# 쌤대신 (Tutor AI) - 앱 스토리보드

## 📱 앱 개요
과외 관리 앱으로, 학생 관리, 스케줄 관리, 청구 관리 등의 기능을 제공합니다.

---

## 🔄 앱 흐름도

```
[Splash Screen]
    ↓ (1.4초 후 자동 이동)
[Main Navigation Screen]
    ├─ [Home Screen] (홈 탭)
    ├─ [Schedule Screen] (스케줄 탭)
    ├─ [Students Screen] (학생 탭)
    ├─ [Billing Screen] (청구 탭)
    └─ [Settings Screen] (설정 탭)
```

---

## 📄 화면별 상세 스토리보드

### 1. Splash Screen (스플래시 화면)
**경로**: `/splash` (초기 화면)

**기능**:
- 앱 로딩 화면
- Lottie 애니메이션 (시계) 표시
- 1.4초 후 자동으로 Main Navigation Screen으로 이동

**UI 구성**:
- 중앙에 Lottie 애니메이션 또는 폴백 아이콘
- 하단에 로딩 인디케이터

**상태**:
- ✅ 구현 완료

---

### 2. Main Navigation Screen (메인 네비게이션)
**경로**: `/main` 또는 `/`

**기능**:
- 하단 네비게이션 바로 5개 탭 전환
- IndexedStack으로 화면 상태 유지

**하단 네비게이션 탭**:
1. **홈** (HomeScreen) - `Icons.home`
2. **스케줄** (ScheduleScreen) - `Icons.calendar_today`
3. **학생** (StudentsScreen) - `Icons.school`
4. **청구** (BillingScreen) - `Icons.receipt_long`
5. **설정** (SettingsScreen) - `Icons.menu`

**상태**:
- ✅ 구현 완료

---

### 3. Home Screen (홈 화면)
**탭**: 홈 (첫 번째 탭)

**주요 기능**:
1. **상단 바**
   - 제목: "과외 진행 현황"
   - 알림 버튼

2. **돌봄 대시보드 카드**
   - 오늘의 수업과 청구 현황 요약
   - "포인트 받으러 가기" 버튼

3. **오늘의 스케줄 섹션**
   - 오늘 수업 목록 (총 개수 표시)
   - 각 수업 카드:
     - 시간 (시작-종료)
     - 학생 이름
     - 과목
     - 완료/진행중/예정 상태
     - 완료 체크박스 (토글 가능)
     - "오늘 수업 메모 작성하기" 버튼 (미완료 수업만)

4. **빠른 실행 섹션**
   - 수업 등록 카드
   - AI 어시스턴트 카드

5. **오늘의 현황 섹션**
   - 통계 패널:
     - 오늘 수업 개수
     - 완료 개수
     - 완료율 (%)
     - 미납 개수

6. **Floating Action Button**
   - "AI 어시스턴트" 버튼

**데이터 모델**:
- `ScheduleItem`: id, time, endTime, student, subject, status

**상태**:
- ✅ 구현 완료 (기본 기능)
- ⚠️ TODO: AI 어시스턴트 기능 연결
- ⚠️ TODO: 포인트 페이지 연결

---

### 4. Schedule Screen (스케줄 화면)
**탭**: 스케줄 (두 번째 탭)

**주요 기능**:
- 스케줄 관리 화면 (현재 기본 구조만 구현)

**상태**:
- ⚠️ 기본 구조만 구현됨 (추가 개발 필요)

---

### 5. Students Screen (학생 화면)
**탭**: 학생 (세 번째 탭)

**주요 기능**:
1. **AppBar**
   - 제목: "학생 관리"
   - 부제목: "총 N명의 학생"
   - "학생 추가" 버튼

2. **통계 카드**
   - 전체 학생 수
   - 오늘 수업 학생 수
   - 평균 출석률
   - 100% 출석 학생 수

3. **탭 필터**
   - 전체
   - 오늘 수업
   - 출석 주의 (출석률 < 90%)

