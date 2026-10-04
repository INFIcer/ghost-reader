@echo off
rem ============================================================================
rem  build-mod.bat  --  Factorio mod packager (launcher)
rem
rem  Put build-mod.bat + build-mod.ps1 in the mod root (next to info.json) and
rem  double-click build-mod.bat.
rem
rem  What it does:
rem    1. reads name/version/title from info.json
rem    2. packs the mod into <modname>_<version>.zip  (dev-only files are skipped)
rem    3. detects the local Factorio mods folder and copies the zip there
rem
rem  Optional command line arguments (passed straight to build-mod.ps1):
rem    build-mod.bat -ModsDir "D:\Factorio\mods"   force a specific mods folder
rem    build-mod.bat -NoDeploy                     only build, do not copy
rem    build-mod.bat -KeepOld                      keep installed older versions
rem    build-mod.bat -Open                         open the output folder when done
rem ============================================================================
setlocal EnableExtensions
chcp 65001 >nul 2>&1
title Factorio mod packager

set "MOD_ROOT=%~dp0"
set "PS_SCRIPT=%~dp0build-mod.ps1"

if not exist "%PS_SCRIPT%" (
  echo.
  echo [ERROR] build-mod.ps1 not found next to this file:
  echo         "%PS_SCRIPT%"
  echo         Keep build-mod.bat and build-mod.ps1 in the same folder.
  echo.
  pause
  exit /b 1
)

set "PS_EXE=powershell.exe"
where pwsh.exe >nul 2>&1 && set "PS_EXE=pwsh.exe"

rem MOD_ROOT is handed over through the environment: "%~dp0" ends with a
rem backslash which would escape the closing quote of a -ModRoot "..." argument.
"%PS_EXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
set "RC=%ERRORLEVEL%"

echo.
if not "%RC%"=="0" (
  echo [FAILED] exit code %RC%
) else (
  echo [DONE]
)
echo.
pause
exit /b %RC%
