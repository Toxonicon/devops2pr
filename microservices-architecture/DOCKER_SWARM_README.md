# 🐳 Docker Swarm Configuration для Платформы Репетитора

Данная конфигурация предоставляет полноценное развертывание микросервисной архитектуры в Docker Swarm с NGINX в качестве reverse proxy и системой мониторинга.

## 📋 Структура файлов

```
microservices-architecture/
├── docker-compose.swarm.yml      # Основная конфигурация для Docker Swarm
├── docker-compose.monitoring.yml # Система мониторинга (Prometheus, Grafana)
├── nginx.swarm.conf              # NGINX конфигурация для Swarm
├── docker-swarm-manage.bat/.sh   # Скрипты управления Swarm
└── monitoring/                   # Конфигурации мониторинга
    ├── prometheus.yml
    ├── alertmanager.yml
    └── ...
```

## 🚀 Быстрый старт

### 1. Подготовка образов

```bash
# Windows
docker-swarm-manage.bat build

# Linux/Mac
./docker-swarm-manage.sh build
```

### 2. Инициализация Docker Swarm

```bash
# Windows
docker-swarm-manage.bat init

# Linux/Mac
./docker-swarm-manage.sh init
```

### 3. Развертывание основных сервисов

```bash
# Windows
docker-swarm-manage.bat deploy

# Linux/Mac
./docker-swarm-manage.sh deploy
```

### 4. Развертывание мониторинга (опционально)

```bash
docker stack deploy -c docker-compose.monitoring.yml monitoring
```

## 🏗️ Архитектура Docker Swarm

### Сервисы и их роли

1. **main-app** (2 реплики)
   - Основное веб-приложение
   - Порт: 3000
   - Ресурсы: 0.5 CPU, 512MB RAM

2. **notification-service** (2 реплики)
   - Микросервис уведомлений
   - Порт: 3001
   - Ресурсы: 0.3 CPU, 256MB RAM

3. **analytics-service** (2 реплики)
   - Микросервис аналитики
   - Порт: 3002
   - Ресурсы: 0.3 CPU, 256MB RAM

4. **nginx** (2 реплики)
   - Reverse proxy и load balancer
   - Порт: 80, 443
   - Размещение: только на manager нодах

5. **portainer** (1 реплика)
   - Веб-интерфейс для управления Docker
   - Порт: 9000
   - Размещение: только на manager нодах

### Сетевая архитектура

```
┌─────────────────┐    ┌─────────────────┐
│   Client        │────│   NGINX         │
│                 │    │   (Port 80)     │
└─────────────────┘    └─────────────────┘
                              │
                    ┌─────────┼─────────┐
                    │         │         │
          ┌─────────▼──┐ ┌────▼────┐ ┌──▼────────┐
          │ Main App   │ │ Notif.  │ │ Analytics │
          │ (Port 3000)│ │ Service │ │ Service   │
          │            │ │(Port    │ │(Port 3002)│
          │            │ │ 3001)   │ │           │
          └────────────┘ └─────────┘ └───────────┘
```

## ⚙️ Конфигурация NGINX

### Основные возможности

- **Load Balancing**: Автоматическая балансировка между репликами
- **Health Checks**: Мониторинг состояния upstream серверов
- **SSL Termination**: Готовность к HTTPS (требует сертификатов)
- **Rate Limiting**: Защита от DDoS атак
- **Caching**: Кеширование статических ресурсов и API ответов
- **WebSocket Support**: Поддержка Socket.IO для real-time коммуникации

### Маршрутизация

- `/` → main-app (основное приложение)
- `/notifications/*` → notification-service
- `/analytics/*` → analytics-service
- `/socket.io/*` → main-app (WebSocket)
- `/health` → health check endpoint
- `/nginx-status` → статистика Nginx

## 🔄 Управление Docker Swarm

### Команды управления

```bash
# Статус сервисов
docker-swarm-manage.bat status

# Масштабирование
docker-swarm-manage.bat scale main-app 3

# Обновление сервиса
docker-swarm-manage.bat update notification-service

# Просмотр логов
docker-swarm-manage.bat logs main-app

# Остановка всех сервисов
docker-swarm-manage.bat stop
```

### Ручные команды Docker

