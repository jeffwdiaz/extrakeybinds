@echo off
REM ========================================
REM Steam Workshop Upload Script
REM ========================================
REM 
REM This script uploads a Project Zomboid mod to Steam Workshop using SteamCMD.
REM 
REM REQUIREMENTS:
REM - SteamCMD installed at C:\SteamCMD\steamcmd.exe
REM - workshop.txt file in your mod folder
REM - Valid Steam account with Workshop upload permissions
REM
REM USAGE:
REM 1. Place this script in your mod's parent directory
REM 2. Update the MOD_FOLDER variable below to match your mod folder name
REM 3. Run this script
REM
REM ========================================

REM CONFIGURATION - UPDATE THESE FOR YOUR MOD
set "MOD_FOLDER=ExtraKeybinds"
set "STEAMCMD_PATH=C:\SteamCMD\steamcmd.exe"

REM Build paths based on mod folder
set "WORKSHOP_FILE=%~dp0%MOD_FOLDER%\workshop.txt"

echo Uploading %MOD_FOLDER% mod to Steam Workshop...

REM ========================================
REM VALIDATION CHECKS
REM ========================================

REM Check if SteamCMD exists
if not exist "%STEAMCMD_PATH%" (
    echo ERROR: SteamCMD not found at %STEAMCMD_PATH%
    echo.
    echo SOLUTION: Run the download_steamcmd.bat script first to install SteamCMD
    echo Or manually download from: https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip
    echo.
    pause
    exit /b 1
)

REM Check if workshop.txt exists
if not exist "%WORKSHOP_FILE%" (
    echo ERROR: workshop.txt not found at %WORKSHOP_FILE%
    echo.
    echo SOLUTION: Make sure you have a workshop.txt file in your %MOD_FOLDER% directory
    echo The file should contain your Workshop item configuration
    echo.
    pause
    exit /b 1
)

echo.
echo Starting Steam Workshop upload...
echo You will be prompted to enter your Steam username and password
echo.

REM Upload to workshop
REM Try with force_install_dir to avoid network issues
"%STEAMCMD_PATH%" +force_install_dir "%~dp0" +login +workshop_build_item "%WORKSHOP_FILE%" +quit

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS: Mod uploaded to Steam Workshop!
    echo.
    echo If this was your first upload, SteamCMD will have updated the publishedfileid
    echo in your workshop.txt file. Use that ID for future updates.
) else (
    echo.
    echo ERROR: Upload failed with error code %ERRORLEVEL%
    echo.
    echo Common issues:
    echo - Check your Steam username/password
    echo - Make sure you have Steam Guard enabled
    echo - Verify all files exist in the content folder
)

pause
