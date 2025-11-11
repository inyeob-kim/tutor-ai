저는 소수의 학생들을 가르치는 과외 선생님인데, 제 과정을 간소화하는 데 도움이 되는 무료로 사용하기 쉬운 청구 및 일정 관리 앱을 찾고 있어요. 이상적으로는, 약속 일정을 관리하고, 세션을 쉽게 설정하고 수정할 수 있으며, 간단한 청구 옵션과 결제 추적이 가능한 청구서 발행 및 결제를 처리할 수 있는 무언가가 필요해요. 게다가, 학생 세부 정보와 메모를 관리할 수 있는 방법이 있으면 좋을 것 같아요. 몇 가지 옵션을 찾아봤는데, 여러분의 개인적인 경험과 추천을 듣고 싶어요. 작은 과외 사업을 관리하는 데 무엇이 가장 효과적이라고 생각하세요? 이제 막 시작하는 단계라 지금은 무료 방법을 찾아보고 싶어요.

backend디렉토리로 이동
```bash
cd app/backend/
```

가상환경 설정(처음에 한번만)
```bash
python -m venv .venv
```

가상환경 실행
```bash
source .venv/Scripts/activate
```

의존성 다운로드
```bash
pip install -r requirements.txt
```

fastapi 서버 실행
```bash
uvicorn main:app --reload
```

fastapi가 지원하는 api test (Swagger)
 http://127.0.0.1:8000/docs 로 접속


## 

# 🎓 Tutor AI Backend (FastAPI + PostgreSQL)

학생 관리 시스템의 백엔드 API 서버입니다.  
FastAPI + SQLAlchemy (async) + Alembic + PostgreSQL 로 구성되어 있으며,  
학생 등록, 조회, 수정, 삭제 기능을 제공합니다.

---

## 🚀 1. 환경 구성

### 1️⃣ Python 버전
```
Python 3.12+
```

### 2️⃣ 가상환경 생성 및 활성화
```bash
python -m venv venv
source venv/Scripts/activate   # Windows PowerShell이면: venv\Scripts\activate
```

### 3️⃣ 의존성 설치
```bash
pip install -r requirements.txt
```

### 4️⃣ 환경변수 (.env)
```
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/tutor_ai
AES_KEY_B64=...
HMAC_KEY_B64=...
```

---

## 🗃️ 2. 데이터베이스 초기화

### Alembic 마이그레이션
```bash
alembic upgrade head
```

테이블 구조는 다음과 같습니다.

| 컬럼명 | 타입 | 설명 |
|--------|------|------|
| user_id | `BIGINT` | PK |
| name | `VARCHAR(100)` | 이름 |
| email | `VARCHAR(120)` | 이메일 |
| grade | `VARCHAR(20)` | 학년 |
| student_phone | `VARCHAR(20)` | 학생 연락처 |
| guardian_phone | `VARCHAR(20)` | 보호자 연락처 |
| memo | `TEXT` | 메모 |
| created_at | `TIMESTAMP WITH TIME ZONE` | 생성일시 |
| updated_at | `TIMESTAMP WITH TIME ZONE` | 수정일시 |

---

## 🧩 3. 서버 실행

```bash
uvicorn app.backend.main:app --reload --log-level debug
```

서버 주소:
```
http://127.0.0.1:8000
```

Swagger 문서 자동 생성:
```
http://127.0.0.1:8000/docs
```

---

## 📡 4. API 사용법

### ✅ 학생 등록 (Create)
**POST** `/students`

#### Request Body
```json
{
  "name": "Alice",
  "email": "alice@example.com",
  "grade": "G6",
  "student_phone": "010-1234-5678",
  "guardian_phone": "010-8765-4321",
  "memo": "첫 상담 완료"
}
```

#### Response
```json
{
  "user_id": 1,
  "name": "Alice",
  "email": "alice@example.com",
  "grade": "G6",
  "student_phone": "010-1234-5678",
  "guardian_phone": "010-8765-4321",
  "memo": "첫 상담 완료",
  "created_at": "2025-11-11T09:00:00Z",
  "updated_at": "2025-11-11T09:00:00Z"
}
```

---

### 📋 학생 목록 조회 (Read List)
**GET** `/students`

#### Query Params
| 이름 | 설명 | 기본값 |
|------|------|--------|
| q | 이름 검색 (부분일치) | None |
| orderBy | 정렬 기준 (`created_at`, `name`, `grade`) | `created_at` |
| order | `asc` or `desc` | `desc` |
| page | 페이지 번호 (1부터) | 1 |
| pageSize | 페이지 크기 | 20 |

#### Response
```json
{
  "total": 2,
  "page": 1,
  "pageSize": 20,
  "items": [
    {
      "user_id": 1,
      "name": "Alice",
      "email": "alice@example.com",
      "grade": "G6",
      "student_phone": "010-1234-5678",
      "guardian_phone": "010-8765-4321",
      "memo": "첫 상담 완료",
      "created_at": "2025-11-11T09:00:00Z",
      "updated_at": "2025-11-11T09:00:00Z"
    }
  ]
}
```

---

### 🔍 학생 단건 조회 (Read One)
**GET** `/students/{user_id}`

#### Response
```json
{
  "user_id": 1,
  "name": "Alice",
  "email": "alice@example.com",
  "grade": "G6",
  "student_phone": "010-1234-5678",
  "guardian_phone": "010-8765-4321",
  "memo": "첫 상담 완료",
  "created_at": "2025-11-11T09:00:00Z",
  "updated_at": "2025-11-11T09:00:00Z"
}
```

