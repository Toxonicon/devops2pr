@echo off
echo 🔍 Проверка работы микросервисов...
echo.

echo 📊 Проверка основного приложения (порт 3000)...
curl -s -o nul -w "Status: %%{http_code}" http://localhost:3000/api/users
echo.

echo 📨 Проверка микросервиса уведомлений (порт 3001)...
curl -s -o nul -w "Status: %%{http_code}" http://localhost:3001/health
echo.

echo 📈 Проверка микросервиса аналитики (порт 3002)...
curl -s -o nul -w "Status: %%{http_code}" http://localhost:3002/health
echo.

echo 🔗 Проверка взаимодействия микросервисов...
curl -s -o nul -w "Status: %%{http_code}" http://localhost:3000/api/microservices/status
echo.

echo ✅ Проверка завершена!
echo.
echo 🌐 Доступные сервисы:
echo   - Основное приложение: http://localhost:3000
echo   - Микросервис уведомлений: http://localhost:3001
echo   - Микросервис аналитики: http://localhost:3002
echo.

pause