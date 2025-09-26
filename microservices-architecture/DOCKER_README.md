# 🐳 Docker Configuration для Микросервисов

## 📋 Структура Dockerfile

Каждый микросервис имеет свой оптимизированный Dockerfile с лучшими практиками:

### 🔔 Микросервис уведомлений
```
microservices/notification-service/
├── Dockerfile          # Основной Dockerfile для разработки
├── Dockerfile.prod     # Production Dockerfile с многоэтапной сборкой
├── .dockerignore       # Исключения для Docker контекста
├── package.json        # Зависимости Node.js
└── index.js           # Основной файл сервиса
```

### 📊 Микросервис аналитики
```
microservices/analytics-service/
├── Dockerfile          # Основной Dockerfile для разработки
├── Dockerfile.prod     # Production Dockerfile с многоэтапной сборкой
├── .dockerignore       # Исключения для Docker контекста
├── package.json        # Зависимости Node.js
└── index.js           # Основной файл сервиса
```

## 🚀 Команды для сборки образов

### Индивидуальная сборка каждого микросервиса

```bash
# Микросервис уведомлений
cd microservices/notification-service
docker build -t notification-service:latest .

# Микросервис аналитики
cd ../analytics-service
docker build -t analytics-service:latest .

# Основное приложение
cd ../..
docker build -t tutor-platform:latest .
```

### Автоматическая сборка всех образов

```bash
# Linux/Mac
chmod +x build-images.sh
./build-images.sh

# Windows
build-images.bat
```

### Сборка production версий

```bash
# Production версия микросервиса уведомлений
cd microservices/notification-service
docker build -f Dockerfile.prod -t notification-service:prod .

# Production версия микросервиса аналитики
cd ../analytics-service
docker build -f Dockerfile.prod -t analytics-service:prod .
```

## 🔧 Особенности Dockerfile

### Безопасность
- ✅ Использование non-root пользователя (`nodeuser`)
- ✅ Минимальные права доступа
- ✅ Alpine Linux для минимального attack surface

### Оптимизация
- ✅ Многослойная структура для кеширования
- ✅ Копирование package.json отдельно для кеширования npm install
- ✅ Использование `npm ci` вместо `npm install`
- ✅ Очистка npm кеша после установки

### Мониторинг
- ✅ HEALTHCHECK для каждого контейнера
- ✅ Proper labeling для метаданных
- ✅ Expose портов для документации

### Production готовность
- ✅ Многоэтапная сборка в Dockerfile.prod
- ✅ .dockerignore для исключения лишних файлов
- ✅ Оптимизация размера образа

## 🐳 Docker Compose

Для запуска всей системы используйте:

```bash
# Сборка и запуск всех сервисов
docker-compose up --build -d

# Только запуск (если образы уже собраны)
docker-compose up -d

# Просмотр логов
docker-compose logs -f

# Остановка
docker-compose down
```

## 🔍 Проверка состояния контейнеров

```bash
# Проверка запущенных контейнеров
docker ps

# Проверка health status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Подключение к контейнеру
docker exec -it notification-service sh
docker exec -it analytics-service sh
```

## 📊 Мониторинг и отладка

### Просмотр логов
```bash
# Логи конкретного сервиса
docker logs notification-service -f
docker logs analytics-service -f

# Логи через compose
docker-compose logs notification-service -f
```

### Проверка ресурсов
```bash
# Использование ресурсов
docker stats

# Информация об образах
docker images
```

### Health Check
```bash
# Проверка health status
docker inspect --format='{{.State.Health.Status}}' notification-service
docker inspect --format='{{.State.Health.Status}}' analytics-service
```

## 🚀 Production Deployment

### Размеры образов (примерно)
- notification-service: ~50MB
- analytics-service: ~50MB  
- tutor-platform: ~60MB

### Environment Variables
```bash
# Для production
NODE_ENV=production
MAIN_APP_URL=http://main-app:3000

# Для разработки
NODE_ENV=development
MAIN_APP_URL=http://localhost:3000
```

### Docker Hub Push (опционально)
```bash
# Tag images
docker tag notification-service:latest username/notification-service:latest
docker tag analytics-service:latest username/analytics-service:latest

# Push to registry
docker push username/notification-service:latest
docker push username/analytics-service:latest
```

## 🛠️ Troubleshooting

### Типичные проблемы

1. **Docker Desktop не запущен**
   ```
   Error: Cannot connect to Docker daemon
   ```
   Решение: Запустите Docker Desktop

2. **Порты заняты**
   ```
   Error: Port already in use
   ```
   Решение: Остановите конфликтующие сервисы или измените порты

3. **Недостаток места**
   ```
   Error: No space left on device
   ```
   Решение: Очистите Docker кеш
   ```bash
   docker system prune -a
   ```

4. **Проблемы с network**
   ```bash
   # Пересоздать network
   docker network prune
   docker-compose down
   docker-compose up
   ```

### Полезные команды очистки
```bash
# Удалить неиспользуемые образы
docker image prune

# Удалить все остановленные контейнеры
docker container prune

# Полная очистка системы
docker system prune -a --volumes
```