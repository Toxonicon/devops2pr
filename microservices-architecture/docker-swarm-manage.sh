#!/bin/bash

echo "🐳 Docker Swarm Management для платформы репетитора"
echo "================================================"

STACK_NAME="tutor-platform"

show_help() {
    echo ""
    echo "Использование: ./docker-swarm-manage.sh [команда]"
    echo ""
    echo "Команды:"
    echo "  init       - Инициализация Docker Swarm"
    echo "  deploy     - Развертывание стека сервисов"
    echo "  update     - Обновление сервисов"
    echo "  scale      - Масштабирование сервисов"
    echo "  status     - Статус сервисов"
    echo "  logs       - Просмотр логов"
    echo "  stop       - Остановка стека"
    echo "  leave      - Выход из Swarm"
    echo "  build      - Сборка образов для Swarm"
    echo ""
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

case "$1" in
    "init")
        echo "🔧 Инициализация Docker Swarm..."
        docker swarm init --advertise-addr 127.0.0.1
        if [ $? -ne 0 ]; then
            echo "⚠️  Swarm уже инициализирован или ошибка"
        else
            echo "✅ Docker Swarm инициализирован"
        fi
        
        echo ""
        echo "📋 Информация о Swarm:"
        docker node ls
        
        echo ""
        echo "🌐 Создание overlay сети..."
        docker network create --driver overlay tutor-platform-network 2>/dev/null || echo "Сеть уже существует"
        ;;
    
    "build")
        echo "🔨 Сборка образов для Docker Swarm..."
        
        echo "Сборка основного приложения..."
        docker build -t tutor-main-app:latest .
        
        echo "Сборка микросервиса уведомлений..."
        docker build -t tutor-notification-service:latest ./microservices/notification-service
        
        echo "Сборка микросервиса аналитики..."
        docker build -t tutor-analytics-service:latest ./microservices/analytics-service
        
        echo "✅ Все образы собраны"
        echo ""
        echo "📋 Список образов:"
        docker images | grep tutor-
        ;;
    
    "deploy")
        echo "🚀 Развертывание стека в Docker Swarm..."
        
        # Проверяем что Swarm инициализирован
        docker node ls >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo "❌ Docker Swarm не инициализирован. Запустите: ./docker-swarm-manage.sh init"
            exit 1
        fi
        
        docker stack deploy -c docker-compose.swarm.yml $STACK_NAME
        
        echo "⏳ Ожидание запуска сервисов..."
        sleep 30
        
        echo ""
        echo "📊 Статус сервисов:"
        docker stack services $STACK_NAME
        ;;
    
    "update")
        echo "🔄 Обновление сервисов..."
        
        if [ -z "$2" ]; then
            echo "Обновление всех сервисов..."
            docker service update --force ${STACK_NAME}_main-app
            docker service update --force ${STACK_NAME}_notification-service
            docker service update --force ${STACK_NAME}_analytics-service
            docker service update --force ${STACK_NAME}_nginx
        else
            echo "Обновление сервиса $2..."
            docker service update --force ${STACK_NAME}_$2
        fi
        ;;
    
    "scale")
        if [ -z "$2" ]; then
            echo "❌ Укажите сервис для масштабирования"
            echo "Пример: ./docker-swarm-manage.sh scale main-app 3"
            exit 1
        fi
        
        if [ -z "$3" ]; then
            echo "❌ Укажите количество реплик"
            exit 1
        fi
        
        echo "📈 Масштабирование $2 до $3 реплик..."
        docker service scale ${STACK_NAME}_$2=$3
        ;;
    
    "status")
        echo "📊 Статус Docker Swarm:"
        echo ""
        
        echo "🔗 Узлы кластера:"
        docker node ls
        
        echo ""
        echo "📋 Сервисы стека:"
        docker stack services $STACK_NAME
        
        echo ""
        echo "🔄 Процессы сервисов:"
        docker stack ps $STACK_NAME --no-trunc
        
        echo ""
        echo "🌐 Сети:"
        docker network ls | grep overlay
        ;;
    
    "logs")
        if [ -z "$2" ]; then
            echo "📋 Доступные сервисы для просмотра логов:"
            docker stack services $STACK_NAME --format "table {{.Name}}"
            echo ""
            echo "Использование: ./docker-swarm-manage.sh logs [service-name]"
            exit 1
        fi
        
        echo "📋 Логи сервиса $2:"
        docker service logs -f ${STACK_NAME}_$2
        ;;
    
    "stop")
        echo "🛑 Остановка стека $STACK_NAME..."
        docker stack rm $STACK_NAME
        
        echo "⏳ Ожидание завершения..."
        sleep 15
        
        echo "✅ Стек остановлен"
        ;;
    
    "leave")
        echo "⚠️  Выход из Docker Swarm (это удалит весь кластер!)"
        echo "Нажмите Ctrl+C для отмены или Enter для продолжения..."
        read
        
        docker swarm leave --force
        echo "✅ Вышли из Docker Swarm"
        ;;
    
    *)
        echo "❌ Неизвестная команда: $1"
        show_help
        exit 1
        ;;
esac

echo ""
echo "🌐 Полезные URL (если развернуто):"
echo "  - Основное приложение: http://localhost"
echo "  - Nginx статус: http://localhost/nginx-status"
echo "  - Portainer: http://localhost:9000"
echo "  - Health check: http://localhost/health"
echo ""