# Используем официальный Node.js образ на Alpine Linux для минимального размера
FROM node:18-alpine

# Добавляем метаданные
LABEL maintainer="DevOps Student"
LABEL version="1.0.0"
LABEL description="Notification Microservice for Tutor-Student Platform"

# Устанавливаем рабочую директорию
WORKDIR /app

# Создаем пользователя для безопасности (не root)
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodeuser -u 1001

# Копируем package.json и package-lock.json для кеширования слоев
COPY package*.json ./

# Устанавливаем зависимости с очисткой кеша
RUN npm ci --only=production && \
    npm cache clean --force

# Копируем исходный код
COPY . .

# Изменяем владельца файлов на nodeuser
RUN chown -R nodeuser:nodejs /app
USER nodeuser

# Открываем порт
EXPOSE 3001

# Добавляем health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "const http = require('http'); \
    const options = { hostname: 'localhost', port: 3001, path: '/health', method: 'GET' }; \
    const req = http.request(options, (res) => { \
      if (res.statusCode === 200) { process.exit(0); } else { process.exit(1); } \
    }); \
    req.on('error', () => process.exit(1)); \
    req.end();"

# Запускаем приложение
CMD ["node", "index.js"]