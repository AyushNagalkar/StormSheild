@echo off
echo Reading API key from .env file...

rem Read API key from .env file
for /f "tokens=2 delims==" %%a in ('type .env ^| findstr GEMINI_API_KEY') do set API_KEY=%%a

if "%API_KEY%"=="" (
    echo ERROR: GEMINI_API_KEY not found in .env file
    pause
    exit /b 1
)

echo API Key loaded: %API_KEY:~0,20%...
echo.
echo Fetching available Gemini models...
echo.

curl -s "https://generativelanguage.googleapis.com/v1beta/models?key=%API_KEY%"

echo.
echo.
echo Test complete. Check the model names above.
pause
