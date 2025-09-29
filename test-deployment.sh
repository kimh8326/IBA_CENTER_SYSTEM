#!/bin/bash

# 필라테스 센터 시스템 배포 테스트 스크립트

echo "🏗️ 필라테스 센터 시스템 배포 테스트"
echo "========================================"

# 환경 설정 확인
echo "1. 네트워크 환경 확인..."
NETWORK_IP=$(ipconfig getifaddr en0)
echo "   현재 네트워크 IP: $NETWORK_IP"

# 서버 시작 테스트
echo "2. 서버 실행 테스트..."
cd server
npm install > /dev/null 2>&1
node index.js &
SERVER_PID=$!
sleep 3

# 서버 상태 확인
if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "   ✅ localhost:3000 서버 정상"
else
    echo "   ❌ localhost:3000 서버 연결 실패"
fi

if curl -s http://$NETWORK_IP:3000/api/health > /dev/null; then
    echo "   ✅ $NETWORK_IP:3000 네트워크 접근 정상"
else
    echo "   ❌ $NETWORK_IP:3000 네트워크 접근 실패"
fi

# 클라이언트 빌드 테스트
echo "3. 클라이언트 빌드 테스트..."
cd ../client

echo "   🌐 웹 빌드 테스트..."
flutter build web --release > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ 웹 빌드 성공"
else
    echo "   ❌ 웹 빌드 실패"
fi

echo "   📱 Android APK 빌드 테스트..."
flutter build apk --release > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ Android APK 빌드 성공"
else
    echo "   ❌ Android APK 빌드 실패"
fi

echo "   🖥️ macOS 앱 빌드 테스트..."
flutter build macos --release > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ macOS 앱 빌드 성공"
else
    echo "   ❌ macOS 앱 빌드 실패"
fi

# 서버 종료
kill $SERVER_PID

echo ""
echo "🎉 배포 테스트 완료!"
echo "========================================"
echo "📋 배포 체크리스트:"
echo "   □ 서버 PC의 고정 IP 설정 완료"
echo "   □ Wi-Fi 네트워크 설정 완료"  
echo "   □ 방화벽 3000 포트 허용"
echo "   □ 클라이언트 앱 배포 및 테스트"
echo "   □ 여러 기기에서 동시 접속 테스트"