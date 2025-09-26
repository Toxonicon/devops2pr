const express = require('express');
const axios = require('axios');
const cors = require('cors');
const cron = require('node-cron');

const app = express();
const PORT = process.env.PORT || 3001;
const MAIN_APP_URL = process.env.MAIN_APP_URL || 'http://localhost:3000';

app.use(cors());
app.use(express.json());

// Хранение уведомлений в памяти
let notifications = [];
let notificationId = 1;

// Типы уведомлений
const NOTIFICATION_TYPES = {
  SESSION_CREATED: 'session_created',
  SESSION_JOINED: 'session_joined',
  NEW_MESSAGE: 'new_message',
  USER_JOINED: 'user_joined',
  REMINDER: 'reminder'
};

// API для получения всех уведомлений
app.get('/api/notifications', (req, res) => {
  res.json({
    success: true,
    data: notifications,
    count: notifications.length
  });
});

// API для создания нового уведомления
app.post('/api/notifications', (req, res) => {
  const { type, title, message, userId, metadata = {} } = req.body;
  
  if (!type || !title || !message) {
    return res.status(400).json({
      success: false,
      error: 'Требуются поля: type, title, message'
    });
  }

  const notification = {
    id: notificationId++,
    type,
    title,
    message,
    userId,
    metadata,
    timestamp: new Date().toISOString(),
    read: false
  };

  notifications.push(notification);
  
  // Ограничиваем количество уведомлений
  if (notifications.length > 100) {
    notifications = notifications.slice(-100);
  }

  console.log(`📨 Новое уведомление: ${title}`);
  
  res.json({
    success: true,
    data: notification
  });
});

// API для отметки уведомления как прочитанного
app.put('/api/notifications/:id/read', (req, res) => {
  const notificationId = parseInt(req.params.id);
  const notification = notifications.find(n => n.id === notificationId);
  
  if (!notification) {
    return res.status(404).json({
      success: false,
      error: 'Уведомление не найдено'
    });
  }
  
  notification.read = true;
  
  res.json({
    success: true,
    data: notification
  });
});

// API для получения статистики уведомлений
app.get('/api/notifications/stats', (req, res) => {
  const stats = {
    total: notifications.length,
    unread: notifications.filter(n => !n.read).length,
    read: notifications.filter(n => n.read).length,
    byType: {}
  };

  // Подсчитываем по типам
  Object.values(NOTIFICATION_TYPES).forEach(type => {
    stats.byType[type] = notifications.filter(n => n.type === type).length;
  });

  res.json({
    success: true,
    data: stats
  });
});

// Функция для отправки данных в основное приложение
async function sendToMainApp(endpoint, data) {
  try {
    const response = await axios.post(`${MAIN_APP_URL}${endpoint}`, data, {
      headers: {
        'Content-Type': 'application/json',
        'X-Service': 'notification-service'
      },
      timeout: 5000
    });
    
    console.log(`✅ Данные отправлены в основное приложение: ${endpoint}`);
    return response.data;
  } catch (error) {
    console.error(`❌ Ошибка отправки в основное приложение:`, error.message);
    return null;
  }
}

// Автоматическое создание напоминаний каждые 5 минут
cron.schedule('*/5 * * * *', () => {
  const reminder = {
    type: NOTIFICATION_TYPES.REMINDER,
    title: '🔔 Напоминание',
    message: 'Не забудьте проверить активные учебные сессии и ответить на сообщения учеников!',
    metadata: {
      auto_generated: true,
      cron_time: new Date().toISOString()
    }
  };

  // Добавляем напоминание в наш список
  const notification = {
    id: notificationId++,
    ...reminder,
    timestamp: new Date().toISOString(),
    read: false
  };

  notifications.push(notification);
  
  if (notifications.length > 100) {
    notifications = notifications.slice(-100);
  }

  console.log('⏰ Создано автоматическое напоминание');
});

// Периодическая отправка статистики уведомлений в основное приложение
cron.schedule('*/2 * * * *', async () => {
  const stats = {
    service: 'notification-service',
    timestamp: new Date().toISOString(),
    notifications_count: notifications.length,
    unread_count: notifications.filter(n => !n.read).length,
    last_notification: notifications.length > 0 ? notifications[notifications.length - 1] : null
  };

  // Попытка отправить статистику в основное приложение
  await sendToMainApp('/api/microservice/notification-stats', stats);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    service: 'notification-service',
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`📨 Микросервис уведомлений запущен на порту ${PORT}`);
  console.log(`🔗 Основное приложение: ${MAIN_APP_URL}`);
  
  // Отправляем уведомление о запуске
  const startupNotification = {
    id: notificationId++,
    type: 'system',
    title: '🚀 Сервис запущен',
    message: 'Микросервис уведомлений успешно запущен и готов к работе',
    timestamp: new Date().toISOString(),
    read: false,
    metadata: {
      service: 'notification-service',
      port: PORT
    }
  };
  
  notifications.push(startupNotification);
});