# 쌤대신 (Tutor AI) - Flutter 앱 연동 가이드

## 📱 프로젝트 개요

**쌤대신**은 과외 선생님을 위한 종합 관리 앱입니다. 학생 관리, 스케줄 관리, 청구 관리 등의 기능을 제공하며, Flutter로 개발된 크로스 플랫폼 모바일 앱입니다.

### 주요 기능
- 👥 **학생 관리**: 학생 등록, 조회, 수정, 삭제
- 📅 **스케줄 관리**: 일정 등록, 충돌 확인, 필터링
- 💰 **청구 관리**: 청구 내역 관리, 미납 관리
- 📊 **대시보드**: 오늘의 수업 현황, 통계
- ⚙️ **설정**: 앱 설정, 데이터 관리

---

## 📋 사전 요구사항

### 필수 소프트웨어
1. **Flutter SDK** (3.9.2 이상)
   - 설치: https://docs.flutter.dev/get-started/install
   - 확인: `flutter --version`

2. **Dart SDK** (3.9.2 이상)
   - Flutter와 함께 설치됨

3. **백엔드 서버** (FastAPI)
   - Python 3.12 이상
   - FastAPI 서버가 `http://localhost:8000`에서 실행 중이어야 함

4. **개발 도구** (선택)
   - Android Studio / VS Code
   - Xcode (iOS 개발 시, macOS만)
   - Git

### 시스템 요구사항
- **Windows**: Windows 10 이상
- **macOS**: macOS 10.14 이상 (iOS 개발 시)
- **Linux**: Ubuntu 18.04 이상

---

## 🚀 설치 및 설정

### 1. 프로젝트 클론 (이미 있는 경우 생략)
```bash
cd app/frontend
```

### 2. 의존성 설치
```bash
flutter pub get
```

### 3. Flutter 환경 확인
```bash
flutter doctor
```

**중요**: 다음 항목들이 정상적으로 설정되어 있어야 합니다:
- ✅ Flutter (Channel stable)
- ✅ Android toolchain
- ✅ Xcode (iOS 개발 시)
- ✅ Git
- ✅ Chrome (웹 개발 시)

---

## ⚙️ 백엔드 연동 설정

### 1. 백엔드 서버 실행

백엔드 서버가 실행되어 있어야 합니다. 프로젝트 루트에서:

```bash
# 백엔드 디렉토리로 이동
cd app/backend

# 가상환경 활성화 (선택)
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 서버 실행
uvicorn app.backend.main:app --reload --port 8000
```

서버가 정상적으로 실행되면:
- API 문서: http://localhost:8000/docs
- 헬스체크: http://localhost:8000/healthz

### 2. API 서비스 설정

API 서비스의 기본 URL은 `lib/services/api_service.dart`에서 설정됩니다:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:8000';
  // ...
}
```

**⚠️ 중요**: Android 에뮬레이터에서 테스트할 경우, `localhost` 대신 `10.0.2.2`를 사용해야 합니다.

플랫폼별 자동 설정을 원하면 `lib/services/api_service.dart`를 다음과 같이 수정:

```dart
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';  // Android 에뮬레이터
    } else {
      return 'http://localhost:8000';  // iOS 시뮬레이터, 실제 기기
    }
  }
  // ...
}
```

**실제 기기 테스트 시**: 위의 `baseUrl` getter를 사용하거나, 직접 IP 주소로 변경:
```dart
static const String baseUrl = 'http://192.168.0.100:8000';  // 실제 IP
```

#### 개발 환경별 설정

**로컬 개발 (에뮬레이터/시뮬레이터)**
- **Android 에뮬레이터**: `http://10.0.2.2:8000` 
  - Android 에뮬레이터는 `localhost`를 `10.0.2.2`로 매핑합니다
  - 현재 설정: `http://localhost:8000` → Android에서는 작동하지 않음
  - 해결: `lib/services/api_service.dart`에서 플랫폼별 분기 필요
- **iOS 시뮬레이터**: `http://localhost:8000` ✅
- **웹 브라우저**: `http://localhost:8000` ✅
- **실제 기기**: `http://[컴퓨터IP]:8000` (예: `http://192.168.0.100:8000`)

**프로덕션 환경**
- 실제 서버 URL로 변경 필요 (예: `https://api.yourdomain.com`)

