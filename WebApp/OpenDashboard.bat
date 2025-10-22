@echo off
echo.
echo ========================================
echo   Market Prediction Dashboard
echo ========================================
echo.
echo Opening dashboard in browser...
echo.

start "" "%~dp0AdvancedDashboard.html"

echo.
echo Dashboard opened in your browser!
echo.
echo This window will close in 3 seconds...
timeout /t 3 >nul

