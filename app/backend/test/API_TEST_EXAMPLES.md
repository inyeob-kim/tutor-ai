# API 테스트 예제 (curl)

기본 URL: `http://localhost:8000` (서버 실행 시 포트 확인 필요)

## 1. Teacher (선생님)

### 1.1 선생님 등록
```bash
curl -X POST "http://localhost:8000/teachers" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "홍길동",
    "phone": "01012345678",
    "provider": "google",
    "oauth_id": "google_123456789",
    "email": "teacher@example.com",
    "bank_name": "국민은행",
    "account_number": "123-456-789012",
    "tax_type": "사업소득",
    "hourly_rate_min": 30000,
    "hourly_rate_max": 50000,
    "available_days": "월화수목금",
    "available_time": "평일 18~22시, 토 10~18시"
  }'
```

### 1.2 선생님 목록 조회
```bash
# 전체 목록
curl "http://localhost:8000/teachers?page=1&pageSize=20"

# 검색 (이름 또는 전화번호)
curl "http://localhost:8000/teachers?q=홍길동&page=1&pageSize=20"

# 정렬
curl "http://localhost:8000/teachers?orderBy=name&order=asc"
```

### 1.3 선생님 상세 조회
```bash
curl "http://localhost:8000/teachers/1"
```

### 1.4 선생님 수정
```bash
curl -X PATCH "http://localhost:8000/teachers/1" \
  -H "Content-Type: application/json" \
  -d '{
    "hourly_rate_min": 35000,
    "hourly_rate_max": 55000,
    "notes": "시급 인상"
  }'
```

### 1.5 선생님 삭제
```bash
curl -X DELETE "http://localhost:8000/teachers/1"
```

---

## 2. Student (학생)

### 2.1 학생 등록
```bash
curl -X POST "http://localhost:8000/students" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "김철수",
    "phone": "01098765432",
    "parent_phone": "01011112222",
    "school": "서울고등학교",
    "grade": "고1",
    "subject": "수학",
    "start_date": "2025-01-01",
    "lesson_day": "월수금",
    "lesson_time": "19:00~21:00",
    "hourly_rate": 40000,
    "notes": "수학 집중 관리 필요"
  }'
```

### 2.2 학생 목록 조회
```bash
# 전체 목록
curl "http://localhost:8000/students?page=1&pageSize=20"

# 검색
curl "http://localhost:8000/students?q=김철수&page=1&pageSize=20"

# 정렬
curl "http://localhost:8000/students?orderBy=grade&order=asc"
```

### 2.3 학생 상세 조회
```bash
curl "http://localhost:8000/students/1"
```

### 2.4 학생 수정
```bash
curl -X PATCH "http://localhost:8000/students/1" \
  -H "Content-Type: application/json" \
  -d '{
    "grade": "고2",
    "hourly_rate": 45000,
    "notes": "학년 올라감"
  }'
```

### 2.5 학생 삭제
```bash
curl -X DELETE "http://localhost:8000/students/1"
```

---

## 3. Schedule (스케줄)

### 3.1 스케줄 등록
```bash
curl -X POST "http://localhost:8000/schedules" \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": 1,
    "lesson_date": "2025-01-15",
    "start_time": "19:00:00",
    "end_time": "21:00:00",
    "student_id": 1,
    "schedule_type": "lesson",
    "title": "수학 수업",
    "color": "#3788D8"
  }'
```

### 3.2 스케줄 목록 조회
```bash
# 전체 목록
curl "http://localhost:8000/schedules?page=1&pageSize=50"

# 선생님별 조회
curl "http://localhost:8000/schedules?teacher_id=1&page=1&pageSize=50"

# 기간별 조회
curl "http://localhost:8000/schedules?date_from=2025-01-01&date_to=2025-01-31"
```

### 3.3 스케줄 상세 조회
```bash
curl "http://localhost:8000/schedules/1"
```

### 3.4 스케줄 수정
```bash
curl -X PATCH "http://localhost:8000/schedules/1" \
  -H "Content-Type: application/json" \
  -d '{
    "start_time": "19:30:00",
    "end_time": "21:30:00",
    "title": "수학 수업 (연장)"
  }'
```

