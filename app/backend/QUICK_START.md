# 🚀 백엔드 서버 빠른 시작 가이드

## 문제: PostgreSQL 연결/인증 오류

### 에러 메시지 1: `Connect call failed ('127.0.0.1', 5432)`
PostgreSQL 데이터베이스에 연결할 수 없을 때 발생합니다.

### 에러 메시지 2: `password authentication failed for user "user"`
PostgreSQL 인증 실패 - `.env` 파일의 `DATABASE_URL`에 설정된 사용자명/비밀번호가 올바르지 않습니다.

## 해결 방법

### 1️⃣ PostgreSQL 실행 확인

#### Windows
```bash
# PostgreSQL 서비스 상태 확인
sc query postgresql-x64-15

# 서비스가 실행 중이 아니면 시작
net start postgresql-x64-15
```

#### Docker 사용 (권장)
```bash
# PostgreSQL 컨테이너 실행
docker run -d \
  --name tutor-ai-postgres \
  -e POSTGRES_USER=tutor_ai \
  -e POSTGRES_PASSWORD=tutor_ai_pw \
  -e POSTGRES_DB=tutor_ai \
  -p 5432:5432 \
  postgres:15

# 컨테이너 상태 확인
docker ps
docker logs tutor-ai-postgres
```

### 2️⃣ 백엔드 서버 실행 확인

```bash
# app/backend 디렉토리로 이동
cd app/backend

# 가상환경 활성화
source .venv/Scripts/activate  # Windows PowerShell
# 또는
.venv\Scripts\activate  # Windows CMD

# 서버 실행
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 3️⃣ 환경 변수 설정 확인

**`.env` 파일이 없는 경우:**
1. `app/backend/.env.example` 파일을 복사하여 `.env` 파일 생성:
   ```bash
   cd app/backend
   copy .env.example .env  # Windows CMD
   # 또는
   cp .env.example .env    # Git Bash
   ```

2. `.env` 파일을 열어서 `DATABASE_URL`을 확인하고 수정:

```env
# ⚠️ 중요: 사용자명, 비밀번호, 데이터베이스명이 PostgreSQL과 일치해야 합니다!
DATABASE_URL=postgresql+asyncpg://tutor_ai:tutor_ai_pw@localhost:5432/tutor_ai
AES_KEY_B64=your_aes_key_here
HMAC_KEY_B64=your_hmac_key_here
```

**⚠️ 인증 오류가 발생하는 경우:**
- `.env` 파일의 `DATABASE_URL`에서 사용자명(`tutor_ai`), 비밀번호(`tutor_ai_pw`), 데이터베이스명(`tutor_ai`)이 실제 PostgreSQL과 일치하는지 확인하세요.
- Docker를 사용하는 경우, Docker 명령어의 환경 변수와 `.env` 파일의 설정이 일치해야 합니다.
- 로컬 PostgreSQL을 사용하는 경우, `psql`로 직접 연결 테스트:
  ```bash
  psql -U tutor_ai -d tutor_ai
  ```

### 4️⃣ 데이터베이스 마이그레이션 실행

```bash
# Alembic 마이그레이션 실행
alembic upgrade head
```

## 체크리스트

- [ ] PostgreSQL이 실행 중인가?
  - Docker: `docker ps | grep tutor-ai-postgres`
  - 로컬: `sc query postgresql-x64-15` (Windows)
- [ ] 백엔드 서버가 실행 중인가? (http://localhost:8000)
  - 브라우저에서 http://localhost:8000/docs 접속 테스트
- [ ] `.env` 파일이 존재하는가?
  - `app/backend/.env` 파일 확인
  - 없으면 `.env.example`을 복사하여 생성
- [ ] `DATABASE_URL`이 올바른가?
  - 사용자명, 비밀번호, 데이터베이스명이 PostgreSQL과 일치하는지 확인
  - `psql -U tutor_ai -d tutor_ai`로 직접 연결 테스트
- [ ] 데이터베이스 마이그레이션이 완료되었는가?
  - `alembic upgrade head` 실행
  - `alembic current`로 현재 버전 확인

## 테스트

브라우저에서 다음 URL로 접속하여 서버가 실행 중인지 확인:
- http://localhost:8000/docs (Swagger UI)
- http://localhost:8000/healthz (헬스 체크)

## 문제 해결

### PostgreSQL이 설치되어 있지 않은 경우

1. **Docker 사용 (권장)**: 위의 Docker 명령어 실행
2. **로컬 설치**: https://www.postgresql.org/download/ 에서 다운로드

### 백엔드 서버가 실행되지 않는 경우

1. 가상환경이 활성화되어 있는지 확인
2. 의존성이 설치되어 있는지 확인: `pip install -r requirements.txt`
3. 포트 8000이 사용 중인지 확인: `netstat -ano | findstr :8000`

### 데이터베이스 연결 오류가 계속되는 경우

1. PostgreSQL이 실행 중인지 확인
2. `DATABASE_URL`의 사용자명, 비밀번호, 데이터베이스 이름이 올바른지 확인
3. 방화벽이 포트 5432를 차단하지 않는지 확인

### PostgreSQL 인증 오류 (`password authentication failed`)

**원인**: `.env` 파일의 `DATABASE_URL`에 설정된 사용자명/비밀번호가 PostgreSQL과 일치하지 않습니다.

**해결 방법**:

#### Docker를 사용하는 경우:
1. Docker 컨테이너를 삭제하고 재생성 (환경 변수 확인):
   ```bash
   docker stop tutor-ai-postgres
   docker rm tutor-ai-postgres
   docker run -d \
     --name tutor-ai-postgres \
     -e POSTGRES_USER=tutor_ai \
     -e POSTGRES_PASSWORD=tutor_ai_pw \
     -e POSTGRES_DB=tutor_ai \
     -p 5432:5432 \
     postgres:15
   ```

2. `.env` 파일의 `DATABASE_URL` 확인:
   ```env
   DATABASE_URL=postgresql+asyncpg://tutor_ai:tutor_ai_pw@localhost:5432/tutor_ai
   ```

#### 로컬 PostgreSQL을 사용하는 경우:
1. PostgreSQL에 올바른 사용자와 데이터베이스가 있는지 확인:
   ```sql
   -- psql로 접속 (postgres 슈퍼유저로)
   psql -U postgres
   
   -- 사용자 확인
   \du
   
   -- 사용자가 없으면 생성
   CREATE ROLE tutor_ai WITH LOGIN PASSWORD 'tutor_ai_pw';
   ALTER ROLE tutor_ai CREATEDB;
   
   -- 데이터베이스 확인
   \l
   
   -- 데이터베이스가 없으면 생성
   CREATE DATABASE tutor_ai OWNER tutor_ai;
   GRANT ALL PRIVILEGES ON DATABASE tutor_ai TO tutor_ai;
   ```

2. `.env` 파일의 `DATABASE_URL`을 실제 PostgreSQL 설정에 맞게 수정

### 백엔드 서버 연결 오류 (`Failed to fetch`)

**원인**: 백엔드 서버가 실행되지 않았거나 연결할 수 없습니다.

**해결 방법**:
1. 백엔드 서버가 실행 중인지 확인: http://localhost:8000/docs
2. 포트 8000이 사용 중인지 확인: `netstat -ano | findstr :8000`
3. 백엔드 서버 재시작:
   ```bash
   cd app/backend
   source .venv/Scripts/activate
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