4. **검색 바**
   - 학생 이름으로 검색

5. **학생 리스트**
   - 각 학생 카드:
     - 색상 구분선 (상단)
     - 아바타 (이름 첫 글자)
     - 학생 이름 (100% 출석 시 트로피 아이콘)
     - 학년 정보
     - 출석률 (프로그레스 바)
     - 다음 수업 시간
     - 과목 태그
     - 총 수업 횟수
   - 카드 클릭 시 상세 모달 표시

6. **학생 상세 모달** (Bottom Sheet)
   - 헤더:
     - 학생 색상 배경
     - 프로필 아바타
     - 이름, 학년
     - 총 수업 수, 출석률 통계
   - 바디:
     - 전화번호
     - 수강 과목 목록
     - "학생 정보 수정" 버튼

**데이터 모델**:
- `Student`: name, grade, subjects, phone, sessions, completedSessions, color, nextClass, attendanceRate

**상태**:
- ✅ 구현 완료 (기본 기능)
- ⚠️ TODO: 학생 추가 페이지
- ⚠️ TODO: 학생 정보 수정 기능

---

### 6. Billing Screen (청구 화면)
**탭**: 청구 (네 번째 탭)

**주요 기능**:
- 청구 관리 화면 (현재 기본 구조만 구현)

**상태**:
- ⚠️ 기본 구조만 구현됨 (추가 개발 필요)

---

### 7. Settings Screen (설정 화면)
**탭**: 설정 (다섯 번째 탭)

**주요 기능**:
- 설정 화면 (현재 기본 구조만 구현)

**상태**:
- ⚠️ 기본 구조만 구현됨 (추가 개발 필요)

---

## 🎨 디자인 시스템

### 테마
- Material Design 3 기반
- `AppTheme.light()` 사용
- 커스텀 색상 스킴

### 주요 색상
- Primary: 파란색 계열
- Success: 초록색 (#10B981)
- Warning: 주황색 (#F97316)
- Purple: 보라색 (#9333EA)

### 타이포그래피
- `AppTypography` 사용
- Google Fonts 적용

---

## 📦 데이터 모델

### Student
```dart
{
  name: String,
  grade: String,
  subjects: List<String>,
  phone: String,
  sessions: int,
  completedSessions: int,
  color: Color,
  nextClass: String,
  attendanceRate: int (0-100)
}
```

### ScheduleItem
```dart
{
  id: String,
  time: String,
  endTime: String,
  student: String,
  subject: String,
  status: ScheduleStatus (completed, current, upcoming)
}
```

---

## 🔗 라우팅

### 라우트 정의 (`AppRoutes`)
- `/splash` → SplashScreen
- `/main` 또는 `/` → MainNavigationScreen
- `/schedule` → ScheduleScreen
- `/students` → StudentsScreen
- `/billing` → BillingScreen
- `/settings` → SettingsScreen

### 네비게이션
- MaterialPageRoute 사용
- 하단 네비게이션은 IndexedStack으로 상태 유지

---

## ✅ 구현 상태

### 완료된 기능
- ✅ 스플래시 화면
- ✅ 메인 네비게이션 구조
- ✅ 홈 화면 (기본 기능)
- ✅ 학생 관리 화면 (기본 기능)

### 개발 필요
- ⚠️ 스케줄 화면 상세 구현
- ⚠️ 청구 화면 상세 구현
- ⚠️ 설정 화면 상세 구현
- ⚠️ AI 어시스턴트 기능
- ⚠️ 학생 추가/수정 기능
- ⚠️ 수업 등록 기능
- ⚠️ 포인트 시스템

---

## 📝 참고사항

- 모든 화면은 Flutter Material Design 3 기반
- 반응형 디자인 고려
- 다크 모드는 현재 미지원 (추후 추가 가능)
- 백엔드 API 연동 필요 (현재는 데모 데이터 사용)

