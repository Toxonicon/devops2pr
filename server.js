const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const path = require('path');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Хранение данных в памяти (без базы данных)
let users = new Map(); // id -> {name, role, socketId}
let messages = []; // массив сообщений
let sessions = new Map(); // sessionId -> {tutor, students, subject}

// Главная страница
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API для получения пользователей
app.get('/api/users', (req, res) => {
  const userList = Array.from(users.values()).map(user => ({
    id: user.id,
    name: user.name,
    role: user.role,
    online: user.socketId ? true : false
  }));
  res.json(userList);
});

// API для получения сообщений
app.get('/api/messages', (req, res) => {
  res.json(messages);
});

// API для получения сессий
app.get('/api/sessions', (req, res) => {
  const sessionList = Array.from(sessions.values());
  res.json(sessionList);
});

// API endpoints для взаимодействия с микросервисами
app.post('/api/microservice/notification-stats', (req, res) => {
  console.log('📨 Получена статистика от сервиса уведомлений:', req.body);
  res.json({ success: true, message: 'Статистика уведомлений получена' });
});

app.post('/api/microservice/analytics-data', (req, res) => {
  console.log('📊 Получены аналитические данные:', req.body);
  res.json({ success: true, message: 'Аналитические данные получены' });
});

// API для получения информации о микросервисах
app.get('/api/microservices/status', async (req, res) => {
  const axios = require('axios'); // Добавим axios если его нет
  
  const services = [
    { name: 'notification-service', url: 'http://localhost:3001/health' },
    { name: 'analytics-service', url: 'http://localhost:3002/health' }
  ];
  
  const statuses = await Promise.allSettled(
    services.map(async service => {
      try {
        const response = await axios.get(service.url, { timeout: 3000 });
        return { name: service.name, status: 'healthy', data: response.data };
      } catch (error) {
        return { name: service.name, status: 'unhealthy', error: error.message };
      }
    })
  );
  
  res.json({
    success: true,
    services: statuses.map(result => result.value || { status: 'error' })
  });
});

// Socket.IO соединения
io.on('connection', (socket) => {
  console.log('Пользователь подключился:', socket.id);

  // Регистрация пользователя
  socket.on('register', (userData) => {
    const userId = uuidv4();
    const user = {
      id: userId,
      name: userData.name,
      role: userData.role, // 'tutor' или 'student'
      socketId: socket.id
    };
    
    users.set(userId, user);
    socket.userId = userId;
    socket.userRole = userData.role;
    
    socket.emit('registered', { userId, user });
    io.emit('userJoined', user);
    
    console.log(`${userData.role} ${userData.name} зарегистрирован`);
  });

  // Отправка сообщения
  socket.on('sendMessage', (messageData) => {
    const user = users.get(socket.userId);
    if (user) {
      const message = {
        id: uuidv4(),
        userId: user.id,
        userName: user.name,
        userRole: user.role,
        text: messageData.text,
        timestamp: new Date().toISOString()
      };
      
      messages.push(message);
      
      // Ограничиваем количество сообщений в памяти
      if (messages.length > 100) {
        messages = messages.slice(-100);
      }
      
      io.emit('newMessage', message);
    }
  });

  // Создание учебной сессии (только для репетиторов)
  socket.on('createSession', (sessionData) => {
    const user = users.get(socket.userId);
    if (user && user.role === 'tutor') {
      const sessionId = uuidv4();
      const session = {
        id: sessionId,
        tutor: {
          id: user.id,
          name: user.name
        },
        subject: sessionData.subject,
        description: sessionData.description,
        students: [],
        createdAt: new Date().toISOString()
      };
      
      sessions.set(sessionId, session);
      io.emit('sessionCreated', session);
      
      console.log(`Сессия "${sessionData.subject}" создана репетитором ${user.name}`);
    }
  });

  // Присоединение к сессии (для учеников)
  socket.on('joinSession', (sessionId) => {
    const user = users.get(socket.userId);
    const session = sessions.get(sessionId);
    
    if (user && user.role === 'student' && session) {
      // Проверяем, не присоединился ли уже этот ученик
      const alreadyJoined = session.students.find(s => s.id === user.id);
      if (!alreadyJoined) {
        session.students.push({
          id: user.id,
          name: user.name
        });
        
        socket.join(sessionId);
        io.emit('studentJoinedSession', { sessionId, student: { id: user.id, name: user.name } });
        
        console.log(`Ученик ${user.name} присоединился к сессии ${session.subject}`);
      }
    }
  });

  // Отключение пользователя
  socket.on('disconnect', () => {
    if (socket.userId) {
      const user = users.get(socket.userId);
      if (user) {
        user.socketId = null;
        io.emit('userLeft', user);
        console.log(`Пользователь ${user.name} отключился`);
      }
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Сервер запущен на порту ${PORT}`);
  console.log(`Откройте браузер на http://localhost:${PORT}`);
});