# Alembic 마이그레이션 가이드

## 📋 기본 절차

### 1. 현재 마이그레이션 상태 확인
```bash
cd app/backend
alembic current
```
현재 적용된 마이그레이션 버전을 확인합니다.

### 2. 마이그레이션 히스토리 확인
```bash
alembic history
```
모든 마이그레이션 파일의 히스토리를 확인합니다.

### 3. 마이그레이션 적용 (업그레이드)
```bash
# 최신 버전까지 모든 마이그레이션 적용
alembic upgrade head

# 특정 버전까지 업그레이드
alembic upgrade <revision_id>

# 한 단계씩 업그레이드
alembic upgrade +1
```

### 4. 마이그레이션 롤백 (다운그레이드)
```bash
# 한 단계 롤백
alembic downgrade -1

# 특정 버전으로 롤백
alembic downgrade <revision_id>

# 모든 마이그레이션 롤백
alembic downgrade base
```

### 5. 마이그레이션 SQL 미리보기
```bash
# 실제 실행하지 않고 SQL만 확인
alembic upgrade head --sql
```

## 🎯 현재 작업: attendance_status 추가

### 실행 명령어
```bash
# 1. 현재 상태 확인
alembic current

# 2. 마이그레이션 적용
alembic upgrade head

# 3. 적용 확인
alembic current
```

### 예상 결과
- `attendance_status` enum 타입 생성
- `schedules` 테이블에 `attendance_status` 컬럼 추가 (nullable)

## ⚠️ 주의사항

1. **데이터베이스 백업**: 프로덕션 환경에서는 반드시 백업 후 실행
2. **환경 변수 확인**: `DATABASE_URL`이 올바르게 설정되어 있는지 확인
3. **트랜잭션**: 마이그레이션은 자동으로 트랜잭션으로 실행됩니다

## 🔍 문제 해결

### 마이그레이션 충돌 시
```bash
# 마이그레이션 병합
alembic merge -m "merge branches" <rev1> <rev2>
```

### 마이그레이션 파일 수정 후
```bash
# 마이그레이션 재생성 (주의: 기존 데이터 손실 가능)
alembic revision --autogenerate -m "description"
```

## 📝 자주 사용하는 명령어

```bash
# 현재 버전 확인
alembic current

# 최신 버전으로 업그레이드
alembic upgrade head

# 한 단계 롤백
alembic downgrade -1

# 마이그레이션 히스토리 확인
alembic history --verbose

# SQL 미리보기
alembic upgrade head --sql
```

