@echo off
chcp 65001 >nul
title Co-Talk 릴리즈 빌드

cd /d "%~dp0.."
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build_release.ps1"
