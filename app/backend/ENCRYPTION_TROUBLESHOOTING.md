# 암호화 문제 해결 가이드

## 문제: 학생 등록 시 암호화가 안 됨

### 원인 확인

1. **환경변수 확인**
   ```bash
   # .env 파일에 키가 있는지 확인
   echo $AES_KEY_B64
   echo $HMAC_KEY_B64
   ```

2. **DB 스키마 확인**
   ```sql
   -- 해시 필드가 있는지 확인
   SELECT column_name, data_type 
   FROM information_schema.columns 
   WHERE table_name = 'students' 
   AND column_name LIKE '%_hash';
   ```

3. **암호화 테스트**
   ```bash
   python -m app.backend.test.test_encryption
   ```

### 해결 방법

#### 1. 마이그레이션 실행 (해시 필드 추가)

```bash
# 마이그레이션 생성
alembic revision --autogenerate -m "add_encryption_hash_fields"

# 마이그레이션 실행
alembic upgrade head
```

#### 2. 서버 재시작

모델 변경사항을 반영하기 위해 서버를 재시작하세요.

#### 3. 테스트

```bash
# 암호화 테스트 실행
python -m app.backend.test.test_encryption
```

### 예상 결과

- ✅ DB에 저장된 `name`, `phone` 필드는 JSON 형태의 암호화된 envelope
- ✅ `name_hash`, `phone_hash` 필드에 해시값 저장
- ✅ ORM으로 조회 시 자동 복호화되어 평문 반환

### 여전히 안 되면

1. **로그 확인**: `Failed to decrypt value` 경고가 있는지 확인
2. **직접 확인**: DB에서 실제 저장된 값을 확인
   ```sql
   SELECT name, phone FROM students LIMIT 1;
   ```
   - 암호화되어 있으면: `{"v":"v1","alg":"AES-256-GCM",...}` 형태
   - 평문이면: 그냥 문자열

3. **코드 확인**: `app/backend/db/models/student.py`에서 `setup_hash_fields(Student)`가 호출되는지 확인

