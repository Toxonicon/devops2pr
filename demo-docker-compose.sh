#!/bin/bash

# Скрипт для демонстрации Docker Compose без Docker Desktop
echo "🐳 Демонстрация Docker Compose конфигурации"
echo "============================================"
echo ""

echo "📋 Проверка файлов конфигурации..."
echo ""

# Проверяем наличие Docker Compose файлов
files=("docker-compose.yml" "docker-compose.dev.yml" "docker-compose.prod.yml" "docker-compose.override.yml")

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - найден"
    else
        echo "❌ $file - не найден"
    fi
done

echo ""
echo "📋 Проверка Dockerfile для каждого микросервиса..."
echo ""

# Проверяем Dockerfile микросервисов
dockerfiles=("Dockerfile" "microservices/notification-service/Dockerfile" "microservices/analytics-service/Dockerfile")

for dockerfile in "${dockerfiles[@]}"; do
    if [ -f "$dockerfile" ]; then
        echo "✅ $dockerfile - найден"
    else
        echo "❌ $dockerfile - не найден"
    fi
done

echo ""
echo "🔧 Проверка валидности конфигурации Docker Compose..."
echo ""

# Попытаемся проверить конфигурацию
if command -v docker-compose &> /dev/null; then
    if docker-compose config --quiet &> /dev/null; then
        echo "✅ docker-compose.yml валиден"
    else
        echo "❌ Ошибка в docker-compose.yml"
    fi
    
    if docker-compose -f docker-compose.prod.yml config --quiet &> /dev/null; then
        echo "✅ docker-compose.prod.yml валиден"
    else
        echo "❌ Ошибка в docker-compose.prod.yml"
    fi
else
    echo "⚠️  Docker Compose не установлен или Docker не запущен"
fi

echo ""
echo "🚀 Команды для запуска (когда Docker будет доступен):"
echo ""
echo "# Запуск в режиме разработки:"
echo "docker-compose up --build"
echo ""
echo "# Запуск в фоновом режиме:"
echo "docker-compose up -d --build"
echo ""
echo "# Запуск с дополнительными сервисами:"
echo "docker-compose --profile with-nginx up -d"
echo ""
echo "# Production запуск:"
echo "docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "# Использование скрипта управления:"
echo "./docker-manage.sh up --build -d"
echo ""

echo "📊 Текущие запущенные сервисы (локально):"
echo ""

# Проверяем локально запущенные сервисы
ports=("3000" "3001" "3002")
services=("Основное приложение" "Сервис уведомлений" "Сервис аналитики")

for i in "${!ports[@]}"; do
    port="${ports[$i]}"
    service="${services[$i]}"
    
    if nc -z localhost "$port" 2>/dev/null || curl -s "http://localhost:$port" > /dev/null 2>&1; then
        echo "✅ $service (порт $port) - запущен"
    else
        echo "❌ $service (порт $port) - не запущен"
    fi
done

echo ""
echo "🌐 Для проверки откройте в браузере:"
echo "  - http://localhost:3000 - Основное приложение"
echo "  - http://localhost:3001/health - Health check уведомлений"
echo "  - http://localhost:3002/health - Health check аналитики"