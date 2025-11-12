## Student

### students 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `student_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `name` | VARCHAR(50) | NOT NULL | - | 학생 이름 |
| `phone` | VARCHAR(20) | NOT NULL | - | 전화번호 (하이픈 없이 01012345678) |
| `parent_phone` | VARCHAR(20) | NULL | - | 부모님 연락처 (선택) |
| `teacher_id` | BIGINT | NULL | - | 담당 교사 ID (FK: teachers.teacher_id) |
| `school` | VARCHAR(100) | NULL | - | 학교/학년 |
| `grade` | VARCHAR(20) | NULL | - | 학년 (예: 고1, 중3, 초6) |
| `subject` | VARCHAR(100) | NULL | - | 과목 (수학, 영어, 국어+수학 등) |
| `start_date` | DATE | NULL | - | 과외 시작일 |
| `lesson_day` | VARCHAR(50) | NULL | - | 수업 요일 (월수금, 토일 등) |
| `lesson_time` | VARCHAR(50) | NULL | - | 수업 시간 (19:00~21:00 등) |
| `hourly_rate` | INT | NULL | - | 시급 |
| `notes` | TEXT | NULL | - | 특이사항, 약점, 목표 등 |
| `is_active` | TINYINT(1) | NOT NULL | 1 | 현재 수업 중 여부 |
| `is_adult` | BOOLEAN | NOT NULL | false | 성인 여부 (true: 성인, false: 미성년자) |
| `created_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| `updated_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 수정일시 |

### 제약 조건

- **Primary Key**: `student_id`
- **Unique Constraint**: `uniq_name_phone` (`name`, `phone`) - 이름과 전화번호 조합 중복 방지

---

## Teacher

### teachers 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `teacher_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `name` | VARCHAR(50) | NOT NULL | - | 본명 |
| `phone` | VARCHAR(20) | NOT NULL | - | 연락처 |
| `subject_id` | INT | NULL | - | 대표 과목 ID (FK: subjects.id) |
| `email` | VARCHAR(100) | NULL | - | 이메일 |
| `bank_name` | VARCHAR(50) | NULL | - | 입금받을 은행 |
| `account_number` | VARCHAR(30) | NULL | - | 계좌번호 |
| `tax_type` | ENUM('사업소득','기타소득','프리랜서','미신고') | NOT NULL | '사업소득' | 세금 신고 유형 |
| `hourly_rate_min` | INT | NULL | - | 최저 시급 |
| `hourly_rate_max` | INT | NULL | - | 최고 시급 |
| `available_days` | VARCHAR(100) | NULL | - | 수업 가능한 요일 |
| `available_time` | VARCHAR(200) | NULL | - | 가능한 시간대 |
| `vacation_start` | DATE | NULL | - | 방학/휴가 시작일 |
| `vacation_end` | DATE | NULL | - | 방학/휴가 종료일 |
| `total_students` | INT | NOT NULL | 0 | 현재 학생 수 |
| `monthly_income` | INT | NOT NULL | 0 | 이번 달 예상 수입 |
| `provider` | ENUM('google','kakao','naver','apple') | NOT NULL | - | 소셜 로그인 제공자 |
| `oauth_id` | VARCHAR(191) | NOT NULL | - | 제공자 발급 사용자 ID |
| `notes` | TEXT | NULL | - | 비고 / 목표 등 |
| `created_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| `updated_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 수정일시 |

### 제약 조건
- **Unique Constraint**: `uniq_provider_oauth_id` (`provider`, `oauth_id`) - 소셜 계정 식별자 유니크
---

## Category

### categories 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `id` | SERIAL | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `name` | VARCHAR(50) | NOT NULL | - | 대분류 이름 (언어, 음악 등) |
| `icon` | VARCHAR(100) | NULL | - | UI 표시용 아이콘(이모지/FontAwesome) |
| `sort_order` | INT | NOT NULL | 0 | 정렬 우선순위 (작을수록 상위) |
| `is_active` | BOOLEAN | NOT NULL | true | 사용 여부 |

---

## Subject

### subjects 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `id` | SERIAL | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `category_id` | INT | NOT NULL | - | 대분류 ID (FK: categories.id) |
| `code` | VARCHAR(20) | NOT NULL | - | 과목 코드 (예: ENG, MATH) |
| `name` | VARCHAR(50) | NOT NULL | - | 과목명 (예: 영어 회화) |
| `color` | VARCHAR(7) | NOT NULL | '#3788D8' | 과목 색상 HEX |
| `is_active` | BOOLEAN | NOT NULL | true | 사용 여부 |

### 제약 조건
- **Primary Key**: `id`
- **Foreign Key**: `category_id` → `categories.id`
- **Unique Constraint**: `code`

---

## Schedule

### schedules 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `schedule_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `teacher_id` | BIGINT | NOT NULL | - | 교사 ID (FK: teachers.teacher_id) |
| `student_id` | BIGINT | NOT NULL | - | 학생 ID (FK: students.student_id) |
| `lesson_date` | DATE | NOT NULL | - | 날짜 |
| `start_time` | VARCHAR(5) | NOT NULL | - | 시작 시간 (HH:MM) |
| `end_time` | VARCHAR(5) | NOT NULL | - | 종료 시간 (HH:MM) |
| `subject_id` | INT | NOT NULL | - | 과목 ID (FK: subjects.id) |
| `notes` | TEXT | NULL | - | 비고 |
| `status` | VARCHAR(20) | NOT NULL | 'confirmed' | 일정 상태 |
| `cancelled_at` | DATETIME | NULL | - | 취소 일시 |
| `cancelled_by` | BIGINT | NULL | - | 취소한 사용자 ID |
| `cancel_reason` | TEXT | NULL | - | 취소 사유 |
| `created_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| `updated_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 수정일시 |

