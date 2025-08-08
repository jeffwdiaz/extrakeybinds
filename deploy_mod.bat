@echo off
echo Deploying ExtraKeybinds mod to Project Zomboid workshop...

REM Get the current directory (where this batch file is located)
set "SOURCE_DIR=%~dp0ExtraKeybinds"

REM Set the destination directory (Project Zomboid workshop folder)
set "DEST_DIR=C:\Users\jeffw\Zomboid\Workshop\ExtraKeybinds"

REM Check if source directory exists
if not exist "%SOURCE_DIR%" (
    echo ERROR: Source directory not found: %SOURCE_DIR%
    echo Make sure this batch file is in the same directory as the ExtraKeybinds folder
    pause
    exit /b 1
)

REM Create destination directory if it doesn't exist
if not exist "%DEST_DIR%" (
    echo Creating destination directory: %DEST_DIR%
    mkdir "%DEST_DIR%"
)

REM Remove existing mod folder if it exists
if exist "%DEST_DIR%" (
    echo Removing existing mod folder...
    rmdir /s /q "%DEST_DIR%"
)

REM Copy the mod folder
echo Copying mod files...
xcopy "%SOURCE_DIR%" "%DEST_DIR%" /e /i /y

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: ExtraKeybinds mod has been deployed to:
    echo %DEST_DIR%
    echo.
    echo You can now test the mod in Project Zomboid!
) else (
    echo.
    echo ERROR: Failed to copy mod files
    echo Error code: %ERRORLEVEL%
)

pause 