---

### ✏️ 학생 수정 (Update)
**PATCH** `/students/{user_id}`

#### Request Body
```json
{
  "memo": "재상담 완료",
  "grade": "G7"
}
```

#### Response
```json
{
  "user_id": 1,
  "name": "Alice",
  "grade": "G7",
  "memo": "재상담 완료",
  "updated_at": "2025-11-11T10:00:00Z"
}
```

---

### 🗑️ 학생 삭제 (Delete)
**DELETE** `/students/{user_id}`

#### Response
`204 No Content`

---

## 🧠 5. 프론트엔드 연동 (예시)
React + Axios 사용 시:

```ts
import axios from "axios";

const API = axios.create({
  baseURL: "http://127.0.0.1:8000",
});

// 생성
await API.post("/students", { name: "Alice" });

// 조회
const { data } = await API.get("/students");
console.log(data.items);
```

---

## 🔧 6. 폴더 구조

```
app/
 └── backend/
     ├── main.py                # FastAPI 엔트리포인트
     ├── routers/
     │   └── student_router.py  # 학생 관련 API
     ├── schemas/
     │   └── student.py         # Pydantic 스키마
     ├── db/
     │   ├── models/
     │   │   └── student.py     # SQLAlchemy 모델
     │   ├── base_class.py
     │   ├── base.py
     │   └── database.py        # AsyncSession 설정
     └── alembic/
         └── versions/
```

---

## ✅ 7. 참고 명령어

| 기능 | 명령 |
|------|------|
| 새 마이그레이션 생성 | `alembic revision --autogenerate -m "msg"` |
| DB 반영 | `alembic upgrade head` |
| 로컬 실행 | `uvicorn app.backend.main:app --reload` |
| 문서 확인 | `http://127.0.0.1:8000/docs` |

---

## 📄 License
MIT License  
(c) 2025 HJ
 http://127.0.0.1:8000/docs 로 접속해서 api 테스트 가능!

----------------------------------------------------------------------
새로운 의존성 설치를 했다면, 아래 명령어로 텍스트파일 업데이트 부탁드립니다~
```bash
pip freeze > requirements.txt
```
----------------------------------------------------------------------

✅ MVP (출시 최소 기능)
1) 인증/계정

이메일/비번 로그인, 로그아웃

비밀번호 재설정(이메일 링크)

프로필: 이름, 연락처, 정산용 은행 계좌

2) 학생 관리

학생 등록: 이름, 학년/학제, 연락처(학생/보호자), 메모

학생 목록/검색/정렬

학생 프로필: 기본정보, 수업 히스토리, 결제기록 요약

3) 스케줄(수업 관리)

수업 생성: 학생, 과목, 날짜/시작-종료, 장소/온라인, 요금(시간당/회차당)

반복 수업(매주, 격주) 기본 옵션

오늘/주간/월간 뷰(리스트 → 달력은 placeholder여도 OK)

출결 체크(출석/결석/지각 메모)

4) 청구/정산

청구서 생성: 수업 기록 → 금액 합산

송부 방법(카카오/문자/이메일 링크) 템플릿

결제 상태: 미납/완료/부분/취소

월별 요약(총액/수납/미수)

5) 음성 명령(초기)

🎤 녹음 → 서버 STT(Whisper 등) → 텍스트

간단 NLU 룰: “내일 5시 민지 수학 90분” → 수업 초안 생성

실패 시 폴백: 텍스트 명령 입력창

6) 데이터/내보내기

CSV 내보내기: 학생 목록, 수업 기록, 청구 기록(월별)

로컬 캐시(최근 조회 오프라인 표시)

7) 알림/리마인드

수업 1시간 전 알림(로컬 알림)

미납 리마인드(수동 발송 버튼)

----------------------------------------------------------------------

✅ V1 확장 (빠른 차기 업데이트)
A. 수업/학습 관리 고도화

단일 수업에 커리큘럼 체크리스트/숙제/피드백 첨부

사진/파일 업로드(숙제 스캔, 시험지)

성적/지표 트래킹(전/후 비교 그래프)

B. 청구/결제 고도화

단가/패키지(10회 선결제, 월정액)

할인/쿠폰/장학 처리

전자영수증/PDF 청구서 생성(브랜딩 로고)

자동 리마인드 스케줄(N일/주기)

C. 일정 연동

Google/Apple/OS 캘린더 싱크(읽기/쓰기 선택)

ICS 파일 내보내기

D. 커뮤니케이션

보호자에게 수업 요약/피드백 자동 발송 템플릿(문자/메일/카톡)

미리 준비한 과제/프린트 공유 링크

E. 음성·AI 고도화

자연어 NLU(의도: 수업생성/변경/취소/청구/요약)

“오늘 요약” 자동 생성(오늘 수업/미수금/해야할 일)

수업 후 음성 메모 → 자동 요약 → 학생 프로필 메모 저장

----------------------------------------------------------------------

✅ V2+ (프로·팀 운영)

여러 튜터/조교 계정(역할/권한: Admin/Teacher/Viewer)

레슨 패키지 재고/소진 트래킹(몇 회 남음)

수익 분석(주/월/과목/학생별)

출결 자동화(위치/QR 체크인
