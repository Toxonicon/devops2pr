@echo off
echo 🚀 Демонстрация Docker Swarm для платформы репетитора
echo =======================================================
echo.

echo 📋 Этот скрипт продемонстрирует:
echo   1. Инициализацию Docker Swarm
echo   2. Сборку образов для микросервисов
echo   3. Развертывание в Swarm режиме
echo   4. Настройку NGINX Load Balancer
echo   5. Мониторинг и масштабирование
echo.

pause

rem Проверяем Docker
echo 🔍 Проверка Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker не установлен или не запущен
    echo    Установите Docker Desktop и запустите его
    pause
    exit /b 1
)
echo ✅ Docker доступен

echo.
echo 🐳 Шаг 1: Инициализация Docker Swarm
echo ====================================
call docker-swarm-manage.bat init

echo.
echo 🔨 Шаг 2: Сборка образов микросервисов
echo =====================================
call docker-swarm-manage.bat build

echo.
echo 🚀 Шаг 3: Развертывание основных сервисов
echo ========================================
call docker-swarm-manage.bat deploy

echo.
echo ⏳ Ожидание запуска всех сервисов...
timeout /t 45 /nobreak >nul

echo.
echo 📊 Шаг 4: Проверка статуса сервисов
echo ==================================
call docker-swarm-manage.bat status

echo.
echo 🌐 Шаг 5: Проверка работы приложения
echo ===================================

echo Проверка health endpoints...
echo.

echo Основное приложение:
curl -s -o nul -w "Status: %%{http_code}\n" http://localhost:3000/api/users || echo "Недоступно"

echo NGINX Load Balancer:
curl -s -o nul -w "Status: %%{http_code}\n" http://localhost/health || echo "Недоступно"

echo Микросервис уведомлений:
curl -s -o nul -w "Status: %%{http_code}\n" http://localhost:3001/health || echo "Недоступно"

echo Микросервис аналитики:
curl -s -o nul -w "Status: %%{http_code}\n" http://localhost:3002/health || echo "Недоступно"

echo.
echo 📈 Шаг 6: Демонстрация масштабирования
echo =====================================

echo Текущее количество реплик:
docker service ls --format "table {{.Name}}\t{{.Replicas}}"

echo.
echo Масштабируем основное приложение до 3 реплик...
call docker-swarm-manage.bat scale main-app 3

echo.
echo Масштабируем микросервис уведомлений до 3 реплик...
call docker-swarm-manage.bat scale notification-service 3

echo.
echo Новое количество реплик:
docker service ls --format "table {{.Name}}\t{{.Replicas}}"

echo.
echo 📊 Шаг 7: Развертывание мониторинга
echo ==================================

echo Развертываем Prometheus и Grafana...
docker stack deploy -c docker-compose.monitoring.yml monitoring

echo.
echo ⏳ Ожидание запуска мониторинга...
timeout /t 30 /nobreak >nul

echo.
echo 📋 Финальный статус всех сервисов:
docker stack ls
echo.
docker service ls

echo.
echo 🎉 Демонстрация завершена!
echo ==========================
echo.
echo 🌐 Доступные сервисы:
echo   📱 Основное приложение:    http://localhost
echo   📊 Мониторинг (Prometheus): http://localhost:9090  
echo   📈 Графики (Grafana):      http://localhost:3001 (admin/admin123)
echo   🔧 Управление (Portainer): http://localhost:9000
echo   ❤️  Health Check:          http://localhost/health
echo   📊 Nginx Status:           http://localhost/nginx-status
echo.
echo 💡 Полезные команды для дальнейшей работы:
echo   docker-swarm-manage.bat status     - статус сервисов
echo   docker-swarm-manage.bat logs       - просмотр логов
echo   docker-swarm-manage.bat scale      - масштабирование
echo   docker-swarm-manage.bat stop       - остановка всех сервисов
echo.
echo 📖 Подробная документация: DOCKER_SWARM_README.md
echo.

set /p answer="Открыть основное приложение в браузере? (y/n): "
if /i "%answer%"=="y" start http://localhost

echo.
echo Нажмите любую клавишу для завершения...
pause >nul