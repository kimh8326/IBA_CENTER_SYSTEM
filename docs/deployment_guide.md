# 필라테스 센터 관리 시스템 배포 가이드

## 문서 정보
- **시스템명**: 필라테스 센터 관리 시스템 (Pilates Center Management System)
- **버전**: 1.0.0
- **작성일**: 2025-09-03
- **작성자**: Claude AI
- **문서 목적**: 시스템 배포 및 운영을 위한 상세 가이드

---

## 1. 배포 개요

### 1.1 배포 목적
- **운영 환경 구축**: 개발 완료된 시스템을 실제 운영 환경에 배포
- **안정성 확보**: 24/7 안정적인 서비스 제공
- **성능 최적화**: 실제 사용 환경에서의 최적 성능 구현
- **유지보수 지원**: 효율적인 모니터링 및 관리 체계 구축

### 1.2 배포 환경
- **운영 모델**: On-Premise (로컬 네트워크)
- **네트워크**: 센터 내부 Wi-Fi (192.168.1.x/24)
- **서버**: 전용 PC 또는 미니 PC
- **클라이언트**: 웹 브라우저 (Chrome, Safari, Edge)
- **데이터베이스**: SQLite (파일 기반)

### 1.3 배포 특징
- **0원 운영비**: 클라우드 서버 불필요
- **설치 한 번**: 영구 사용 가능
- **로컬 네트워크**: 초고속 응답 속도
- **데이터 보안**: 외부 유출 불가능

---

## 2. 시스템 요구사항

### 2.1 하드웨어 요구사항

#### 서버 PC (최소 사양)
- **CPU**: Intel i3-8세대 또는 AMD Ryzen 3 이상
- **메모리**: 8GB RAM 이상 (16GB 권장)
- **저장공간**: SSD 256GB 이상 (500GB 권장)
- **네트워크**: 유선 LAN (Gigabit 권장)
- **전원**: UPS 연결 권장 (정전 대비)

#### 서버 PC (권장 사양)
- **CPU**: Intel i5-10세대 또는 AMD Ryzen 5 이상
- **메모리**: 16GB RAM 이상
- **저장공간**: SSD 500GB 이상
- **네트워크**: 유선 LAN + Wi-Fi
- **백업**: 외장 하드 또는 NAS 연결

#### 클라이언트 기기
- **데스크톱**: 웹 브라우저 지원되는 모든 PC/Mac
- **모바일**: Android 6.0+ / iOS 12.0+
- **태블릿**: iPad, Android 태블릿
- **네트워크**: 센터 내부 Wi-Fi 연결 필수

### 2.2 소프트웨어 요구사항

#### 서버 운영체제
- **Windows**: Windows 10 Pro 이상 (권장)
- **macOS**: macOS 11.0 (Big Sur) 이상
- **Linux**: Ubuntu 20.04 LTS 이상

#### 필수 소프트웨어
- **Node.js**: v18.0 이상
- **Git**: 버전 관리 (선택)
- **PM2**: 프로세스 관리 (권장)
- **백업 소프트웨어**: 자동 백업용

#### 클라이언트 브라우저
- **Chrome**: 90 버전 이상
- **Safari**: 14 버전 이상
- **Edge**: 90 버전 이상
- **Firefox**: 88 버전 이상 (선택)

---

## 3. 네트워크 설정

### 3.1 네트워크 구성도

```
인터넷 (ISP)
     │
     ▼
┌─────────────┐
│   공유기     │ (192.168.1.1)
│  (Router)   │
└─────────────┘
     │
     ├─ 서버 PC (192.168.1.100) - 고정 IP
     │
     ├─ 관리자 PC (192.168.1.101)
     │
     ├─ 강사 태블릿 (192.168.1.102~105)
     │
     └─ 회원 기기들 (192.168.1.110~150)
```

### 3.2 서버 IP 고정 설정

#### Windows 10/11
1. **설정** > **네트워크 및 인터넷** > **이더넷**
2. **어댑터 옵션 변경** 클릭
3. **이더넷** 우클릭 > **속성**
4. **인터넷 프로토콜 버전 4 (TCP/IPv4)** 선택 > **속성**
5. **다음 IP 주소 사용** 선택:
   - IP 주소: `192.168.1.100`
   - 서브넷 마스크: `255.255.255.0`
   - 기본 게이트웨이: `192.168.1.1`
   - DNS 서버: `8.8.8.8`, `8.8.4.4`

