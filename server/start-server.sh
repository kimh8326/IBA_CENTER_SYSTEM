#!/bin/bash

# Pilates Center System - 서버 자동 실행 스크립트
# 이 스크립트를 실행하면 필라테스 센터 관리 서버가 시작됩니다.

echo "🏃‍♀️ 필라테스 센터 관리 서버 시작 중..."
echo "========================================="

# 현재 디렉토리가 서버 폴더인지 확인
if [ ! -f "package.json" ]; then
    echo "❌ 오류: 서버 프로젝트 루트 디렉토리에서 실행해주세요."
    echo "   server 폴더로 이동 후 다시 실행하세요: cd server"
    exit 1
fi

# Node.js가 설치되어 있는지 확인
if ! command -v node &> /dev/null; then
    echo "❌ 오류: Node.js가 설치되어 있지 않습니다."
    echo "   Node.js를 먼저 설치해주세요: https://nodejs.org"
    exit 1
fi

# npm이 설치되어 있는지 확인
if ! command -v npm &> /dev/null; then
    echo "❌ 오류: npm이 설치되어 있지 않습니다."
    echo "   npm은 Node.js와 함께 자동 설치됩니다."
    exit 1
fi

echo "📦 의존성 패키지 확인 중..."

# node_modules가 없으면 npm install 실행
if [ ! -d "node_modules" ]; then
    echo "   의존성 패키지를 설치합니다..."
    npm install
    
    if [ $? -ne 0 ]; then
        echo "❌ 의존성 설치 실패!"
        exit 1
    fi
else
    echo "   의존성 패키지가 이미 설치되어 있습니다."
fi

echo ""
echo "🚀 서버 시작 중..."
echo "   종료하려면 Ctrl+C를 누르세요"
echo "========================================="

# 서버 실행
node index.js