### 3.5 스케줄 충돌 확인
```bash
curl -X POST "http://localhost:8000/schedules/check-conflict?teacher_id=1&lesson_date=2025-01-15&start_time=19:00:00&end_time=21:00:00"
```

### 3.6 스케줄 대량 생성 (주간 반복)
```bash
curl -X POST "http://localhost:8000/schedules/bulk-generate?teacher_id=1&weekday=0&start_time=19:00&end_time=21:00&date_from=2025-01-01&date_to=2025-03-31&schedule_type=lesson&title=수학%20정기수업"
```

### 3.7 스케줄 삭제
```bash
curl -X DELETE "http://localhost:8000/schedules/1"
```

---

## 4. Invoice (청구)

### 4.1 청구 등록 (청구하기 버튼 클릭)
```bash
curl -X POST "http://localhost:8000/invoices" \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": 1,
    "student_id": 1,
    "invoice_number": "INV-2025-001",
    "status": "draft",
    "total_amount": 320000,
    "tax_amount": 0,
    "final_amount": 320000,
    "billing_period_start": "2025-01-01T00:00:00",
    "billing_period_end": "2025-01-31T23:59:59",
    "items": [
      {
        "description": "수학 수업 4회차",
        "subject": "수학",
        "quantity": 4,
        "unit_price": 40000,
        "amount": 160000,
        "lesson_date": "2025-01-01, 2025-01-08, 2025-01-15, 2025-01-22"
      },
      {
        "description": "영어 수업 4회차",
        "subject": "영어",
        "quantity": 4,
        "unit_price": 40000,
        "amount": 160000,
        "lesson_date": "2025-01-03, 2025-01-10, 2025-01-17, 2025-01-24"
      }
    ]
  }'
```

### 4.2 청구 목록 조회
```bash
# 전체 목록
curl "http://localhost:8000/invoices?page=1&pageSize=20"

# 선생님별 조회
curl "http://localhost:8000/invoices?teacher_id=1&page=1&pageSize=20"

# 학생별 조회
curl "http://localhost:8000/invoices?student_id=1&page=1&pageSize=20"

# 상태별 조회
curl "http://localhost:8000/invoices?status=draft&page=1&pageSize=20"
```

### 4.3 청구 상세 조회
```bash
curl "http://localhost:8000/invoices/1"
```

### 4.4 카카오페이 링크 생성 및 발송 (자동 생성)
```bash
# 카카오페이 API를 호출하여 결제 링크 자동 생성
curl -X POST "http://localhost:8000/invoices/1/create-kakao-pay-link?approval_url=http://localhost:5173/payment/success&cancel_url=http://localhost:5173/payment/cancel&fail_url=http://localhost:5173/payment/fail"
```

**테스트 모드 (기본값)**:
- `KAKAO_PAY_TEST_MODE=true`일 때 실제 API 호출 없이 모의 응답 반환
- 환경변수 설정 없이도 테스트 가능

**실제 카카오페이 연동**:
1. `.env` 파일에 추가:
   ```
   KAKAO_PAY_ADMIN_KEY=your_admin_key_here
   KAKAO_PAY_TEST_MODE=false
   KAKAO_PAY_CID=your_cid_here
   ```
2. 카카오 개발자 센터에서 앱 등록 및 Admin Key 발급
3. 실제 결제 링크가 생성됨

### 4.5 카카오페이 링크 수동 저장 (기존 링크 사용)
```bash
curl -X POST "http://localhost:8000/invoices/1/send-link?kakao_pay_link=https://kakaopay.link/xxx"
```

### 4.6 카카오페이 결제 승인 (pg_token으로 결제 완료)
```bash
# 카카오페이 결제 완료 후 approval_url에서 받은 pg_token으로 승인
curl -X POST "http://localhost:8000/invoices/1/approve-payment?pg_token=pg_token_from_kakaopay"
```

### 4.7 결제 완료 처리 (수동, 청구완료로 상태 변경)
```bash
# 카카오페이 콜백 또는 앱에서 직접 호출 (pg_token 없이)
curl -X POST "http://localhost:8000/invoices/1/complete-payment?kakao_pay_tid=T1234567890"
```

