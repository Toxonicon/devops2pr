@echo off
setlocal EnableDelayedExpansion

rem Функция отображения помощи
:show_help
echo 🐳 Docker Compose управление для Tutor Platform
echo.
echo Использование: %~nx0 [КОМАНДА] [ОПЦИИ]
echo.
echo Команды:
echo   up           Запуск всех сервисов
echo   down         Остановка всех сервисов
echo   restart      Перезапуск всех сервисов
echo   logs         Просмотр логов
echo   status       Статус сервисов
echo   build        Сборка образов
echo   clean        Очистка неиспользуемых ресурсов
echo   dev          Запуск в режиме разработки
echo   prod         Запуск в production режиме
echo   health       Проверка состояния сервисов
echo.
echo Опции:
echo   --with-nginx     Запуск с Nginx reverse proxy
echo   --with-redis     Запуск с Redis кешированием
echo   --dev-tools      Включить инструменты разработки (Portainer)
echo   -d               Запуск в фоновом режиме
echo   --build          Пересобрать образы перед запуском
echo.
goto :eof

rem Проверка Docker
:check_docker
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker не установлен. Пожалуйста, установите Docker.
    exit /b 1
)

docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose не установлен. Пожалуйста, установите Docker Compose.
    exit /b 1
)
goto :eof

rem Основная логика
if "%1"=="" goto show_help
if "%1"=="help" goto show_help
if "%1"=="--help" goto show_help
if "%1"=="-h" goto show_help

call :check_docker

rem Построение команды с профилями
set "base_cmd=docker-compose"
set "profiles="

for %%a in (%*) do (
    if "%%a"=="--with-nginx" set "profiles=!profiles! --profile with-nginx"
    if "%%a"=="--with-redis" set "profiles=!profiles! --profile with-redis"
    if "%%a"=="--dev-tools" set "profiles=!profiles! --profile dev-tools"
)

set "cmd=!base_cmd! !profiles!"

if "%1"=="up" (
    echo 📦 Запуск сервисов...
    
    echo %* | findstr /c:"--build" >nul
    if !errorlevel! equ 0 (
        !cmd! up --build %*
    ) else (
        echo %* | findstr /c:"-d" >nul
        if !errorlevel! equ 0 (
            !cmd! up -d
        ) else (
            !cmd! up
        )
    )
    
    if !errorlevel! equ 0 (
        echo.
        echo ✅ Сервисы успешно запущены!
        echo.
        echo 🌐 Доступные сервисы:
        echo   - Основное приложение: http://localhost:3000
        echo   - Микросервис уведомлений: http://localhost:3001
        echo   - Микросервис аналитики: http://localhost:3002
        
        echo %* | findstr /c:"--with-nginx" >nul
        if !errorlevel! equ 0 echo   - Nginx Reverse Proxy: http://localhost:80
        
        echo %* | findstr /c:"--dev-tools" >nul
        if !errorlevel! equ 0 echo   - Portainer: http://localhost:9000
    ) else (
        echo ❌ Ошибка при запуске сервисов!
    )
    
) else if "%1"=="down" (
    echo 🛑 Остановка сервисов...
    !cmd! down
    echo ✅ Сервисы остановлены!
    
) else if "%1"=="restart" (
    echo 🔄 Перезапуск сервисов...
    !cmd! restart
    echo ✅ Сервисы перезапущены!
    
) else if "%1"=="logs" (
    if "%2"=="" (
        !cmd! logs -f
    ) else (
        !cmd! logs -f %2
    )
    
) else if "%1"=="status" (
    echo 📊 Статус сервисов:
    docker-compose ps
    echo.
    echo 📈 Использование ресурсов:
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
) else if "%1"=="build" (
    echo 🔨 Сборка образов...
    !cmd! build --no-cache
    echo ✅ Образы собраны!
    
) else if "%1"=="clean" (
    echo 🧹 Очистка неиспользуемых ресурсов...
    docker system prune -f
    docker volume prune -f
    echo ✅ Очистка завершена!
    
) else if "%1"=="dev" (
    echo 🛠️ Запуск в режиме разработки...
    docker-compose -f docker-compose.yml -f docker-compose.dev.yml up %*
    
) else if "%1"=="prod" (
    echo 🚀 Запуск в production режиме...
    docker-compose -f docker-compose.prod.yml up %*
    
) else if "%1"=="health" (
    echo 🏥 Проверка состояния сервисов:
    
    rem Проверяем основное приложение
    curl -f -s "http://localhost:3000/api/users" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ main-app: Healthy
    ) else (
        echo ❌ main-app: Unhealthy
    )
    
    rem Проверяем сервис уведомлений
    curl -f -s "http://localhost:3001/health" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ notification-service: Healthy
    ) else (
        echo ❌ notification-service: Unhealthy
    )
    
    rem Проверяем сервис аналитики
    curl -f -s "http://localhost:3002/health" >nul 2>&1
    if !errorlevel! equ 0 (
        echo ✅ analytics-service: Healthy
    ) else (
        echo ❌ analytics-service: Unhealthy
    )
    
) else (
    echo ❌ Неизвестная команда: %1
    goto show_help
)

pause