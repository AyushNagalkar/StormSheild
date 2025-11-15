@echo off
echo Testing Gemini API with correct model name...

rem Read API key from .env file
for /f "tokens=2 delims==" %%a in ('type .env ^| findstr GEMINI_API_KEY') do set API_KEY=%%a

if "%API_KEY%"=="" (
    echo ERROR: GEMINI_API_KEY not found in .env file
    pause
    exit /b 1
)

echo API Key loaded: %API_KEY:~0,20%...
echo.
echo Testing with model: gemini-2.5-flash
echo.

curl -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=%API_KEY%" ^
     -H "Content-Type: application/json" ^
     -d "{\"contents\":[{\"parts\":[{\"text\":\"You are testing a disaster prediction system. Current weather: Temperature 35C, Humidity 45%%, Wind 12 m/s, Location: Mumbai (coastal city). Based on this data, what is the wildfire risk percentage (0-100%%) and why? Keep response under 100 words.\"}]}],\"generationConfig\":{\"temperature\":0.7,\"maxOutputTokens\":200}}"

echo.
echo.
echo Test complete!
pause
