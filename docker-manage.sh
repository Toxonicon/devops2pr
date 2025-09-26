#!/bin/bash

# Функция для отображения помощи
show_help() {
    echo "🐳 Docker Compose управление для Tutor Platform"
    echo ""
    echo "Использование: $0 [КОМАНДА] [ОПЦИИ]"
    echo ""
    echo "Команды:"
    echo "  up           Запуск всех сервисов"
    echo "  down         Остановка всех сервисов"
    echo "  restart      Перезапуск всех сервисов"
    echo "  logs         Просмотр логов"
    echo "  status       Статус сервисов"
    echo "  build        Сборка образов"
    echo "  clean        Очистка неиспользуемых ресурсов"
    echo "  dev          Запуск в режиме разработки"
    echo "  prod         Запуск в production режиме"
    echo "  health       Проверка состояния сервисов"
    echo ""
    echo "Опции:"
    echo "  --with-nginx     Запуск с Nginx reverse proxy"
    echo "  --with-redis     Запуск с Redis кешированием"
    echo "  --dev-tools      Включить инструменты разработки (Portainer)"
    echo "  --detach, -d     Запуск в фоновом режиме"
    echo "  --build          Пересобрать образы перед запуском"
    echo ""
}

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверка наличия Docker и Docker Compose
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker не установлен. Пожалуйста, установите Docker."
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose не установлен. Пожалуйста, установите Docker Compose."
        exit 1
    fi
}

# Построение команды с профилями
build_command() {
    local base_cmd="docker-compose"
    local profiles=""
    
    # Добавляем профили в зависимости от опций
    if [[ "$*" == *"--with-nginx"* ]]; then
        profiles="$profiles --profile with-nginx"
    fi
    
    if [[ "$*" == *"--with-redis"* ]]; then
        profiles="$profiles --profile with-redis"
    fi
    
    if [[ "$*" == *"--dev-tools"* ]]; then
        profiles="$profiles --profile dev-tools"
    fi
    
    echo "$base_cmd $profiles"
}

# Основные команды
case "$1" in
    "up")
        check_docker
        log "Запуск сервисов..."
        
        cmd=$(build_command "$@")
        
        if [[ "$*" == *"--build"* ]]; then
            $cmd up --build ${*/*--build/}
        elif [[ "$*" == *"-d"* ]] || [[ "$*" == *"--detach"* ]]; then
            $cmd up -d
        else
            $cmd up
        fi
        
        if [ $? -eq 0 ]; then
            success "Сервисы успешно запущены!"
            echo ""
            echo "🌐 Доступные сервисы:"
            echo "  - Основное приложение: http://localhost:3000"
            echo "  - Микросервис уведомлений: http://localhost:3001"
            echo "  - Микросервис аналитики: http://localhost:3002"
            if [[ "$*" == *"--with-nginx"* ]]; then
                echo "  - Nginx Reverse Proxy: http://localhost:80"
            fi
            if [[ "$*" == *"--dev-tools"* ]]; then
                echo "  - Portainer: http://localhost:9000"
            fi
        else
            error "Ошибка при запуске сервисов!"
        fi
        ;;
        
    "down")
        check_docker
        log "Остановка сервисов..."
        cmd=$(build_command "$@")
        $cmd down
        success "Сервисы остановлены!"
        ;;
        
    "restart")
        check_docker
        log "Перезапуск сервисов..."
        cmd=$(build_command "$@")
        $cmd restart
        success "Сервисы перезапущены!"
        ;;
        
    "logs")
        check_docker
        cmd=$(build_command "$@")
        if [ -z "$2" ]; then
            $cmd logs -f
        else
            $cmd logs -f "$2"
        fi
        ;;
        
    "status")
        check_docker
        log "Статус сервисов:"
        docker-compose ps
        echo ""
        log "Использование ресурсов:"
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
        ;;
        
    "build")
        check_docker
        log "Сборка образов..."
        cmd=$(build_command "$@")
        $cmd build --no-cache
        success "Образы собраны!"
        ;;
        
    "clean")
        check_docker
        log "Очистка неиспользуемых ресурсов..."
        docker system prune -f
        docker volume prune -f
        success "Очистка завершена!"
        ;;
        
    "dev")
        check_docker
        log "Запуск в режиме разработки..."
        docker-compose -f docker-compose.yml -f docker-compose.dev.yml up ${@:2}
        ;;
        
    "prod")
        check_docker
        log "Запуск в production режиме..."
        docker-compose -f docker-compose.prod.yml up ${@:2}
        ;;
        
    "health")
        check_docker
        log "Проверка состояния сервисов:"
        
        services=("main-app:3000" "notification-service:3001" "analytics-service:3002")
        
        for service in "${services[@]}"; do
            IFS=':' read -r name port <<< "$service"
            if curl -f -s "http://localhost:$port/health" > /dev/null 2>&1 || curl -f -s "http://localhost:$port/api/users" > /dev/null 2>&1; then
                success "$name: Healthy ✓"
            else
                error "$name: Unhealthy ✗"
            fi
        done
        ;;
        
    "help"|"--help"|"-h"|"")
        show_help
        ;;
        
    *)
        error "Неизвестная команда: $1"
        show_help
        exit 1
        ;;
esac