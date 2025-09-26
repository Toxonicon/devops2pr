const express = require('express');
const axios = require('axios');
const cors = require('cors');
const cron = require('node-cron');

const app = express();
const PORT = process.env.PORT || 3002;
const MAIN_APP_URL = process.env.MAIN_APP_URL || 'http://localhost:3000';

app.use(cors());
app.use(express.json());

// Хранение аналитических данных в памяти
let analytics = {
  userActivity: [],
  sessionStats: [],
  messageStats: [],
  dailyStats: new Map(), // дата -> статистика
  realtimeMetrics: {
    activeUsers: 0,
    activeSessions: 0,
    messagesPerMinute: 0,
    lastUpdate: new Date().toISOString()
  }
};

// Функция для получения данных из основного приложения
async function fetchFromMainApp(endpoint) {
  try {
    const response = await axios.get(`${MAIN_APP_URL}${endpoint}`, {
      timeout: 5000,
      headers: {
        'X-Service': 'analytics-service'
      }
    });
    return response.data;
  } catch (error) {
    console.error(`❌ Ошибка получения данных из основного приложения:`, error.message);
    return null;
  }
}

// Функция для отправки данных в основное приложение
async function sendToMainApp(endpoint, data) {
  try {
    const response = await axios.post(`${MAIN_APP_URL}${endpoint}`, data, {
      headers: {
        'Content-Type': 'application/json',
        'X-Service': 'analytics-service'
      },
      timeout: 5000
    });
    
    console.log(`✅ Аналитика отправлена в основное приложение: ${endpoint}`);
    return response.data;
  } catch (error) {
    console.error(`❌ Ошибка отправки аналитики:`, error.message);
    return null;
  }
}

// Функция для анализа данных
function analyzeData(users = [], sessions = [], messages = []) {
  const now = new Date();
  const today = now.toISOString().split('T')[0];
  
  // Анализ пользователей
  const tutors = users.filter(u => u.role === 'tutor');
  const students = users.filter(u => u.role === 'student');
  const activeUsers = users.filter(u => u.online);
  
  // Анализ сессий
  const activeSessions = sessions.length;
  const sessionsWithStudents = sessions.filter(s => s.students && s.students.length > 0);
  
  // Анализ сообщений за последний час
  const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
  const recentMessages = messages.filter(m => new Date(m.timestamp) > oneHourAgo);
  
  // Создаем сводную статистику
  const stats = {
    timestamp: now.toISOString(),
    users: {
      total: users.length,
      tutors: tutors.length,
      students: students.length,
      active: activeUsers.length,
      offline: users.length - activeUsers.length
    },
    sessions: {
      total: activeSessions,
      withStudents: sessionsWithStudents.length,
      empty: activeSessions - sessionsWithStudents.length,
      averageStudentsPerSession: activeSessions > 0 ? 
        sessions.reduce((sum, s) => sum + (s.students ? s.students.length : 0), 0) / activeSessions : 0
    },
    messages: {
      total: messages.length,
      lastHour: recentMessages.length,
      fromTutors: messages.filter(m => m.userRole === 'tutor').length,
      fromStudents: messages.filter(m => m.userRole === 'student').length
    },
    insights: []
  };
  
  // Добавляем инсайты
  if (stats.users.tutors === 0) {
    stats.insights.push('⚠️ Нет активных репетиторов в системе');
  }
  
  if (stats.users.students > stats.users.tutors * 10) {
    stats.insights.push('📈 Высокое соотношение учеников к репетиторам');
  }
  
  if (stats.sessions.total === 0 && stats.users.tutors > 0) {
    stats.insights.push('💡 Репетиторы онлайн, но нет активных сессий');
  }
  
  if (stats.messages.lastHour > 50) {
    stats.insights.push('🔥 Высокая активность чата в последний час');
  }
  
  // Сохраняем дневную статистику
  analytics.dailyStats.set(today, {
    ...stats,
    date: today
  });
  
  return stats;
}

// API для получения аналитики
app.get('/api/analytics', (req, res) => {
  res.json({
    success: true,
    data: analytics
  });
});

// API для получения статистики реального времени
app.get('/api/analytics/realtime', (req, res) => {
  res.json({
    success: true,
    data: analytics.realtimeMetrics
  });
});

// API для получения дневной статистики
app.get('/api/analytics/daily', (req, res) => {
  const dailyData = Array.from(analytics.dailyStats.values());
  res.json({
    success: true,
    data: dailyData
  });
});

