@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM Pilates Center System - 서버 자동 실행 스크립트 (Windows용)
REM 이 스크립트를 실행하면 필라테스 센터 관리 서버가 시작됩니다.

echo 🏃‍♀️ 필라테스 센터 관리 서버 시작 중...
echo =========================================

REM 현재 디렉토리가 서버 폴더인지 확인
if not exist "package.json" (
    echo ❌ 오류: 서버 프로젝트 루트 디렉토리에서 실행해주세요.
    echo    server 폴더로 이동 후 다시 실행하세요: cd server
    pause
    exit /b 1
)

REM Node.js가 설치되어 있는지 확인
node --version > nul 2>&1
if errorlevel 1 (
    echo ❌ 오류: Node.js가 설치되어 있지 않습니다.
    echo    Node.js를 먼저 설치해주세요: https://nodejs.org
    pause
    exit /b 1
)

REM npm이 설치되어 있는지 확인
npm --version > nul 2>&1
if errorlevel 1 (
    echo ❌ 오류: npm이 설치되어 있지 않습니다.
    echo    npm은 Node.js와 함께 자동 설치됩니다.
    pause
    exit /b 1
)

echo 📦 의존성 패키지 확인 중...

REM node_modules가 없으면 npm install 실행
if not exist "node_modules" (
    echo    의존성 패키지를 설치합니다...
    npm install
    
    if !errorlevel! neq 0 (
        echo ❌ 의존성 설치 실패!
        pause
        exit /b 1
    )
) else (
    echo    의존성 패키지가 이미 설치되어 있습니다.
)

echo.
echo 🚀 서버 시작 중...
echo    종료하려면 Ctrl+C를 누르세요
echo =========================================

REM 서버 실행
node index.js

pause