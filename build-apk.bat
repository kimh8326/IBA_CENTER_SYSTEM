@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM Pilates Center System - Android APK 빌드 스크립트 (Windows용)
REM 이 스크립트를 실행하면 자동으로 Android APK 설치 파일이 생성됩니다.

echo 🏗️  Pilates Center System APK 빌드 시작...
echo =========================================

REM 현재 디렉토리가 올바른지 확인
if not exist "pubspec.yaml" (
    echo ❌ 오류: Flutter 프로젝트 루트 디렉토리에서 실행해주세요.
    echo    client 폴더로 이동 후 다시 실행하세요: cd client
    pause
    exit /b 1
)

REM Flutter가 설치되어 있는지 확인
flutter --version > nul 2>&1
if errorlevel 1 (
    echo ❌ 오류: Flutter가 설치되어 있지 않습니다.
    echo    Flutter를 먼저 설치해주세요: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo 🧹 Flutter 프로젝트 정리 중...
flutter clean

echo 📦 종속성 패키지 다운로드 중...
flutter pub get

echo 🔨 Release APK 빌드 중...
echo    (시간이 오래 걸릴 수 있습니다...)
flutter build apk --release

if !errorlevel! equ 0 (
    echo.
    echo ✅ APK 빌드 성공!
    echo =========================================
    
    REM 생성된 APK 파일 정보
    set "APK_PATH=build\app\outputs\flutter-apk\app-release.apk"
    
    echo 📱 생성된 설치 파일:
    echo    - 파일명: app-release.apk
    echo    - 위치: !APK_PATH!
    
    REM 사용하기 쉬운 이름으로 복사
    copy "!APK_PATH!" "pilates-center-system.apk" > nul
    echo    - 복사본: pilates-center-system.apk (루트 폴더)
    
    echo.
    echo 📲 설치 방법:
    echo    1. Android 기기 설정 ^> 보안 ^> '알 수 없는 소스' 허용
    echo    2. pilates-center-system.apk 파일을 Android 기기로 전송
    echo    3. 파일 매니저에서 APK 파일을 탭하여 설치
    echo.
    echo ⚠️  주의사항:
    echo    - 앱 사용 시 서버가 192.168.1.100:3000에서 실행되어야 합니다
    echo    - 동일한 Wi-Fi 네트워크에 연결되어 있어야 합니다
    echo.
    echo 🎉 빌드 완료!
    
) else (
    echo.
    echo ❌ APK 빌드 실패!
    echo =========================================
    echo 다음을 확인해주세요:
    echo    - Android SDK가 올바르게 설치되어 있는지
    echo    - Flutter doctor 명령으로 환경 설정 확인
    echo    - 네트워크 연결 상태
    echo.
    echo 문제가 지속되면 수동으로 다음 명령을 실행해보세요:
    echo    flutter doctor
    echo    flutter clean
    echo    flutter pub get
    echo    flutter build apk --release
)

pause