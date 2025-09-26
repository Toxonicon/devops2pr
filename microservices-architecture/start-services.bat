@echo off
echo 🚀 Запуск платформы репетитора с микросервисами...

rem Проверяем, что Docker установлен
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker не найден. Пожалуйста, установите Docker.
    pause
    exit /b 1
)

rem Проверяем, что Docker Compose установлен
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker Compose не найден. Пожалуйста, установите Docker Compose.
    pause
    exit /b 1
)

rem Останавливаем существующие контейнеры
echo 🛑 Остановка существующих контейнеров...
docker-compose down

rem Собираем образы
echo 🔨 Сборка Docker образов...
docker-compose build

rem Запускаем сервисы
echo 🚀 Запуск сервисов...
docker-compose up -d

rem Ждем запуска сервисов
echo ⏳ Ожидание запуска сервисов...
timeout /t 10 /nobreak >nul

rem Проверяем статус сервисов
echo 📊 Проверка статуса сервисов...
docker-compose ps

echo.
echo ✅ Все сервисы запущены!
echo.
echo 🌐 Доступные сервисы:
echo   - Основное приложение: http://localhost:3000
echo   - Сервис уведомлений: http://localhost:3001
echo   - Сервис аналитики: http://localhost:3002
echo.
echo 📋 Полезные команды:
echo   - Просмотр логов: docker-compose logs -f
echo   - Остановка: docker-compose down
echo   - Перезапуск: docker-compose restart

pause