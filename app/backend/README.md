저는 소수의 학생들을 가르치는 과외 선생님인데, 제 과정을 간소화하는 데 도움이 되는 무료로 사용하기 쉬운 청구 및 일정 관리 앱을 찾고 있어요. 이상적으로는, 약속 일정을 관리하고, 세션을 쉽게 설정하고 수정할 수 있으며, 간단한 청구 옵션과 결제 추적이 가능한 청구서 발행 및 결제를 처리할 수 있는 무언가가 필요해요. 게다가, 학생 세부 정보와 메모를 관리할 수 있는 방법이 있으면 좋을 것 같아요. 몇 가지 옵션을 찾아봤는데, 여러분의 개인적인 경험과 추천을 듣고 싶어요. 작은 과외 사업을 관리하는 데 무엇이 가장 효과적이라고 생각하세요? 이제 막 시작하는 단계라 지금은 무료 방법을 찾아보고 싶어요.


```bash
cd app/backend/
```

가상환경 설정
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