```bash
# Список сервисов
docker service ls

# Детали сервиса
docker service ps tutor-platform_main-app

# Масштабирование
docker service scale tutor-platform_main-app=3

# Обновление с новым образом
docker service update --image tutor-main-app:v2 tutor-platform_main-app

# Rolling update без даунтайма
docker service update --update-parallelism 1 --update-delay 10s tutor-platform_main-app
```

## 📊 Мониторинг

### Prometheus Metrics

- **URL**: http://localhost:9090
- **Цели мониторинга**:
  - Node metrics (CPU, Memory, Disk)
  - Container metrics (cAdvisor)
  - Application metrics (custom endpoints)
  - Nginx metrics

### Grafana Dashboards

- **URL**: http://localhost:3001
- **Credentials**: admin/admin123
- **Дашборды**:
  - Docker Swarm Overview
  - Application Performance
  - Infrastructure Monitoring
  - Business Metrics

### Alerting

Алерты настроены для:
- Высокое использование CPU (>80%)
- Недостаток памяти (<100MB свободно)
- Недоступность сервисов
- Высокий response time (>5s)

## 🔒 Безопасность

### NGINX Security Headers

```nginx
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header X-XSS-Protection "1; mode=block";
```

### Rate Limiting

- API endpoints: 10 req/sec
- General requests: 1 req/sec

### Network Isolation

- Overlay networks с изоляцией трафика
- Внутренние сервисы недоступны извне
- Только необходимые порты экспонированы

## 🚀 Production Deployment

### SSL/TLS Configuration

1. Получите SSL сертификаты:
```bash
# Let's Encrypt
certbot certonly --webroot -w /var/www/html -d tutor.yourdomain.com
```

2. Создайте директорию для сертификатов:
```bash
mkdir -p ssl/
cp /etc/letsencrypt/live/tutor.yourdomain.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/tutor.yourdomain.com/privkey.pem ssl/key.pem
```

3. Раскомментируйте HTTPS секцию в `nginx.swarm.conf`

### Multi-Node Swarm

```bash
# На manager ноде
docker swarm init --advertise-addr <MANAGER-IP>

# На worker нодах
docker swarm join --token <TOKEN> <MANAGER-IP>:2377

# Добавить labels для нод
docker node update --label-add environment=production worker1
docker node update --label-add environment=production worker2
```

### Backup Strategy

```bash
# Backup Docker volumes
docker run --rm -v tutor-platform_portainer-data:/data -v $(pwd):/backup alpine tar czf /backup/portainer-backup.tar.gz /data

# Backup configurations
tar czf swarm-config-backup.tar.gz *.yml nginx.swarm.conf monitoring/
```

## 🐛 Troubleshooting

### Общие проблемы

1. **Сервис не запускается**:
   ```bash
   docker service logs tutor-platform_main-app
   docker service ps tutor-platform_main-app --no-trunc
   ```

2. **Network connectivity issues**:
   ```bash
   docker network ls
   docker network inspect tutor-platform-network
   ```

3. **Resource constraints**:
   ```bash
   docker node ls
   docker system df
   docker system prune -a
   ```

### Health Checks

```bash
# Проверка health всех сервисов
curl http://localhost/health
curl http://localhost:3000/api/users
curl http://localhost:3001/health
curl http://localhost:3002/health
```

## 📈 Performance Tuning

### NGINX Optimization

- Worker processes = CPU cores
- Worker connections = 1024
- Keepalive connections для upstreams
- Gzip compression
- Static file caching

### Docker Swarm Optimization

- Используйте SSD для Docker volumes
- Настройте логирование (rotation, size limits)
- Мониторите resource usage
- Регулярно обновляйте образы

## 🔗 Полезные ссылки

### URLs после развертывания

- **Основное приложение**: http://localhost
- **Portainer**: http://localhost:9000
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001
- **Health Check**: http://localhost/health
- **Nginx Status**: http://localhost/nginx-status

### Документация

- [Docker Swarm Documentation](https://docs.docker.com/engine/swarm/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## 📝 Changelog

### v1.0.0
- Начальная конфигурация Docker Swarm
- NGINX reverse proxy с load balancing
- Система мониторинга (Prometheus + Grafana)
- Health checks для всех сервисов
- Автоматическое масштабирование
- Скрипты управления для Windows и Linux