**전체 플로우 테스트**:
```bash
# 1. 청구서 생성 (draft 상태)
INVOICE_ID=$(curl -X POST "http://localhost:8000/invoices" \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": 1,
    "student_id": 1,
    "invoice_number": "INV-2025-001",
    "total_amount": 320000,
    "final_amount": 320000,
    "items": [{"description": "수학 수업 4회차", "quantity": 4, "unit_price": 40000, "amount": 160000}]
  }' | jq -r '.invoice_id')

# 2. 카카오페이 링크 생성 (sent 상태로 변경)
curl -X POST "http://localhost:8000/invoices/$INVOICE_ID/create-kakao-pay-link"

# 3. 생성된 링크 확인
curl "http://localhost:8000/invoices/$INVOICE_ID" | jq '.kakao_pay_link'

# 4-1. 카카오페이 결제 승인 (pg_token 사용, 권장)
curl -X POST "http://localhost:8000/invoices/$INVOICE_ID/approve-payment?pg_token=test_pg_token_123"

# 4-2. 또는 수동으로 결제 완료 처리
curl -X POST "http://localhost:8000/invoices/$INVOICE_ID/complete-payment?kakao_pay_tid=TEST_TID_123"
```

### 4.8 청구 수정
```bash
curl -X PATCH "http://localhost:8000/invoices/1" \
  -H "Content-Type: application/json" \
  -d '{
    "notes": "추가 메모",
    "status": "sent"
  }'
```

### 4.9 청구 삭제
```bash
curl -X DELETE "http://localhost:8000/invoices/1"
```

---

## 5. 헬스체크

```bash
curl "http://localhost:8000/healthz"
```

---

---

## 6. 카카오페이 테스트 가이드

### 6.1 테스트 모드 (기본값)
기본적으로 `KAKAO_PAY_TEST_MODE=true`로 설정되어 있어 실제 카카오페이 API 호출 없이 테스트 가능합니다.

**환경변수 설정** (`.env` 파일):
```bash
# 테스트 모드 (기본값, 설정 안 해도 됨)
KAKAO_PAY_TEST_MODE=true
```

**테스트 플로우**:
1. 청구서 생성 → `draft` 상태
2. 카카오페이 링크 생성 → `sent` 상태, 모의 링크 반환
3. 결제 완료 처리 → `paid` 상태

### 6.2 실제 카카오페이 연동 (선택사항)

**1. 카카오 개발자 센터 설정**
- https://developers.kakao.com 접속
- 내 애플리케이션 생성
- 카카오페이 서비스 활성화
- Admin Key 발급

**2. 환경변수 설정** (`.env` 파일):
```bash
KAKAO_PAY_ADMIN_KEY=your_admin_key_here
KAKAO_PAY_TEST_MODE=false
KAKAO_PAY_CID=TC0ONETIME  # 테스트용 (실서비스는 실제 CID 사용)
```

**3. 실제 결제 테스트**
- 카카오페이 개발자 센터에서 테스트 결제 가능
- 실제 결제 링크가 생성되어 카카오톡으로 전송 가능

### 6.3 카카오페이 콜백 처리

결제 완료 후 카카오페이가 `approval_url`로 리다이렉트하며 `pg_token`을 전달합니다.

**프론트엔드에서 처리**:
```javascript
// approval_url에서 pg_token 추출
const urlParams = new URLSearchParams(window.location.search);
const pgToken = urlParams.get('pg_token');

// 백엔드에 결제 승인 요청
fetch(`/invoices/${invoiceId}/approve-payment`, {
  method: 'POST',
  body: JSON.stringify({ pg_token: pgToken }),
  headers: { 'Content-Type': 'application/json' }
});
```

**또는 백엔드에서 직접 승인 처리** (추가 엔드포인트 필요 시 구현 가능)

---

## 참고사항

1. **서버 실행**: `uvicorn app.backend.main:app --reload` (기본 포트: 8000)
2. **API 문서**: `http://localhost:8000/docs` (Swagger UI)
3. **날짜 형식**: `YYYY-MM-DD` (예: 2025-01-15)
4. **시간 형식**: `HH:MM:SS` (예: 19:00:00)
5. **상태 코드**:
   - 201: 생성 성공
   - 200: 조회/수정 성공
   - 204: 삭제 성공
   - 404: 리소스 없음
   - 409: 충돌 (스케줄 중복 등)
   - 400: 잘못된 요청
   - 500: 서버 오류 (카카오페이 API 오류 등)