#### macOS
1. **시스템 환경설정** > **네트워크**
2. **이더넷** 선택
3. **고급** > **TCP/IP**
4. **IPv4 구성**을 **수동**으로 변경
5. IP 정보 입력 (위와 동일)

#### Ubuntu Linux
```bash
# /etc/netplan/01-netcfg.yaml 파일 편집
sudo nano /etc/netplan/01-netcfg.yaml

# 다음 내용 입력
network:
  version: 2
  ethernets:
    enp0s3:  # 네트워크 인터페이스명
      dhcp4: no
      addresses: [192.168.1.100/24]
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]

# 설정 적용
sudo netplan apply
```

### 3.3 포트 설정

#### 필요 포트
- **3000**: Node.js API 서버
- **8080**: Flutter 웹 앱 (개발 모드)
- **80/443**: HTTP/HTTPS (프로덕션, 선택)

#### 방화벽 설정 (Windows)
```cmd
# 방화벽에서 포트 3000 허용
netsh advfirewall firewall add rule name="Pilates Server" dir=in action=allow protocol=TCP localport=3000

# 방화벽에서 포트 8080 허용
netsh advfirewall firewall add rule name="Pilates Client" dir=in action=allow protocol=TCP localport=8080
```

---

## 4. 시스템 설치

### 4.1 Node.js 설치