#### 실제 기기에서 테스트하는 방법

1. **컴퓨터와 기기가 같은 Wi-Fi에 연결되어 있어야 합니다**

2. **컴퓨터의 IP 주소 확인**
   ```bash
   # Windows
   ipconfig
   # IPv4 주소 확인 (예: 192.168.0.100)
   
   # macOS/Linux
   ifconfig
   # 또는
   ip addr show
   ```

3. **API 서비스 URL 변경**
   `lib/services/api_service.dart` 파일 수정:
   ```dart
   class ApiService {
     // 실제 기기 테스트용
     static const String baseUrl = 'http://192.168.0.100:8000';  // 실제 IP 주소로 변경
   }
   ```

4. **백엔드 CORS 설정 확인**
   백엔드 `main.py`에서 해당 IP 허용:
   ```python
   origins = [
       "http://localhost:5173",
       "http://localhost:3000",
       "http://192.168.0.100:8000",  # 실제 기기 IP 추가
       "*",  # 개발 환경에서만 (프로덕션에서는 제거)
   ]
   ```

5. **방화벽 설정**
   - Windows: 방화벽에서 포트 8000 허용
   - macOS: 시스템 설정 > 보안 및 개인 정보 보호 > 방화벽

### 3. CORS 설정 확인

백엔드 `main.py`에서 CORS 설정을 확인하세요:

```python
origins = [
    "http://localhost:5173",   # Vite
    "http://localhost:3000",   # CRA/Next
]
```

Flutter 앱을 위한 CORS 설정이 필요하면 백엔드에 추가:
```python
origins = [
    "http://localhost:5173",
    "http://localhost:3000",
    "*",  # 개발 환경에서만 사용 (프로덕션에서는 제거)
]
```

---

## 🏃 실행 방법

### 개발 모드 실행

#### Android
```bash
flutter run
# 또는 특정 디바이스 지정
flutter devices  # 사용 가능한 디바이스 확인
flutter run -d <device-id>
```

#### iOS (macOS만)
```bash
flutter run -d ios
```

#### 웹
```bash
flutter run -d chrome
```

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

### 핫 리로드
앱 실행 중:
- `r`: 핫 리로드
- `R`: 핫 리스타트
- `q`: 종료

---

## 📦 빌드 방법

### Android APK 빌드
```bash
# Debug 빌드
flutter build apk --debug

# Release 빌드
flutter build apk --release

# App Bundle (Play Store용)
flutter build appbundle --release
```

### iOS 빌드 (macOS만)
```bash
# Debug 빌드
flutter build ios --debug

# Release 빌드
flutter build ios --release
```

### 웹 빌드
```bash
flutter build web --release
```

### Windows 빌드
```bash
flutter build windows --release
```

### macOS 빌드
```bash
flutter build macos --release
```

---

## 🔌 API 엔드포인트

### 학생 관리

#### 학생 목록 조회
```
GET /students
Query Parameters:
  - q: string (optional) - 이름 검색
  - page: int (default: 1)
  - pageSize: int (default: 20)
```

#### 학생 등록
```
POST /students
Content-Type: application/json

Body:
{
  "name": "김민수",
  "phone": "010-1234-5678",
  "parent_phone": "010-9876-5432",  // optional
  "school": "서울고등학교",  // optional
  "grade": "고등학교 2학년",  // optional
  "subject": "수학",  // optional
  "start_date": "2024-11-01",  // optional (YYYY-MM-DD)
  "lesson_day": "월요일",  // optional
  "lesson_time": "14:00",  // optional
  "hourly_rate": 50000,  // optional
  "notes": "메모",  // optional
  "is_active": true  // optional (default: true)
}
```

#### 학생 조회
```
GET /students/{student_id}
```

#### 학생 수정
```
PATCH /students/{student_id}
Content-Type: application/json

Body: (수정할 필드만 포함)
{
  "name": "김민수",
  "phone": "010-1234-5678",
  // ...
}
```

#### 학생 삭제
```
DELETE /students/{student_id}
```

### 스케줄 관리

#### 스케줄 목록 조회
```
GET /schedules
Query Parameters:
  - teacher_id: int (optional)
  - date_from: string (optional) - YYYY-MM-DD
  - date_to: string (optional) - YYYY-MM-DD
  - page: int (default: 1)
  - pageSize: int (default: 50)
```

