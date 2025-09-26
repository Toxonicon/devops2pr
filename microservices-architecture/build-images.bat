@echo off
echo 🐳 Сборка Docker образов для микросервисов...

rem Переходим в корневую директорию проекта
cd /d "%~dp0"

rem Функция для сборки образа
:build_image
set service_name=%1
set dockerfile_path=%2
set image_name=%3

echo 📦 Собираем образ для %service_name%...

docker build -t %image_name% -f %dockerfile_path% .
if %errorlevel% neq 0 (
    echo ❌ Ошибка сборки образа %image_name%
    pause
    exit /b 1
) else (
    echo ✅ Образ %image_name% успешно собран
)
goto :eof

rem Сборка основного приложения
echo 🏗️ Сборка основного приложения...
call :build_image "Main Application" "Dockerfile" "tutor-platform:latest"

rem Сборка микросервиса уведомлений
echo 🏗️ Сборка микросервиса уведомлений...
call :build_image "Notification Service" "microservices/notification-service/Dockerfile" "notification-service:latest"

rem Сборка микросервиса аналитики
echo 🏗️ Сборка микросервиса аналитики...
call :build_image "Analytics Service" "microservices/analytics-service/Dockerfile" "analytics-service:latest"

echo.
echo 🎉 Все образы успешно собраны!
echo.
echo 📋 Собранные образы:
echo   - tutor-platform:latest
echo   - notification-service:latest
echo   - analytics-service:latest
echo.
echo 🚀 Для запуска используйте:
echo   docker-compose up -d
echo.
echo 📊 Проверить образы:
echo   docker images

pause