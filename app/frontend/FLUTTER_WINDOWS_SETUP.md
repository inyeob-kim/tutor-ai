# Flutter Windows 개발 환경 설정

## 문제: "Building with plugins requires symlink support"

Windows에서 Flutter 앱을 실행하려면 **Developer Mode**를 활성화해야 합니다.

## 해결 방법

### 1. Windows 설정 열기
- `Win + I` 키를 눌러 설정 앱 열기
- 또는 명령어 실행: `start ms-settings:developers`

### 2. Developer Mode 활성화
1. 설정 앱에서 **"개인 정보 보호 및 보안"** 또는 **"개발자용"** 섹션 찾기
2. **"개발자용"** 또는 **"Developer Mode"** 옵션 찾기
3. **"개발자 모드"** 또는 **"Developer Mode"** 토글을 **켜기**로 설정

### 3. 확인
- 시스템 재시작이 필요할 수 있습니다
- 재시작 후 다시 `flutter run -d windows` 실행

## 대안: Chrome에서 실행

Developer Mode를 활성화하지 않고 테스트하려면:

```bash
flutter run -d chrome
```

Chrome 브라우저에서 앱이 실행됩니다.

## 참고
- Developer Mode는 Windows 10/11에서 symlink(심볼릭 링크) 생성을 허용합니다
- Flutter 플러그인들이 정상적으로 작동하려면 symlink가 필요합니다
- Developer Mode는 개발 환경에서만 필요하며, 일반 사용자에게는 영향이 없습니다