#### Windows
1. [Node.js 공식 사이트](https://nodejs.org)에서 LTS 버전 다운로드
2. 설치 파일 실행 후 기본값으로 설치
3. 설치 완료 후 명령 프롬프트에서 확인:
```cmd
node --version
npm --version
```

#### macOS
```bash
# Homebrew 사용
brew install node

# 또는 공식 인스톨러 사용
# https://nodejs.org에서 다운로드
```

#### Ubuntu Linux
```bash
# NodeSource 저장소 추가
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Node.js 설치
sudo apt-get install -y nodejs

# 설치 확인
node --version
npm --version
```

### 4.2 Flutter 설치 (클라이언트 개발/빌드용)

#### Windows
1. [Flutter 공식 사이트](https://flutter.dev/docs/get-started/install/windows)에서 SDK 다운로드
2. 압축 해제 후 PATH 환경변수에 flutter/bin 추가
3. 설치 확인:
```cmd
flutter doctor
```

#### macOS
```bash
# Homebrew 사용
brew install --cask flutter

# 설치 확인
flutter doctor
```

### 4.3 프로젝트 파일 설치

#### 방법 1: Git을 사용한 설치 (권장)
```bash
# 프로젝트 클론
git clone [repository-url] pilates_center_system
cd pilates_center_system

# 서버 의존성 설치
cd server
npm install

# 클라이언트 의존성 설치
cd ../client
flutter pub get

# 빌드 파일 생성
flutter build web
```

#### 방법 2: 압축 파일을 사용한 설치
1. 제공받은 프로젝트 압축 파일을 원하는 위치에 압축 해제
2. 위의 의존성 설치 단계 실행

---

## 5. 데이터베이스 초기화

### 5.1 자동 초기화
시스템 첫 실행 시 자동으로 데이터베이스가 생성되며, 다음 작업이 수행됩니다:

1. **데이터베이스 파일 생성**: `pilates_center.db`
2. **테이블 생성**: 13개 테이블 자동 생성
3. **기본 데이터 삽입**: 
   - 관리자 계정 생성 (admin/admin123)
   - 기본 수업 타입 데이터
   - 시스템 설정값

### 5.2 수동 초기화 (필요시)

```bash
# 서버 디렉토리에서
cd server

# 기존 데이터베이스 백업 (있는 경우)
mv pilates_center.db pilates_center_backup.db

# 서버 실행으로 자동 초기화
npm start
```

### 5.3 초기 관리자 계정

- **사용자명**: admin
- **비밀번호**: admin123
- **권한**: 관리자 (모든 기능 접근 가능)

⚠️ **보안 주의**: 첫 로그인 후 반드시 비밀번호를 변경하세요.

---

## 6. 서비스 실행

### 6.1 개발 모드 실행

#### 서버 실행
```bash
cd server
npm start
```

#### 클라이언트 실행 (개발 모드)
```bash
cd client
flutter run -d web-server --web-port 8080
```

### 6.2 프로덕션 모드 실행

#### PM2를 사용한 서버 실행 (권장)
```bash
# PM2 전역 설치
npm install -g pm2

# 서버 실행
cd server
pm2 start index.js --name pilates-server

# 시스템 시작 시 자동 실행 설정
pm2 startup
pm2 save
```

#### 클라이언트 빌드 및 서빙
```bash
# 웹 빌드
cd client
flutter build web --release

# 빌드 파일을 서버 static 폴더로 복사
cp -r build/web/* ../server/public/
```

#### 서버에서 정적 파일 서빙 설정
```javascript
// server/index.js에 추가
app.use(express.static('public'));

// 모든 라우트를 index.html로 리다이렉트 (SPA)
app.get('*', (req, res) => {
  if (req.path.startsWith('/api/')) {
    return res.status(404).json({ error: 'API endpoint not found' });
  }
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});
```

---

## 7. 서비스 관리

### 7.1 PM2를 사용한 프로세스 관리

#### 기본 명령어
```bash
# 서비스 상태 확인
pm2 status

# 서비스 재시작
pm2 restart pilates-server

# 서비스 중지
pm2 stop pilates-server

# 서비스 삭제
pm2 delete pilates-server

# 로그 확인
pm2 logs pilates-server

# 모니터링
pm2 monit
```

#### PM2 설정 파일 (ecosystem.config.js)
```javascript
module.exports = {
  apps: [{
    name: 'pilates-server',
    script: 'index.js',
    cwd: '/path/to/pilates_center_system/server',
    instances: 1,
    exec_mode: 'fork',
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/pilates/error.log',
    out_file: '/var/log/pilates/access.log',
    log_file: '/var/log/pilates/combined.log',
    time: true
  }]
};
```

### 7.2 Windows 서비스로 등록 (선택)

#### PM2를 Windows 서비스로 등록
```cmd
# pm2-windows-service 설치
npm install -g pm2-windows-service

# 서비스 등록
pm2-service-install -n PilatesCenter
```

#### 수동 Windows 서비스 생성 (NSSM 사용)
```cmd
# NSSM 다운로드: https://nssm.cc/download

# 서비스 설치
nssm install PilatesCenter "C:\Program Files\nodejs\node.exe"
nssm set PilatesCenter AppDirectory "C:\pilates_center_system\server"
nssm set PilatesCenter AppParameters "index.js"
nssm set PilatesCenter Description "Pilates Center Management System"

# 서비스 시작
nssm start PilatesCenter
```

---

## 8. 백업 및 복원

### 8.1 자동 백업 스크립트

#### Windows 배치 파일 (backup.bat)
```batch
@echo off
set DATE=%date:~10,4%%date:~4,2%%date:~7,2%
set TIME=%time:~0,2%%time:~3,2%
set TIMESTAMP=%DATE%_%TIME%

mkdir "C:\pilates_backup\%TIMESTAMP%"

# 데이터베이스 백업
copy "C:\pilates_center_system\server\pilates_center.db" "C:\pilates_backup\%TIMESTAMP%\"

# 업로드 파일 백업
xcopy "C:\pilates_center_system\server\uploads" "C:\pilates_backup\%TIMESTAMP%\uploads\" /E /I

# 30일 이상 된 백업 삭제
forfiles /p "C:\pilates_backup" /m *.* /d -30 /c "cmd /c if @isdir==TRUE rd /s /q @path"

echo Backup completed: %TIMESTAMP%
```

#### Linux/macOS 쉘 스크립트 (backup.sh)
```bash
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M)
BACKUP_DIR="/backup/pilates/$DATE"
SOURCE_DIR="/home/pilates/pilates_center_system/server"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 데이터베이스 백업
cp "$SOURCE_DIR/pilates_center.db" "$BACKUP_DIR/"

# 업로드 파일 백업
tar -czf "$BACKUP_DIR/uploads.tar.gz" -C "$SOURCE_DIR" uploads/

# 로그 파일 백업
cp -r "$SOURCE_DIR/logs" "$BACKUP_DIR/" 2>/dev/null || :

# 30일 이상 된 백업 삭제
find /backup/pilates -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null || :

echo "Backup completed: $DATE"
```

#### Cron을 이용한 자동 백업 설정
```bash
# crontab 편집
crontab -e

# 매일 새벽 2시 백업 실행
0 2 * * * /path/to/backup.sh >> /var/log/pilates_backup.log 2>&1
```

### 8.2 복원 절차

#### 데이터베이스 복원
```bash
# 서버 중지
pm2 stop pilates-server

# 현재 DB 백업
mv pilates_center.db pilates_center_current.db

# 백업 파일로부터 복원
cp /backup/pilates/20250903_0200/pilates_center.db ./

# 서버 재시작
pm2 start pilates-server
```

#### 업로드 파일 복원
```bash
# 현재 파일 백업
mv uploads uploads_current

# 백업 파일 복원
tar -xzf /backup/pilates/20250903_0200/uploads.tar.gz
```

---

## 9. 모니터링 및 로깅

### 9.1 시스템 모니터링

#### PM2 모니터링
```bash
# 실시간 모니터링
pm2 monit

# 상태 확인
pm2 status

# 시스템 정보
pm2 info pilates-server
```

#### 로그 파일 위치
- **PM2 로그**: `~/.pm2/logs/`
- **애플리케이션 로그**: `server/logs/`
- **시스템 로그**: OS별 시스템 로그

### 9.2 로그 관리

#### 로그 로테이션 설정
```bash
# PM2 로그 로테이션 모듈 설치
pm2 install pm2-logrotate

# 설정 (로그 파일 크기 10MB, 30개 파일 유지)
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 30
```

#### 사용자 정의 로그
```javascript
// server/utils/logger.js
const winston = require('winston');
require('winston-daily-rotate-file');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.DailyRotateFile({
      filename: 'logs/application-%DATE%.log',
      datePattern: 'YYYY-MM-DD',
      maxSize: '20m',
      maxFiles: '30d'
    })
  ]
});

module.exports = logger;
```

---

## 10. 보안 설정

### 10.1 방화벽 설정

#### Windows Defender 방화벽
1. **제어판** > **시스템 및 보안** > **Windows Defender 방화벽**
2. **고급 설정** 클릭
3. **인바운드 규칙** > **새 규칙**:
   - 규칙 유형: 포트
   - 프로토콜: TCP
   - 특정 로컬 포트: 3000
   - 작업: 연결 허용
   - 프로필: 개인, 도메인 (공용 제외)
   - 이름: Pilates Server

#### Ubuntu UFW
```bash
# UFW 활성화
sudo ufw enable

# SSH 허용 (원격 접속용)
sudo ufw allow ssh

# 필요한 포트 허용
sudo ufw allow 3000/tcp
sudo ufw allow 8080/tcp

# 특정 IP 범위만 허용 (선택)
sudo ufw allow from 192.168.1.0/24 to any port 3000
```

### 10.2 HTTPS 설정 (권장)

#### Let's Encrypt SSL 인증서 (공인 도메인 필요)
```bash
# Certbot 설치
sudo apt install certbot

# 인증서 발급 (도메인이 있는 경우)
sudo certbot certonly --standalone -d your-domain.com
```

#### 자체 서명 인증서 생성
```bash
# 개인 키 생성
openssl genrsa -out server-key.pem 2048

# 인증서 요청 생성
openssl req -new -key server-key.pem -out server-csr.pem

# 자체 서명 인증서 생성
openssl x509 -req -in server-csr.pem -signkey server-key.pem -out server-cert.pem -days 365
```

#### Express에서 HTTPS 적용
```javascript
// server/index.js에 추가
const https = require('https');
const fs = require('fs');

if (process.env.NODE_ENV === 'production') {
  const options = {
    key: fs.readFileSync('server-key.pem'),
    cert: fs.readFileSync('server-cert.pem')
  };

  https.createServer(options, app).listen(3443, () => {
    console.log('HTTPS Server running on port 3443');
  });
}
```

### 10.3 접근 제어

#### IP 기반 접근 제어
```javascript
// server/middleware/ipFilter.js
const allowedIPs = [
  '192.168.1.0/24',  // 로컬 네트워크
  '127.0.0.1',       // 로컬호스트
];

function ipFilter(req, res, next) {
  const clientIP = req.ip || req.connection.remoteAddress;
  
  // IP 범위 검증 로직
  if (isAllowedIP(clientIP)) {
    next();
  } else {
    res.status(403).json({ error: 'Access denied' });
  }
}
```

---

## 11. 업데이트 절차

### 11.1 시스템 업데이트 단계

#### 1단계: 백업
```bash
# 전체 시스템 백업
./backup.sh

# 데이터베이스 별도 백업
cp pilates_center.db pilates_center_pre_update.db
```

#### 2단계: 업데이트 파일 적용
```bash
# Git을 사용하는 경우
git pull origin main

# 의존성 업데이트
cd server && npm install
cd ../client && flutter pub get

# 클라이언트 리빌드
flutter build web --release
```

#### 3단계: 데이터베이스 마이그레이션 (필요시)
```bash
# 마이그레이션 스크립트 실행
node scripts/migrate.js
```

#### 4단계: 서비스 재시작
```bash
pm2 restart pilates-server
```

#### 5단계: 검증
```bash
# 헬스 체크
curl http://localhost:3000/api/health

# 기능 테스트
npm test
```

### 11.2 롤백 절차

#### 문제 발생 시 이전 버전 복원
```bash
# 서비스 중지
pm2 stop pilates-server

# 데이터베이스 롤백
mv pilates_center.db pilates_center_failed.db
mv pilates_center_pre_update.db pilates_center.db

# 코드 롤백 (Git)
git reset --hard [previous_commit_hash]

# 서비스 재시작
pm2 start pilates-server
```

---

## 12. 문제 해결

### 12.1 일반적인 문제들

#### 서버가 시작되지 않음
```bash
# 포트 사용 중인지 확인
netstat -tulpn | grep 3000

# 프로세스 종료
pkill -f node

# 로그 확인
pm2 logs pilates-server --lines 50
```

#### 데이터베이스 연결 오류
```bash
# 파일 권한 확인
ls -la pilates_center.db

# 권한 수정
chmod 664 pilates_center.db

# 디스크 공간 확인
df -h
```

#### 네트워크 접속 불가
```bash
# 방화벽 상태 확인
sudo ufw status

# 포트 열려있는지 확인
telnet 192.168.1.100 3000

# 네트워크 설정 확인
ip addr show
```

### 12.2 성능 문제 해결

#### 응답 속도가 느림
1. **데이터베이스 최적화**:
   - 인덱스 추가
   - 쿼리 최적화
   - 데이터베이스 정리

2. **메모리 사용량 확인**:
   ```bash
   pm2 monit
   htop
   ```

3. **네트워크 대역폭 확인**:
   ```bash
   iftop
   iperf3 -s  # 서버에서
   iperf3 -c 192.168.1.100  # 클라이언트에서
   ```

### 12.3 보안 문제 대응

#### 무차별 대입 공격 방어
```javascript
// Rate limiting 구현
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15분
  max: 5, // 최대 5회 시도
  message: '너무 많은 로그인 시도. 15분 후 다시 시도하세요.'
});

app.use('/api/auth/login', loginLimiter);
```

---

## 13. 연락처 및 지원

### 13.1 기술 지원
- **개발팀**: 시스템 관련 기술 문의
- **운영팀**: 일상적인 운영 문의
- **보안팀**: 보안 관련 문의

### 13.2 긴급 상황 대응
- **서비스 중단**: 즉시 백업으로 복원
- **보안 침해**: 즉시 서비스 중단 후 점검
- **데이터 손실**: 최근 백업으로 복원

### 13.3 정기 점검
- **일간**: 서비스 상태 확인
- **주간**: 로그 분석 및 성능 점검
- **월간**: 보안 업데이트 및 백업 검증
- **분기**: 전체 시스템 점검 및 업데이트

---

*본 배포 가이드는 필라테스 센터 관리 시스템을 안정적으로 운영하기 위한 모든 절차와 방법을 제시합니다. 단계별로 따라 하시면 성공적인 시스템 운영이 가능합니다.*