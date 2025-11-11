# 카카오페이 청구 테스트 가이드

## 🎯 테스트 모드 (기본값 - 추천)

기본적으로 **테스트 모드**가 활성화되어 있어 실제 카카오페이 API 호출 없이 테스트할 수 있습니다.

### 환경변수 설정 (선택사항)
`.env` 파일에 다음을 추가하거나, 기본값 그대로 사용:
```bash
KAKAO_PAY_TEST_MODE=true  # 기본값
```

### 테스트 플로우

#### 1. 청구서 생성 (draft 상태)
```bash
curl -X POST "http://localhost:8000/invoices" \
  -H "Content-Type: application/json" \
  -d '{
    "teacher_id": 1,
    "student_id": 1,
    "invoice_number": "INV-2025-001",
    "total_amount": 320000,
    "final_amount": 320000,
    "items": [
      {
        "description": "수학 수업 4회차",
        "quantity": 4,
        "unit_price": 40000,
        "amount": 160000
      }
    ]
  }'
```

**응답 예시**:
```json
{
  "invoice_id": 1,
  "status": "draft",
  "kakao_pay_link": null,
  ...
}
```

#### 2. 카카오페이 링크 생성 (sent 상태로 변경)
```bash
curl -X POST "http://localhost:8000/invoices/1/create-kakao-pay-link"
```

**응답 예시** (테스트 모드):
```json
{
  "invoice_id": 1,
  "status": "sent",
  "kakao_pay_link": "https://mock.kakaopay.com/payment?order_id=INV-2025-001",
  "kakao_pay_tid": "TEST_TID_INV-2025-001",
  ...
}
```

#### 3. 생성된 링크 확인
```bash
curl "http://localhost:8000/invoices/1" | jq '.kakao_pay_link'
```

#### 4. 결제 승인 (paid 상태로 변경)
```bash
# pg_token으로 승인 (권장)
curl -X POST "http://localhost:8000/invoices/1/approve-payment?pg_token=test_pg_token_123"

# 또는 수동으로 완료 처리
curl -X POST "http://localhost:8000/invoices/1/complete-payment?kakao_pay_tid=TEST_TID_INV-2025-001"
```

**응답 예시**:
```json
{
  "invoice_id": 1,
  "status": "paid",
  "paid_at": "2025-01-11T16:50:00",
  ...
}
```

---

## 🔧 실제 카카오페이 연동 (선택사항)

실제 카카오페이 API를 사용하려면 다음 설정이 필요합니다.

### 1. 카카오 개발자 센터 설정

1. https://developers.kakao.com 접속
2. 내 애플리케이션 생성
3. 카카오페이 서비스 활성화
4. **Admin Key** 발급 (앱 설정 > 앱 키)
5. **CID** 발급 (카카오페이 > 가맹점 관리)

### 2. 환경변수 설정

`.env` 파일에 추가:
```bash
KAKAO_PAY_ADMIN_KEY=your_admin_key_here
KAKAO_PAY_TEST_MODE=false
KAKAO_PAY_CID=TC0ONETIME  # 테스트용 CID (실서비스는 실제 CID 사용)
```

### 3. 실제 결제 테스트

위와 동일한 curl 명령어를 사용하되, 실제 카카오페이 링크가 생성됩니다.

**주의사항**:
- 테스트 환경에서는 실제 결제가 발생하지 않습니다
- 카카오페이 개발자 센터에서 테스트 결제 가능
- 실서비스에서는 실제 CID와 Admin Key 사용 필요

---

## 📋 전체 테스트 시나리오

```bash
# 변수 설정
BASE_URL="http://localhost:8000"

# 1. 선생님 등록
TEACHER_ID=$(curl -s -X POST "$BASE_URL/teachers" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "홍길동",
    "phone": "01012345678",
    "provider": "google",
    "oauth_id": "google_123"
  }' | jq -r '.teacher_id')

# 2. 학생 등록
STUDENT_ID=$(curl -s -X POST "$BASE_URL/students" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "김철수",
    "phone": "01098765432"
  }' | jq -r '.student_id')

# 3. 청구서 생성
INVOICE_ID=$(curl -s -X POST "$BASE_URL/invoices" \
  -H "Content-Type: application/json" \
  -d "{
    \"teacher_id\": $TEACHER_ID,
    \"student_id\": $STUDENT_ID,
    \"invoice_number\": \"INV-2025-001\",
    \"total_amount\": 320000,
    \"final_amount\": 320000,
    \"items\": [{
      \"description\": \"수학 수업 4회차\",
      \"quantity\": 4,
      \"unit_price\": 40000,
      \"amount\": 160000
    }]
  }" | jq -r '.invoice_id')

echo "Created invoice: $INVOICE_ID"

# 4. 카카오페이 링크 생성
curl -X POST "$BASE_URL/invoices/$INVOICE_ID/create-kakao-pay-link" | jq '.'

# 5. 링크 확인
LINK=$(curl -s "$BASE_URL/invoices/$INVOICE_ID" | jq -r '.kakao_pay_link')
echo "Payment link: $LINK"

# 6. 결제 승인 (테스트)
curl -X POST "$BASE_URL/invoices/$INVOICE_ID/approve-payment?pg_token=test_token" | jq '.'

# 7. 최종 상태 확인
curl -s "$BASE_URL/invoices/$INVOICE_ID" | jq '{status, paid_at, kakao_pay_link}'
```

---

## 🔍 상태 확인

각 단계별 상태 확인:
- `draft`: 청구서 생성 완료, 링크 미생성
- `sent`: 카카오페이 링크 생성 완료, 결제 대기
- `paid`: 결제 완료

```bash
# 상태별 청구서 조회
curl "http://localhost:8000/invoices?status=draft"
curl "http://localhost:8000/invoices?status=sent"
curl "http://localhost:8000/invoices?status=paid"
```

---

## ⚠️ 주의사항

1. **테스트 모드**: 기본값으로 설정되어 있어 실제 결제가 발생하지 않습니다
2. **실서비스 전환**: `KAKAO_PAY_TEST_MODE=false`로 변경하고 실제 키 사용
3. **CID**: 테스트용 `TC0ONETIME`은 실제 결제 불가, 실서비스는 별도 CID 필요
4. **보안**: Admin Key는 절대 공개하지 마세요

