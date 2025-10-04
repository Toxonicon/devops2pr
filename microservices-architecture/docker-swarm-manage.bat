@echo off
echo 🐳 Docker Swarm Management для платформы репетитора
echo ================================================

if "%1"=="" (
    echo.
    echo Использование: docker-swarm-manage.bat [команда]
    echo.
    echo Команды:
    echo   init       - Инициализация Docker Swarm
    echo   deploy     - Развертывание стека сервисов
    echo   update     - Обновление сервисов
    echo   scale      - Масштабирование сервисов
    echo   status     - Статус сервисов
    echo   logs       - Просмотр логов
    echo   stop       - Остановка стека
    echo   leave      - Выход из Swarm
    echo   build      - Сборка образов для Swarm
    echo.
    exit /b 1
)

set STACK_NAME=tutor-platform

if "%1"=="init" (
    echo 🔧 Инициализация Docker Swarm...
    docker swarm init --advertise-addr 127.0.0.1
    if %errorlevel% neq 0 (
        echo ⚠️  Swarm уже инициализирован или ошибка
    ) else (
        echo ✅ Docker Swarm инициализирован
    )
    
    echo.
    echo 📋 Информация о Swarm:
    docker node ls
    
    echo.
    echo 🌐 Создание overlay сети...
    docker network create --driver overlay tutor-platform-network 2>nul || echo "Сеть уже существует"
    
    goto :end
)

if "%1"=="build" (
    echo 🔨 Сборка образов для Docker Swarm...
    
    echo Сборка основного приложения...
    docker build -t tutor-main-app:latest .
    
    echo Сборка микросервиса уведомлений...
    docker build -t tutor-notification-service:latest ./microservices/notification-service
    
    echo Сборка микросервиса аналитики...
    docker build -t tutor-analytics-service:latest ./microservices/analytics-service
    
    echo ✅ Все образы собраны
    echo.
    echo 📋 Список образов:
    docker images | findstr tutor-
    
    goto :end
)

if "%1"=="deploy" (
    echo 🚀 Развертывание стека в Docker Swarm...
    
    rem Проверяем что Swarm инициализирован
    docker node ls >nul 2>&1
    if %errorlevel% neq 0 (
        echo ❌ Docker Swarm не инициализирован. Запустите: docker-swarm-manage.bat init
        exit /b 1
    )
    
    docker stack deploy -c docker-compose.swarm.yml %STACK_NAME%
    
    echo ⏳ Ожидание запуска сервисов...
    timeout /t 30 /nobreak >nul
    
    echo.
    echo 📊 Статус сервисов:
    docker stack services %STACK_NAME%
    
    goto :end
)

if "%1"=="update" (
    echo 🔄 Обновление сервисов...
    
    if "%2"=="" (
        echo Обновление всех сервисов...
        docker service update --force %STACK_NAME%_main-app
        docker service update --force %STACK_NAME%_notification-service
        docker service update --force %STACK_NAME%_analytics-service
        docker service update --force %STACK_NAME%_nginx
    ) else (
        echo Обновление сервиса %2...
        docker service update --force %STACK_NAME%_%2
    )
    
    goto :end
)

if "%1"=="scale" (
    if "%2"=="" (
        echo ❌ Укажите сервис для масштабирования
        echo Пример: docker-swarm-manage.bat scale main-app 3
        exit /b 1
    )
    
    if "%3"=="" (
        echo ❌ Укажите количество реплик
        exit /b 1
    )
    
    echo 📈 Масштабирование %2 до %3 реплик...
    docker service scale %STACK_NAME%_%2=%3
    
    goto :end
)

if "%1"=="status" (
    echo 📊 Статус Docker Swarm:
    echo.
    
    echo 🔗 Узлы кластера:
    docker node ls
    
    echo.
    echo 📋 Сервисы стека:
    docker stack services %STACK_NAME%
    
    echo.
    echo 🔄 Процессы сервисов:
    docker stack ps %STACK_NAME% --no-trunc
    
    echo.
    echo 🌐 Сети:
    docker network ls | findstr overlay
    
    goto :end
)

if "%1"=="logs" (
    if "%2"=="" (
        echo 📋 Доступные сервисы для просмотра логов:
        docker stack services %STACK_NAME% --format "table {{.Name}}"
        echo.
        echo Использование: docker-swarm-manage.bat logs [service-name]
        exit /b 1
    )
    
    echo 📋 Логи сервиса %2:
    docker service logs -f %STACK_NAME%_%2
    
    goto :end
)

if "%1"=="stop" (
    echo 🛑 Остановка стека %STACK_NAME%...
    docker stack rm %STACK_NAME%
    
    echo ⏳ Ожидание завершения...
    timeout /t 15 /nobreak >nul
    
    echo ✅ Стек остановлен
    
    goto :end
)

if "%1"=="leave" (
    echo ⚠️  Выход из Docker Swarm (это удалит весь кластер!)
    echo Нажмите Ctrl+C для отмены или любую клавишу для продолжения...
    pause >nul
    
    docker swarm leave --force
    echo ✅ Вышли из Docker Swarm
    
    goto :end
)

echo ❌ Неизвестная команда: %1

:end
echo.
echo 🌐 Полезные URL (если развернуто):
echo   - Основное приложение: http://localhost
echo   - Nginx статус: http://localhost/nginx-status  
echo   - Portainer: http://localhost:9000
echo   - Health check: http://localhost/health
echo.