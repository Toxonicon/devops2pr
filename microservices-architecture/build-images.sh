#!/bin/bash

echo "🐳 Сборка Docker образов для микросервисов..."

# Переходим в корневую директорию проекта
cd "$(dirname "$0")"

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для сборки образа
build_image() {
    local service_name=$1
    local dockerfile_path=$2
    local image_name=$3
    
    echo -e "${BLUE}📦 Собираем образ для ${service_name}...${NC}"
    
    if docker build -t $image_name -f $dockerfile_path .; then
        echo -e "${GREEN}✅ Образ ${image_name} успешно собран${NC}"
    else
        echo -e "${RED}❌ Ошибка сборки образа ${image_name}${NC}"
        exit 1
    fi
}

# Сборка основного приложения
echo -e "${BLUE}🏗️ Сборка основного приложения...${NC}"
build_image "Main Application" "Dockerfile" "tutor-platform:latest"

# Сборка микросервиса уведомлений
echo -e "${BLUE}🏗️ Сборка микросервиса уведомлений...${NC}"
build_image "Notification Service" "microservices/notification-service/Dockerfile" "notification-service:latest"

# Сборка микросервиса аналитики
echo -e "${BLUE}🏗️ Сборка микросервиса аналитики...${NC}"
build_image "Analytics Service" "microservices/analytics-service/Dockerfile" "analytics-service:latest"

echo ""
echo -e "${GREEN}🎉 Все образы успешно собраны!${NC}"
echo ""
echo "📋 Собранные образы:"
echo "  - tutor-platform:latest"
echo "  - notification-service:latest"
echo "  - analytics-service:latest"
echo ""
echo "🚀 Для запуска используйте:"
echo "  docker-compose up -d"
echo ""
echo "📊 Проверить образы:"
echo "  docker images | grep -E '(tutor-platform|notification-service|analytics-service)'"