#### 스케줄 등록
```
POST /schedules
Content-Type: application/json

Body:
{
  "teacher_id": 1,
  "lesson_date": "2024-11-07",  // YYYY-MM-DD
  "start_time": "14:00",  // HH:MM
  "end_time": "15:00",  // HH:MM
  "schedule_type": "lesson",  // "lesson" | "available" | "vacation" | "personal"
  "student_id": 1,  // optional
  "title": "수학 수업",  // optional
  "notes": "메모",  // optional
  "color": "#3788D8"  // optional (default: "#3788D8")
}
```

#### 스케줄 충돌 확인
```
POST /schedules/check-conflict
Query Parameters:
  - teacher_id: int
  - lesson_date: string (YYYY-MM-DD)
  - start_time: string (HH:MM)
  - end_time: string (HH:MM)

Response:
{
  "conflict": true/false,
  "count": 0
}
```

#### 스케줄 조회
```
GET /schedules/{schedule_id}
```

#### 스케줄 수정
```
PATCH /schedules/{schedule_id}
Content-Type: application/json

Body: (수정할 필드만 포함)
```

#### 스케줄 삭제
```
DELETE /schedules/{schedule_id}
```

---

## 📁 프로젝트 구조

```
app/frontend/
├── lib/
│   ├── main.dart                 # 앱 진입점
│   ├── models/                   # 데이터 모델
│   │   └── student.dart
│   ├── routes/                   # 라우팅
│   │   └── app_routes.dart
│   ├── screens/                   # 화면
│   │   ├── splash_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── home_screen.dart
│   │   ├── students_screen.dart
│   │   ├── schedule_screen.dart
│   │   ├── billing_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── add_student_screen.dart
│   │   └── add_schedule_screen.dart
│   ├── services/                  # API 서비스
│   │   └── api_service.dart
│   ├── theme/                     # 테마
│   │   ├── app_theme.dart
│   │   ├── app_typography.dart
│   │   └── scroll_physics.dart
│   └── widgets/                   # 재사용 위젯
│       ├── badge.dart
│       └── section_title.dart
├── assets/                        # 리소스
│   ├── animations/               # Lottie 애니메이션
│   ├── images/                   # 이미지
│   ├── icons/                    # 아이콘
│   └── fonts/                    # 폰트
├── test/                          # 테스트
├── android/                       # Android 설정
├── ios/                          # iOS 설정
├── web/                          # 웹 설정
├── windows/                      # Windows 설정
├── macos/                        # macOS 설정
├── linux/                        # Linux 설정
├── pubspec.yaml                  # 의존성 관리
└── README.md                     # 이 파일
```

---

## 🎨 주요 기능 설명

### 1. 홈 화면
- 오늘의 스케줄 목록
- 빠른 실행 버튼
- 오늘의 현황 통계
- AI 어시스턴트 버튼

### 2. 학생 관리
- 학생 목록 조회 및 검색
- 학생 등록/수정/삭제
- 출석률 통계
- 학생 상세 정보 모달

### 3. 스케줄 관리
- 일정 목록 (필터: 오늘/이번 주/이번 달/전체)
- 일정 등록/수정/삭제
- 시간 충돌 확인
- 일정 상태 표시 (완료/진행중/예정)

### 4. 청구 관리
- 청구 내역 조회
- 미납 관리
- 청구 통계
- 납부 처리

### 5. 설정
- 프로필 관리
- 알림 설정
- 앱 설정
- 데이터 관리

---

## 🔧 환경 변수 및 설정

### API Base URL 변경

`lib/services/api_service.dart` 파일에서 API URL을 변경할 수 있습니다:

```dart
class ApiService {
  // 개발 환경
  static const String baseUrl = 'http://localhost:8000';
  
  // 프로덕션 환경
  // static const String baseUrl = 'https://api.yourdomain.com';
}
```

### 실제 기기에서 테스트 시

Android 에뮬레이터가 아닌 실제 기기에서 테스트할 경우:

1. **컴퓨터 IP 주소 확인**
   ```bash
   # Windows
   ipconfig
   
   # macOS/Linux
   ifconfig
   ```

