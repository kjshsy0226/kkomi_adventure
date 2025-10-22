@echo off
title Kkomi Viewer
REM 1) 내장 서버 실행 (포트 8080)
REM Windows에 Python 3가 깔려있으면:
python -m http.server 8080 --directory "%~dp0build\web"
REM 고객 PC에 파이썬이 없다면, 대신 server.exe 같은 경량 http 서버 바이너리로 대체