// API для получения инсайтов и рекомендаций
app.get('/api/analytics/insights', (req, res) => {
  const latestStats = Array.from(analytics.dailyStats.values()).pop();
  const insights = latestStats ? latestStats.insights : [];
  
  // Добавляем дополнительные рекомендации
  const recommendations = [
    '📚 Создайте больше специализированных сессий для привлечения учеников',
    '💬 Поощряйте активное общение в чате для лучшего взаимодействия',
    '⏰ Рассмотрите возможность создания расписания занятий',
    '🎯 Анализируйте популярные предметы для фокуса на них'
  ];
  
  res.json({
    success: true,
    data: {
      insights,
      recommendations: recommendations.slice(0, 3)
    }
  });
});

// Периодический сбор и анализ данных каждую минуту
cron.schedule('* * * * *', async () => {
  console.log('🔍 Собираем аналитические данные...');
  
  // Получаем данные из основного приложения
  const [users, sessions, messages] = await Promise.all([
    fetchFromMainApp('/api/users'),
    fetchFromMainApp('/api/sessions'),
    fetchFromMainApp('/api/messages')
  ]);
  
  if (users && sessions && messages) {
    // Анализируем данные
    const stats = analyzeData(users, sessions, messages);
    
    // Обновляем метрики реального времени
    analytics.realtimeMetrics = {
      activeUsers: stats.users.active,
      activeSessions: stats.sessions.total,
      messagesPerMinute: Math.round(stats.messages.lastHour / 60),
      lastUpdate: new Date().toISOString()
    };
    
    // Добавляем в историю активности пользователей
    analytics.userActivity.push({
      timestamp: new Date().toISOString(),
      activeUsers: stats.users.active,
      totalUsers: stats.users.total
    });
    
    // Ограничиваем размер истории
    if (analytics.userActivity.length > 1440) { // 24 часа по минутам
      analytics.userActivity = analytics.userActivity.slice(-1440);
    }
    
    console.log(`📊 Аналитика обновлена: ${stats.users.active} активных пользователей, ${stats.sessions.total} сессий`);
  }
});

// Отправка аналитики в основное приложение каждые 3 минуты
cron.schedule('*/3 * * * *', async () => {
  const analyticsData = {
    service: 'analytics-service',
    timestamp: new Date().toISOString(),
    realtimeMetrics: analytics.realtimeMetrics,
    summary: {
      totalDataPoints: analytics.userActivity.length,
      dailyReportsGenerated: analytics.dailyStats.size,
      lastAnalysisTime: analytics.realtimeMetrics.lastUpdate
    }
  };
  
  await sendToMainApp('/api/microservice/analytics-data', analyticsData);
});

// Генерация еженедельного отчета каждое воскресенье в полночь
cron.schedule('0 0 * * 0', () => {
  console.log('📈 Генерируем еженедельный отчет...');
  
  const weeklyReport = {
    period: 'weekly',
    generatedAt: new Date().toISOString(),
    summary: {
      dailyReports: analytics.dailyStats.size,
      averageActiveUsers: analytics.userActivity.length > 0 ?
        analytics.userActivity.reduce((sum, item) => sum + item.activeUsers, 0) / analytics.userActivity.length : 0,
      totalDataPoints: analytics.userActivity.length
    },
    insights: [
      '📊 Еженедельный анализ показывает стабильную активность пользователей',
      '🎯 Рекомендуется увеличить количество специализированных сессий',
      '💡 Средняя активность пользователей составляет ' + 
      (analytics.userActivity.length > 0 ?
        Math.round(analytics.userActivity.reduce((sum, item) => sum + item.activeUsers, 0) / analytics.userActivity.length) : 0) +
      ' человек'
    ]
  };
  
  console.log('📋 Еженедельный отчет сгенерирован:', weeklyReport.summary);
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    service: 'analytics-service',
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    dataPoints: analytics.userActivity.length,
    lastAnalysis: analytics.realtimeMetrics.lastUpdate
  });
});

// API для принудительного обновления аналитики
app.post('/api/analytics/refresh', async (req, res) => {
  console.log('🔄 Принудительное обновление аналитики...');
  
  const [users, sessions, messages] = await Promise.all([
    fetchFromMainApp('/api/users'),
    fetchFromMainApp('/api/sessions'),
    fetchFromMainApp('/api/messages')
  ]);
  
  if (users && sessions && messages) {
    const stats = analyzeData(users, sessions, messages);
    
    res.json({
      success: true,
      data: stats
    });
  } else {
    res.status(500).json({
      success: false,
      error: 'Не удалось получить данные из основного приложения'
    });
  }
});

// Запуск сервера
app.listen(PORT, () => {
  console.log(`📊 Микросервис аналитики запущен на порту ${PORT}`);
  console.log(`🔗 Основное приложение: ${MAIN_APP_URL}`);
  
  // Инициализируем аналитику
  analytics.realtimeMetrics = {
    activeUsers: 0,
    activeSessions: 0,
    messagesPerMinute: 0,
    lastUpdate: new Date().toISOString()
  };
  
  console.log('📈 Сервис аналитики готов к сбору данных');
});