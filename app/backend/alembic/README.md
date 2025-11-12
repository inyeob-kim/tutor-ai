# Alembic 로컬 데이터베이스 설정 가이드

이 문서는 새로운 개발 환경에서 PostgreSQL 데이터베이스를 준비하고 Alembic 마이그레이션을 적용하는 과정을 처음부터 끝까지 설명합니다.

---

## 1. 사전 준비물

- Python 3.12 이상 (백엔드는 `app/backend` 기준)
- PostgreSQL 15 이상 (로컬 설치 또는 Docker 컨테이너)
- Git Bash 혹은 PowerShell (Windows)
- `app/backend` 경로에서 사용할 가상환경

> **Tip**: Python 종속성은 이미 `requirements.txt`에 Alembic과 asyncpg가 포함되어 있으니, 가상환경만 준비하면 됩니다.

---

## 2. 가상환경 및 패키지 설치

```bash
cd app/backend
python -m venv .venv
source .venv/Scripts/activate  # PowerShell: .venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 3. PostgreSQL 준비하기

### 3.1 로컬에 직접 설치한 경우

1. PostgreSQL 서비스를 실행합니다.
2. `psql`에 접속해 전용 계정과 데이터베이스를 만듭니다.

```sql
-- 필요한 경우 postgres 슈퍼유저로 접속
CREATE ROLE tutor_ai WITH LOGIN PASSWORD 'tutor_ai_pw';
ALTER ROLE tutor_ai CREATEDB;

CREATE DATABASE tutor_ai OWNER tutor_ai;
GRANT ALL PRIVILEGES ON DATABASE tutor_ai TO tutor_ai;
```

> 원하는 사용자/비밀번호/DB 이름을 사용해도 되지만, `.env`의 접속 정보와 반드시 일치해야 합니다.

### 3.2 Docker로 실행하는 경우 (선택)

```bash
docker run -d \
  --name tutor-ai-postgres \
  -e POSTGRES_USER=tutor_ai \
  -e POSTGRES_PASSWORD=tutor_ai_pw \
  -e POSTGRES_DB=tutor_ai \
  -p 5432:5432 \
  postgres:15
```

컨테이너가 준비될 때까지 몇 초 기다렸다가 `docker logs tutor-ai-postgres`로 상태를 확인하세요.

---

## 4. 환경 변수 파일 생성

`app/backend` 디렉토리에 `.env` 파일을 만들고 아래 내용을 채웁니다.

```
DATABASE_URL=postgresql+asyncpg://tutor_ai:tutor_ai_pw@localhost:5432/tutor_ai

# 선택: 암호화 키 (없으면 일부 기능 비활성)
AES_KEY_B64=임의의_32바이트_key를_base64로
HMAC_KEY_B64=임의의_hmac_key를_base64로
```

- `DATABASE_URL`은 SQLAlchemy async URL 규격을 사용합니다.
- 암호화 키는 필요 시 `python -c "import os, base64; print(base64.b64encode(os.urandom(32)).decode())"`로 생성할 수 있습니다.

---

## 5. Alembic 마이그레이션 적용

1. `app/backend`에서 가상환경이 활성화된 상태인지 확인합니다.
2. 아래 명령으로 최신 스키마를 DB에 반영합니다.

```bash
alembic upgrade head
```

3. 결과 확인:
   - 성공 시 `INFO  [alembic.runtime.migration] Running upgrade ...` 로그가 출력됩니다.
   - DB에 연결이 안 되면 `sqlalchemy.exc.OperationalError`가 표시되니 접속 정보와 PostgreSQL 상태를 다시 확인하세요.

추가로 현재 적용된 버전을 확인하려면:

```bash
alembic current
```

---

## 6. 새 마이그레이션 작성 (개발자용)

1. 모델 변경 후 자동 생성 템플릿을 만들 때:

```bash
alembic revision --autogenerate -m "describe your change"
```

2. 생성된 `app/backend/alembic/versions/*.py` 파일을 검토 후 필요하면 수정합니다.
3. 변경 사항을 적용하려면 다시 `alembic upgrade head`를 실행하세요.
4. 직전 버전으로 되돌리려면:

```bash
alembic downgrade -1
```

> autogenerate가 모든 변경을 감지하지 않는 경우가 있으니, 생성된 스크립트를 꼭 검토하세요.

---

## 7. 자주 발생하는 문제 해결

- **`connection refused`**: PostgreSQL 서비스가 실행 중인지, 방화벽에서 5432 포트를 허용했는지 확인합니다.
- **`asyncpg` 관련 에러**: 가상환경에서 `pip install -r requirements.txt`를 다시 실행하세요.
- **마이그레이션 충돌**: 팀 작업 중이라면 새로운 리비전을 만들기 전에 `git pull`과 `alembic upgrade head`를 먼저 실행해 최신 상태로 맞추세요.
- **Windows 경로 문제**: Git Bash를 사용 중이라면 `alembic` 커맨드를 실행하기 전에 `python -m alembic`으로 호출하는 것도 방법입니다.

---

## 8. 마무리 점검

1. `alembic history`로 리비전 목록을 확인합니다.
2. `psql -U tutor_ai -d tutor_ai -c "\dt"`로 테이블이 생성되었는지 확인합니다.
3. FastAPI 서버(`uvicorn main:app --reload`)를 실행해 API에서 DB 연결이 정상인지 테스트합니다.

이제 로컬 개발 환경에서 DB 설정과 마이그레이션 준비가 완료되었습니다. 문제가 생기면 슬랙/이슈 트래커에 알려주세요!

