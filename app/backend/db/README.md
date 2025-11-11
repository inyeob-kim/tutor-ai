## Student

### students 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `student_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `name` | VARCHAR(50) | NOT NULL | - | 학생 이름 |
| `phone` | VARCHAR(20) | NOT NULL | - | 전화번호 (하이픈 없이 01012345678) |
| `parent_phone` | VARCHAR(20) | NULL | - | 부모님 연락처 (선택) |
| `school` | VARCHAR(100) | NULL | - | 학교/학년 |
| `grade` | VARCHAR(20) | NULL | - | 학년 (예: 고1, 중3, 초6) |
| `subject` | VARCHAR(100) | NULL | - | 과목 (수학, 영어, 국어+수학 등) |
| `start_date` | DATE | NULL | - | 과외 시작일 |
| `lesson_day` | VARCHAR(50) | NULL | - | 수업 요일 (월수금, 토일 등) |
| `lesson_time` | VARCHAR(50) | NULL | - | 수업 시간 (19:00~21:00 등) |
| `hourly_rate` | INT | NULL | - | 시급 |
| `notes` | TEXT | NULL | - | 특이사항, 약점, 목표 등 |
| `is_active` | TINYINT(1) | NOT NULL | 1 | 현재 수업 중 여부 |
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

## Schedule

### schedules 테이블 구조

| 컬럼명 | 타입 | NULL | 기본값 | 설명 |
|--------|------|------|--------|------|
| `schedule_id` | BIGINT | NOT NULL | AUTO_INCREMENT | 내부용 고유 ID (Primary Key) |
| `teacher_id` | BIGINT | NOT NULL | - | 교사 ID (FK: teachers.teacher_id) |
| `lesson_date` | DATE | NOT NULL | - | 날짜 |
| `start_time` | TIME | NOT NULL | - | 시작 시간 |
| `end_time` | TIME | NOT NULL | - | 종료 시간 |
| `student_id` | BIGINT | NULL | - | 학생 ID (FK: students.student_id) |
| `schedule_type` | ENUM('lesson','available','vacation','personal') | NOT NULL | - | 일정 유형 |
| `title` | VARCHAR(100) | NULL | - | 제목 |
| `notes` | TEXT | NULL | - | 비고 |
| `color` | VARCHAR(7) | NOT NULL | '#3788D8' | 표시 색상 |
| `created_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 생성일시 |
| `updated_at` | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP | 수정일시 |

### 제약 및 인덱스
- **PK**: `schedule_id`
- **UNIQUE**: `uniq_teacher_date_time (teacher_id, lesson_date, start_time)`
- **INDEX**: `idx_teacher (teacher_id)`, `idx_date (lesson_date)`, `idx_student (student_id)`