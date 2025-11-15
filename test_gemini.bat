@echo off
echo Testing Gemini API...

rem Read API key from .env file
for /f "tokens=2 delims==" %%a in ('type .env ^| findstr GEMINI_API_KEY') do set API_KEY=%%a

if "%API_KEY%"=="" (
    echo ERROR: GEMINI_API_KEY not found in .env file
    exit /b 1
)

echo API Key loaded: %API_KEY:~0,20%...

echo.
echo Sending test request to Gemini API...

curl -s -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%API_KEY%" ^
     -H "Content-Type: application/json" ^
     -d "{\"contents\":[{\"parts\":[{\"text\":\"You are testing a disaster prediction system. Current weather: Temperature 35C, Humidity 45%%, Wind 12 m/s, Location: Mumbai (coastal city). Based on this data, what is the wildfire risk percentage (0-100%%) and why? Keep response under 100 words.\"}]}],\"generationConfig\":{\"temperature\":0.7,\"maxOutputTokens\":200}}" > gemini_response.json

echo.
echo Response Status:
curl -s -o /dev/null -w "HTTP Status: %%{http_code}\n" -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=%API_KEY%" ^
     -H "Content-Type: application/json" ^
     -d "{\"contents\":[{\"parts\":[{\"text\":\"Test\"}]}]}"

echo.
echo Response saved to gemini_response.json
if exist gemini_response.json (
    echo.
    echo Raw Response:
    type gemini_response.json
    echo.
    echo.
    echo Checking for successful response...
    findstr /i "candidates" gemini_response.json >nul
    if errorlevel 1 (
        echo ERROR: No candidates found in response
        findstr /i "error" gemini_response.json >nul
        if not errorlevel 1 (
            echo API Error detected in response
        )
    ) else (
        echo SUCCESS: Valid response received from Gemini API!
    )
)

pause