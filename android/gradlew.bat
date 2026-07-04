@echo off
setlocal

where gradle >nul 2>nul
if errorlevel 1 (
    echo ERROR: Gradle is not installed or not on PATH.
    exit /b 1
)

gradle %*
