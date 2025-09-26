# Microservices Architecture

Эта папка содержит все компоненты микросервисной архитектуры проекта "Платформа Репетитор-Ученик".

## Структура проекта

```
microservices-architecture/
├── microservices/              # Папка с микросервисами
│   ├── notification-service/   # Сервис уведомлений
│   └── analytics-service/      # Сервис аналитики
├── docker-compose*.yml         # Конфигурации Docker Compose
├── docker-manage.*            # Скрипты управления Docker
├── nginx.conf                 # Конфигурация Nginx
├── build-images.*             # Скрипты сборки образов
├── start-services.*           # Скрипты запуска сервисов
└── документация/
```

## Микросервисы

### 1. Notification Service (Порт: 3001)
- Управление уведомлениями
- Автоматические напоминания (каждые 5 минут)
- API для создания/получения уведомлений

### 2. Analytics Service (Порт: 3002)
- Сбор аналитических данных
- Реальная аналитика (каждую минуту)
- Отчеты и статистика

## Docker Конфигурации

- `docker-compose.yml` - Основная конфигурация
- `docker-compose.dev.yml` - Конфигурация для разработки
- `docker-compose.prod.yml` - Конфигурация для продакшена
- `docker-compose.override.yml` - Переопределения для разработки

## Скрипты управления

- `docker-manage.bat/.sh` - Управление Docker контейнерами
- `build-images.bat/.sh` - Сборка Docker образов
- `start-services.bat/.sh` - Запуск всех сервисов

## Быстрый запуск

### Windows:
```bash
# Сборка образов
.\build-images.bat

# Запуск сервисов
.\docker-manage.bat up-dev

# Остановка
.\docker-manage.bat down
```

### Linux/Mac:
```bash
# Сборка образов
./build-images.sh

# Запуск сервисов
./docker-manage.sh up-dev

# Остановка
./docker-manage.sh down
```

## Endpoints

### Notification Service (localhost:3001)
- `GET /api/notifications` - Список уведомлений
- `POST /api/notifications` - Создать уведомление
- `GET /api/stats` - Статистика сервиса

### Analytics Service (localhost:3002)
- `GET /api/analytics` - Аналитические данные
- `POST /api/analytics/track` - Отследить событие
- `GET /api/reports` - Отчеты

## Мониторинг

Все сервисы имеют health checks и автоматический перезапуск при сбоях.

- Nginx Proxy: http://localhost
- Main App: http://localhost:3000
- Notification Service: http://localhost:3001
- Analytics Service: http://localhost:3002

## Логи

Для просмотра логов используйте:
```bash
docker-compose logs -f [service_name]
```

## Дополнительная документация

- `DOCKER_README.md` - Подробная документация по Docker
- `DOCKER_COMPOSE_README.md` - Документация Docker Compose
- `MICROSERVICES_STATUS_REPORT.md` - Отчет о состоянии микросервисов

---
*Создано: Сентябрь 2025*
*Автор: Мальцов-Лукьяненко Антон ЭФБО-04-23*