### 제약 및 인덱스
- **PK**: `schedule_id`
- **UNIQUE**: `uniq_teacher_date_time (teacher_id, lesson_date, start_time)`
- **INDEX**: `idx_teacher (teacher_id)`, `idx_date (lesson_date)`, `idx_student (student_id)`, `ix_schedules_subject_id (subject_id)`

---

## Teacher Subject

### teacher_subjects 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `teacher_id` | BIGINT | NOT NULL | - | 교사 ID (FK: teachers.teacher_id, PK) |
| `subject_id` | INT | NOT NULL | - | 과목 ID (FK: subjects.id, PK) |
| `price_per_hour` | INT | NOT NULL | - | 시간당 수업료 |
| `is_active` | BOOLEAN | NOT NULL | true | 사용 여부 |

### 제약 조건
- **Primary Key**: (`teacher_id`, `subject_id`) - 복합 키
- **Foreign Key**: `teacher_id` → `teachers.teacher_id`
- **Foreign Key**: `subject_id` → `subjects.id`

---

## Student Subject

### student_subjects 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `student_id` | BIGINT | NOT NULL | - | 학생 ID (FK: students.student_id, PK) |
| `teacher_id` | BIGINT | NOT NULL | - | 교사 ID (FK: teachers.teacher_id, PK) |
| `subject` | VARCHAR(50) | NOT NULL | - | 과목명 (PK) |
| `hourly_rate` | INT | NOT NULL | - | 실제 청구 시급 |
| `lesson_day` | VARCHAR(20) | NULL | - | 수업 요일 (월수, 화목 등) |
| `start_time` | TIME | NULL | - | 시작 시간 |
| `end_time` | TIME | NULL | - | 종료 시간 |

### 제약 조건
- **Primary Key**: (`student_id`, `teacher_id`, `subject`) - 복합 키
- **Foreign Key**: `student_id` → `students.student_id`
- **Foreign Key**: `teacher_id` → `teachers.teacher_id`

---

## Invoice

### invoices 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `invoice_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `teacher_id` | BIGINT | NOT NULL | - | 교사 ID (FK: teachers.teacher_id) |
| `student_id` | BIGINT | NOT NULL | - | 학생 ID (FK: students.student_id) |
| `invoice_number` | VARCHAR(50) | NOT NULL | - | 청구서 번호 (UNIQUE) |
| `status` | ENUM('draft','sent','partial','paid','void') | NOT NULL | 'draft' | 청구 상태 |
| `total_amount` | INT | NOT NULL | - | 총 청구 금액 |
| `tax_amount` | INT | NOT NULL | 0 | 세금 |
| `final_amount` | INT | NOT NULL | - | 최종 결제 금액 |
| `kakao_pay_link` | TEXT | NULL | - | 카카오페이 청구 링크 |
| `kakao_pay_tid` | VARCHAR(100) | NULL | - | 카카오페이 거래 ID |
| `billing_period_start` | DATETIME | NULL | - | 청구 기간 시작 |
| `billing_period_end` | DATETIME | NULL | - | 청구 기간 종료 |
| `paid_at` | DATETIME | NULL | - | 결제 완료 시간 |
| `notes` | TEXT | NULL | - | 메모 |
| `created_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| `updated_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 수정일시 |

### 제약 조건
- **Primary Key**: `invoice_id`
- **Unique**: `invoice_number` - 청구서 번호 유니크
- **Foreign Key**: `teacher_id` → `teachers.teacher_id`
- **Foreign Key**: `student_id` → `students.student_id`
- **Index**: `teacher_id`, `student_id`, `invoice_number`

### 상태 설명
- `draft`: 청구전 (청구 데이터만 적재)
- `sent`: 청구중 (카카오페이 링크 발송됨)
- `partial`: 부분 결제
- `paid`: 청구완료 (결제 완료)
- `void`: 취소

---

## Invoice Item

### invoice_items 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `item_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `invoice_id` | BIGINT | NOT NULL | - | 청구서 ID (FK: invoices.invoice_id) |
| `description` | VARCHAR(200) | NOT NULL | - | 항목 설명 (예: "수학 수업 4회차") |
| `subject` | VARCHAR(50) | NULL | - | 과목 |
| `quantity` | INT | NOT NULL | 1 | 수량 (수업 횟수 등) |
| `unit_price` | INT | NOT NULL | - | 단가 (시급) |
| `amount` | INT | NOT NULL | - | 금액 (quantity * unit_price) |
| `lesson_date` | VARCHAR(50) | NULL | - | 수업 날짜들 (예: "2025-01-01, 2025-01-08") |
| `notes` | VARCHAR(500) | NULL | - | 비고 |

### 제약 조건
- **Primary Key**: `item_id`
- **Foreign Key**: `invoice_id` → `invoices.invoice_id` (CASCADE DELETE)
- **Index**: `invoice_id`