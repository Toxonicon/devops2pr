@echo off
echo 🐳 Демонстрация Docker Compose конфигурации
echo ============================================
echo.

echo 📋 Проверка файлов конфигурации...
echo.

rem Проверяем наличие Docker Compose файлов
set files=docker-compose.yml docker-compose.dev.yml docker-compose.prod.yml docker-compose.override.yml

for %%f in (%files%) do (
    if exist "%%f" (
        echo ✅ %%f - найден
    ) else (
        echo ❌ %%f - не найден
    )
)

echo.
echo 📋 Проверка Dockerfile для каждого микросервиса...
echo.

rem Проверяем Dockerfile микросервисов
if exist "Dockerfile" (
    echo ✅ Dockerfile - найден
) else (
    echo ❌ Dockerfile - не найден
)

if exist "microservices\notification-service\Dockerfile" (
    echo ✅ microservices\notification-service\Dockerfile - найден
) else (
    echo ❌ microservices\notification-service\Dockerfile - не найден
)

if exist "microservices\analytics-service\Dockerfile" (
    echo ✅ microservices\analytics-service\Dockerfile - найден
) else (
    echo ❌ microservices\analytics-service\Dockerfile - не найден
)

echo.
echo 🔧 Проверка валидности конфигурации Docker Compose...
echo.

rem Попытаемся проверить конфигурацию
docker-compose --version >nul 2>&1
if %errorlevel% equ 0 (
    docker-compose config --quiet >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ docker-compose.yml валиден
    ) else (
        echo ❌ Ошибка в docker-compose.yml или Docker не запущен
    )
) else (
    echo ⚠️  Docker Compose не установлен или Docker не запущен
)

echo.
echo 🚀 Команды для запуска (когда Docker будет доступен):
echo.
echo # Запуск в режиме разработки:
echo docker-compose up --build
echo.
echo # Запуск в фоновом режиме:
echo docker-compose up -d --build
echo.
echo # Запуск с дополнительными сервисами:
echo docker-compose --profile with-nginx up -d
echo.
echo # Production запуск:
echo docker-compose -f docker-compose.prod.yml up -d
echo.
echo # Использование скрипта управления:
echo docker-manage.bat up --build -d
echo.

echo 📊 Текущие запущенные сервисы (локально):
echo.

rem Проверяем локально запущенные сервисы
echo Проверка порта 3000 (Основное приложение)...
netstat -an | find "3000" | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo ✅ Основное приложение (порт 3000) - запущен
) else (
    echo ❌ Основное приложение (порт 3000) - не запущен
)

echo Проверка порта 3001 (Сервис уведомлений)...
netstat -an | find "3001" | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo ✅ Сервис уведомлений (порт 3001) - запущен
) else (
    echo ❌ Сервис уведомлений (порт 3001) - не запущен
)

echo Проверка порта 3002 (Сервис аналитики)...
netstat -an | find "3002" | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo ✅ Сервис аналитики (порт 3002) - запущен
) else (
    echo ❌ Сервис аналитики (порт 3002) - не запущен
)

echo.
echo 🌐 Для проверки откройте в браузере:
echo   - http://localhost:3000 - Основное приложение
echo   - http://localhost:3001/health - Health check уведомлений  
echo   - http://localhost:3002/health - Health check аналитики
echo.

echo 📋 Структура проекта:
echo ├── docker-compose.yml          # Основная конфигурация
echo ├── docker-compose.dev.yml      # Для разработки
echo ├── docker-compose.prod.yml     # Для production
echo ├── Dockerfile                  # Основное приложение
echo ├── microservices/
echo │   ├── notification-service/
echo │   │   └── Dockerfile          # Микросервис уведомлений
echo │   └── analytics-service/
echo │       └── Dockerfile          # Микросервис аналитики
echo └── nginx.conf                  # Конфигурация Nginx

pause