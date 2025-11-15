-- attendance_status 컬럼 확인 쿼리

-- 1. schedules 테이블의 컬럼 목록 확인
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'schedules'
ORDER BY ordinal_position;

-- 2. attendance_status enum 타입 확인
SELECT typname, typtype
FROM pg_type
WHERE typname = 'attendance_status';

-- 3. attendance_status 컬럼 상세 정보 확인
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'schedules' 
  AND column_name = 'attendance_status';

