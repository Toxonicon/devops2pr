#!/bin/bash

echo "🚀 Запуск платформы репетитора с микросервисами..."

# Проверяем, что Docker установлен
if ! command -v docker &> /dev/null; then
    echo "❌ Docker не найден. Пожалуйста, установите Docker."
    exit 1
fi

# Проверяем, что Docker Compose установлен
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose не найден. Пожалуйста, установите Docker Compose."
    exit 1
fi

# Останавливаем существующие контейнеры
echo "🛑 Остановка существующих контейнеров..."
docker-compose down

# Собираем образы
echo "🔨 Сборка Docker образов..."
docker-compose build

# Запускаем сервисы
echo "🚀 Запуск сервисов..."
docker-compose up -d

# Ждем запуска сервисов
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверяем статус сервисов
echo "📊 Проверка статуса сервисов..."
docker-compose ps

echo ""
echo "✅ Все сервисы запущены!"
echo ""
echo "🌐 Доступные сервисы:"
echo "  - Основное приложение: http://localhost:3000"
echo "  - Сервис уведомлений: http://localhost:3001"
echo "  - Сервис аналитики: http://localhost:3002"
echo ""
echo "📋 Полезные команды:"
echo "  - Просмотр логов: docker-compose logs -f"
echo "  - Остановка: docker-compose down"
echo "  - Перезапуск: docker-compose restart"