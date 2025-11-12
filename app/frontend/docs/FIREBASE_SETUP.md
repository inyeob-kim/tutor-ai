# Firebase Google Sign-In 설정 가이드

## Web Client ID 확인 방법

### 방법 1: Google Cloud Console에서 확인 (권장)

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 상단에서 프로젝트 선택: `ssamdaeshin-d0ba7`
3. 왼쪽 메뉴에서 **APIs & Services** > **Credentials** 클릭
4. **OAuth 2.0 Client IDs** 섹션에서 **Web client** 찾기
5. 클릭하면 **Client ID** 확인 가능
   - 형식: `XXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.apps.googleusercontent.com`

### 방법 2: Firebase Console에서 확인

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `ssamdaeshin-d0ba7`
3. 왼쪽 사이드바에서 **⚙️ 프로젝트 설정** 클릭
4. **일반** 탭에서 하단의 **앱** 섹션 확인
5. 웹 앱을 선택하면 **OAuth 클라이언트 ID** 확인 가능

### 방법 3: Authentication에서 확인

1. Firebase Console > **Authentication** > **Sign-in method**
2. **Google** 선택
3. **Web SDK configuration** 섹션에서 **Web client ID** 확인

## Google Sign-In 활성화 방법

만약 Google Sign-In이 활성화되어 있지 않다면:

1. Firebase Console > **Authentication** > **Sign-in method**
2. **Google** 선택
3. **사용 설정** 토글을 켜기
4. **프로젝트 지원 이메일** 선택 (또는 입력)
5. **저장** 클릭

## Web Client ID 설정 방법

확인한 Web Client ID를 다음 중 하나의 방법으로 설정하세요:

### 방법 1: `web/index.html`에 meta 태그 추가 (권장)

```html
<meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com" />
```

### 방법 2: 코드에서 직접 설정

`lib/screens/signup/google_signup_screen.dart` 파일의 31번째 줄:

```dart
clientId: kIsWeb ? 'YOUR_CLIENT_ID.apps.googleusercontent.com' : null,
```

## 문제 해결

### Web Client ID를 찾을 수 없는 경우

1. Google Cloud Console에서 OAuth 동의 화면 설정 확인
2. OAuth 2.0 Client ID가 생성되어 있는지 확인
3. 없으면 **+ CREATE CREDENTIALS** > **OAuth client ID** 클릭하여 생성
   - Application type: **Web application**
   - Authorized JavaScript origins: `http://localhost:8080` (개발용)
   - Authorized redirect URIs: `http://localhost:8080` (개발용)

### Google Sign-In이 작동하지 않는 경우

1. Firebase Console에서 Google Sign-In이 활성화되어 있는지 확인
2. Web Client ID가 올바르게 설정되었는지 확인
3. 브라우저 콘솔에서 에러 메시지 확인
4. OAuth 동의 화면이 설정되어 있는지 확인 (Google Cloud Console)

