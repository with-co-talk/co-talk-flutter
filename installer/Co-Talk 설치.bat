@echo off
chcp 65001 >nul
title Co-Talk 설치
echo.
echo ==========================================
echo        Co-Talk 설치를 시작합니다
echo ==========================================
echo.
echo 관리자 권한이 필요합니다.
echo 권한 요청 창이 나타나면 '예'를 클릭해주세요.
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

