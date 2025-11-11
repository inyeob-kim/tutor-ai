# 개인정보 암호화 가이드

## 개요

민감한 개인정보(이름, 전화번호, 이메일, 계좌번호 등)를 AES-256-GCM으로 암호화하여 저장합니다.

## 암호화된 필드

### Student (학생)
- `name` - 이름
- `phone` - 전화번호
- `parent_phone` - 부모 전화번호

### Teacher (선생님)
- `name` - 이름
- `phone` - 전화번호
- `email` - 이메일
- `bank_name` - 은행명
- `account_number` - 계좌번호

## 해시 필드

암호화된 필드는 매번 다른 암호문을 생성하므로 (nonce 사용), unique constraint나 검색을 위해 해시 필드를 별도로 저장합니다.

- `Student.name_hash`, `Student.phone_hash` - HMAC-SHA256 해시
- `Teacher.phone_hash`, `Teacher.email_hash` - HMAC-SHA256 해시

해시 필드는 자동으로 생성/업데이트됩니다.

## 환경변수 설정

`.env` 파일에 다음 키를 추가해야 합니다:

```bash
# 32바이트 키를 base64로 인코딩한 값
AES_KEY_B64=<32바이트 키를 base64 인코딩>
HMAC_KEY_B64=<32바이트 키를 base64 인코딩>
```

### 키 생성 방법

```python
import secrets
import base64

# 32바이트 랜덤 키 생성
aes_key = secrets.token_bytes(32)
hmac_key = secrets.token_bytes(32)

# Base64 인코딩
aes_key_b64 = base64.b64encode(aes_key).decode('utf-8')
hmac_key_b64 = base64.b64encode(hmac_key).decode('utf-8')

print(f"AES_KEY_B64={aes_key_b64}")
print(f"HMAC_KEY_B64={hmac_key_b64}")
```

## 마이그레이션

### 1. 데이터베이스 스키마 업데이트

기존 테이블에 해시 필드를 추가하고 컬럼 타입을 변경해야 합니다.

```bash
# Alembic 마이그레이션 생성
alembic revision --autogenerate -m "add_encryption_fields"

# 마이그레이션 실행
alembic upgrade head
```

### 2. 기존 데이터 암호화

기존 평문 데이터를 암호화하는 스크립트를 실행합니다:

```bash
# ⚠️ 실행 전 반드시 데이터베이스 백업!
python -m app.backend.utils.migration_encrypt
```

**주의사항**:
- 실행 전 반드시 데이터베이스 백업을 수행하세요
- 프로덕션 환경에서는 테스트 환경에서 먼저 검증하세요
- 마이그레이션 중에는 애플리케이션을 중지하세요

## 검색 기능 제한사항

암호화된 필드는 직접 검색이 불가능합니다:

- **정확 일치 검색**: 해시 필드를 사용하여 가능
- **부분 검색 (LIKE)**: 불가능 (모든 레코드를 복호화해야 함)

### 검색 개선 방안

1. **검색 인덱스 테이블**: 검색 가능한 필드만 별도 테이블에 저장
2. **검색 엔진 연동**: Elasticsearch 등 사용
3. **애플리케이션 레벨 필터링**: 모든 레코드를 가져와서 복호화 후 필터링 (소규모 데이터에만 적합)

## 사용 방법

### 일반적인 사용

암호화는 자동으로 처리됩니다. 모델을 사용할 때는 평문처럼 사용하면 됩니다:

```python
# 생성
student = Student(name="홍길동", phone="01012345678")
session.add(student)
await session.commit()

# 조회 (자동 복호화)
student = await session.get(Student, student_id)
print(student.name)  # "홍길동" (자동 복호화됨)

# 수정
student.name = "홍길순"
await session.commit()  # 자동 암호화됨
```

### 해시 필드로 검색

```python
from app.backend.core.crypto import hmac_sha256_hex

# 전화번호로 검색
phone_hash = hmac_sha256_hex("01012345678")
student = await session.execute(
    select(Student).where(Student.phone_hash == phone_hash)
).scalar_one_or_none()
```

## 보안 고려사항

1. **키 관리**: 
   - 키는 환경변수로 관리하고 절대 코드에 하드코딩하지 마세요
   - 키 로테이션 시 기존 데이터 재암호화 필요

2. **백업**:
   - 암호화 키도 안전하게 백업하세요
   - 키를 잃어버리면 데이터 복호화 불가능

3. **로그**:
   - 복호화된 개인정보가 로그에 출력되지 않도록 주의

4. **접근 제어**:
   - 개인정보 접근 권한을 최소화하세요

## 문제 해결

### "AES_KEY_B64 is missing" 오류

`.env` 파일에 키를 추가했는지 확인하세요.

### "Failed to decrypt value" 경고

기존 평문 데이터가 있을 수 있습니다. 마이그레이션 스크립트를 실행하세요.

### 검색이 작동하지 않음

해시 필드 기반 검색을 사용하거나, 검색 인덱스 테이블을 구현하세요.