2. **API 서비스 URL 변경**
   ```dart
   static const String baseUrl = 'http://192.168.0.100:8000';  // 실제 IP 주소
   ```

3. **백엔드 CORS 설정 확인**
   - 백엔드 `main.py`에서 해당 IP 허용

---

## 🐛 트러블슈팅

### 1. API 연결 실패

**문제**: `Failed to create student: SocketException`

**해결 방법**:
1. 백엔드 서버가 실행 중인지 확인
   ```bash
   curl http://localhost:8000/healthz
   ```

2. API URL 확인
   - 에뮬레이터: `http://10.0.2.2:8000`
   - 시뮬레이터: `http://localhost:8000`
   - 실제 기기: `http://[컴퓨터IP]:8000`

3. CORS 설정 확인
   - 백엔드에서 Flutter 앱의 origin 허용

### 2. 패키지 설치 실패

**문제**: `pub get` 실패

**해결 방법**:
```bash
flutter clean
flutter pub get
```

### 3. 빌드 에러

**문제**: 빌드 중 에러 발생

**해결 방법**:
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### 4. Git PATH 오류

**문제**: `Error: Unable to find git in your PATH`

**해결 방법**:
1. Git 설치 확인: https://git-scm.com/downloads
2. PATH에 Git 추가:
   - Windows: `C:\Program Files\Git\cmd` 추가
   - macOS/Linux: 보통 자동으로 설정됨

### 5. Android 빌드 에러

**문제**: Gradle 에러

**해결 방법**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### 6. iOS 빌드 에러 (macOS만)

**문제**: CocoaPods 에러

**해결 방법**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

---

## 📚 의존성 패키지

### 주요 패키지
- `flutter`: Flutter SDK
- `lottie: ^3.1.0`: Lottie 애니메이션
- `google_fonts: ^6.1.0`: Google Fonts
- `http: ^1.1.0`: HTTP 클라이언트
- `intl: ^0.19.0`: 국제화 및 날짜 포맷팅

### 패키지 업데이트
```bash
flutter pub outdated  # 업데이트 가능한 패키지 확인
flutter pub upgrade  # 패키지 업데이트
```

---

## 🧪 테스트

### 단위 테스트 실행
```bash
flutter test
```

### 위젯 테스트 실행
```bash
flutter test test/widget_test.dart
```

---

## 📱 플랫폼별 빌드 가이드

### Android
1. `android/app/build.gradle`에서 패키지명 및 버전 확인
2. 키스토어 설정 (Release 빌드 시)
3. `flutter build apk --release`

### iOS (macOS만)
1. Xcode에서 서명 설정
2. `ios/Runner.xcworkspace` 열기
3. `flutter build ios --release`

### 웹
1. `flutter build web --release`
2. `build/web` 폴더를 웹 서버에 배포

---

## 🔐 보안 고려사항

### 개발 환경
- API URL을 하드코딩하지 않고 환경 변수 사용 권장
- 민감한 정보는 환경 변수나 설정 파일로 관리

### 프로덕션 환경
- HTTPS 사용 필수
- API 키 등 민감한 정보는 서버에서 관리
- CORS 설정을 엄격하게 관리

---

## 📞 지원 및 문의

### 유용한 링크
- [Flutter 공식 문서](https://docs.flutter.dev/)
- [Dart 공식 문서](https://dart.dev/)
- [FastAPI 공식 문서](https://fastapi.tiangolo.com/)

### 문제 해결
1. `flutter doctor` 실행하여 환경 확인
2. 로그 확인: `flutter run -v` (verbose 모드)
3. GitHub Issues 확인

---

## 📝 변경 이력

### v1.0.0 (2024-11-07)
- 초기 릴리스
- 학생 관리 기능
- 스케줄 관리 기능
- 청구 관리 기능
- 설정 화면
- 백엔드 API 연동

---

## 🎯 다음 단계

### 개발 예정 기능
- [ ] AI 어시스턴트 기능 구현
- [ ] 학생 상세 정보 수정 기능
- [ ] 스케줄 상세 정보 수정 기능
- [ ] 청구 상세 정보 수정 기능
- [ ] 데이터 백업/복원 기능
- [ ] 다크 모드 지원
- [ ] 푸시 알림 기능

---

## 📄 라이선스

이 프로젝트는 비공개 프로젝트입니다.
