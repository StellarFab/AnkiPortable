@echo off
rem ============================================================
rem  Anki Portable Launcher
rem  All user data (collection / add-ons / prefs) is kept in .\Data
rem  Nothing is written to AppData, so the whole folder travels.
rem ============================================================
setlocal

set "HERE=%~dp0"
set "ANKI_BASE=%HERE%Data"
set "ANKI_EXE=%HERE%App\Anki.exe"

if not exist "%ANKI_BASE%" md "%ANKI_BASE%" >nul 2>&1

if not exist "%ANKI_EXE%" (
    echo.
    echo  [ERROR] App\Anki.exe not found.
    echo  Please unzip the whole folder first, and keep the
    echo  App / Data / launcher structure untouched.
    echo.
    pause
    exit /b 1
)

rem ANKI_BASE env var + --base arg: both point Anki at .\Data
set "ANKI_BASE=%ANKI_BASE%"
start "" "%ANKI_EXE%" --base "%ANKI_BASE%"

endlocal
