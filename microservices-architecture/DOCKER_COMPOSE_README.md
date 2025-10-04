# 🐳 Docker Compose для Tutor Platform

## 📋 Обзор файлов конфигурации

| Файл | Назначение |
|------|-----------|
| `docker-compose.yml` | Основная конфигурация для production |
| `docker-compose.dev.yml` | Конфигурация для разработки |
| `docker-compose.prod.yml` | Расширенная production конфигурация |
| `docker-compose.override.yml` | Автоматические переопределения для dev |
| `.env` | Переменные окружения |
| `.env.example` | Пример переменных для production |

## 🚀 Быстрый старт

### 1. Простой запуск
```bash
# Сборка и запуск всех сервисов
docker-compose up --build

# В фоновом режиме
docker-compose up -d --build
```

### 2. Использование скриптов управления
```bash
# Linux/Mac
chmod +x docker-manage.sh
./docker-manage.sh up --build -d

# Windows
docker-manage.bat up --build -d
```

## 📊 Доступные команды

### Основные операции
```bash
# Запуск сервисов
docker-compose up -d

# Остановка сервисов
docker-compose down

# Перезапуск
docker-compose restart

# Просмотр логов
docker-compose logs -f

# Просмотр логов конкретного сервиса
docker-compose logs -f main-app
```

### Управление через скрипт
```bash
# Все команды доступны через скрипт управления
./docker-manage.sh [команда] [опции]

# Примеры:
./docker-manage.sh up --build -d
./docker-manage.sh status
./docker-manage.sh logs main-app
./docker-manage.sh health
./docker-manage.sh clean
```

## 🔧 Конфигурации для разных сред

### Разработка
```bash
# Автоматически использует docker-compose.override.yml
docker-compose up

# Или явно указать dev конфигурацию
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Через скрипт
./docker-manage.sh dev
```

### Production
```bash
# Использование production конфигурации
docker-compose -f docker-compose.prod.yml up -d

# Через скрипт
./docker-manage.sh prod -d
```

### С дополнительными сервисами
```bash
# С Nginx reverse proxy
docker-compose --profile with-nginx up -d

# С Redis кешированием
docker-compose --profile with-redis up -d

# С инструментами разработки (Portainer)
docker-compose --profile dev-tools up -d

# Комбинированный запуск
./docker-manage.sh up -d --with-nginx --with-redis --dev-tools
```

## 🌐 Доступные сервисы и порты

| Сервис | Порт | URL | Описание |
|--------|------|-----|----------|
| Main App | 3000 | http://localhost:3000 | Основное приложение |
| Notifications | 3001 | http://localhost:3001 | API уведомлений |
| Analytics | 3002 | http://localhost:3002 | API аналитики |
| Nginx | 80 | http://localhost | Reverse proxy |
| Redis | 6379 | localhost:6379 | Кеширование |
| Portainer | 9000 | http://localhost:9000 | Docker UI |

## 🏥 Мониторинг и Health Checks

### Проверка состояния
```bash
# Статус контейнеров
docker-compose ps

# Health checks
./docker-manage.sh health

# Детальный статус
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### Просмотр ресурсов
```bash
# Использование ресурсов
docker stats

# Через скрипт
./docker-manage.sh status
```

## 📝 Логирование

### Настройки логирования
- **Driver**: json-file
- **Max size**: 10MB на файл
- **Max files**: 3-5 файлов
- **Rotation**: Автоматический

### Просмотр логов
```bash
# Все сервисы
docker-compose logs -f

# Конкретный сервис
docker-compose logs -f notification-service

# Последние N строк
docker-compose logs --tail=100 analytics-service

# С временными метками
docker-compose logs -f -t main-app
```

## 🔒 Безопасность

### Настройки безопасности в Docker Compose
- ✅ Non-root пользователи в контейнерах
- ✅ Изолированная Docker сеть
- ✅ Ограничения ресурсов
- ✅ Health checks для всех сервисов
- ✅ Restart policies
- ✅ Secrets через environment variables

### Переменные окружения
```bash
# Создайте .env файл из примера
cp .env.example .env

# Обязательно измените в production:
# - JWT_SECRET
# - API_KEY  
# - REDIS_PASSWORD (если используется)
```

## 🔧 Отладка и Troubleshooting

### Типичные проблемы

1. **Контейнеры не запускаются**
   ```bash
   # Проверить логи
   docker-compose logs
   
   # Пересобрать образы
   docker-compose build --no-cache
   ```

2. **Порты заняты**
   ```bash
   # Найти процесс на порту
   netstat -tulpn | grep :3000
   
   # Изменить порты в .env файле
   ```

3. **Проблемы с сетью**
   ```bash
   # Пересоздать сеть
   docker-compose down
   docker network prune
   docker-compose up
   ```

4. **Недостаток ресурсов**
   ```bash
   # Очистить систему
   docker system prune -a
   ./docker-manage.sh clean
   ```

### Полезные команды отладки
```bash
# Подключение к контейнеру
docker exec -it tutor-main-app sh

# Проверка переменных окружения
docker exec tutor-main-app env

# Проверка сети
docker network ls
docker network inspect tutor-platform-network

# Проверка томов
docker volume ls
```

## 🚀 Production Deployment

### Подготовка к production
1. Создайте `.env` файл из `.env.example`
2. Измените секретные ключи и пароли
3. Настройте домен и SSL сертификаты
4. Запустите с production конфигурацией

### Рекомендации для production
```bash
# Использовать production конфигурацию
docker-compose -f docker-compose.prod.yml up -d

# Или с Nginx
./docker-manage.sh prod -d --with-nginx

# Настроить автозапуск
# systemctl enable docker
# Добавить в crontab или systemd
```

### Мониторинг в production
- Настройте внешний мониторинг health endpoints
- Используйте централизованное логирование
- Настройте алерты на использование ресурсов
- Регулярные бэкапы данных (если есть персистентные данные)

## 📚 Дополнительные ресурсы

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Node.js Docker Guidelines](https://github.com/nodejs/docker-node/blob/main/docs/BestPractices.md)