"""
기존 평문 데이터를 암호화하는 마이그레이션 스크립트
실행 전 백업 필수!
"""
import asyncio
from sqlalchemy import text
from app.backend.db.database import async_session_maker
from app.backend.core.crypto import aesgcm_encrypt_str, hmac_sha256_hex
import json


async def migrate_students():
    """students 테이블의 평문 데이터를 암호화"""
    async with async_session_maker() as session:
        # 모든 학생 조회
        result = await session.execute(text("SELECT student_id, name, phone, parent_phone FROM students"))
        rows = result.fetchall()
        
        for row in rows:
            student_id, name, phone, parent_phone = row
            
            # 이미 암호화된 데이터인지 확인 (JSON 형태인지 체크)
            try:
                json.loads(name)
                print(f"Student {student_id}: Already encrypted, skipping")
                continue
            except (json.JSONDecodeError, TypeError):
                pass  # 평문 데이터, 암호화 필요
            
            # 암호화
            name_encrypted = json.dumps(aesgcm_encrypt_str(name))
            phone_encrypted = json.dumps(aesgcm_encrypt_str(phone))
            name_hash = hmac_sha256_hex(name)
            phone_hash = hmac_sha256_hex(phone)
            
            parent_phone_encrypted = None
            if parent_phone:
                try:
                    json.loads(parent_phone)
                    # 이미 암호화됨
                    parent_phone_encrypted = parent_phone
                except (json.JSONDecodeError, TypeError):
                    parent_phone_encrypted = json.dumps(aesgcm_encrypt_str(parent_phone))
            
            # 업데이트
            await session.execute(
                text("""
                    UPDATE students 
                    SET name = :name, 
                        phone = :phone, 
                        parent_phone = :parent_phone,
                        name_hash = :name_hash,
                        phone_hash = :phone_hash
                    WHERE student_id = :student_id
                """),
                {
                    "name": name_encrypted,
                    "phone": phone_encrypted,
                    "parent_phone": parent_phone_encrypted,
                    "name_hash": name_hash,
                    "phone_hash": phone_hash,
                    "student_id": student_id,
                }
            )
            print(f"Student {student_id}: Encrypted")
        
        await session.commit()
        print(f"Migrated {len(rows)} students")


async def migrate_teachers():
    """teachers 테이블의 평문 데이터를 암호화"""
    async with async_session_maker() as session:
        # 모든 선생님 조회
        result = await session.execute(
            text("SELECT teacher_id, nickname, phone, email, account_name, account_number FROM teachers")
        )
        rows = result.fetchall()
        
        for row in rows:
            teacher_id, nickname, phone, email, account_name, account_number = row

            # phone이 이미 암호화되어 있으면 전체 row는 처리된 것으로 간주
            already_encrypted = False
            try:
                json.loads(phone)
                already_encrypted = True
            except (json.JSONDecodeError, TypeError):
                pass

            if already_encrypted:
                print(f"Teacher {teacher_id}: Already encrypted, skipping")
                continue
            
            # 암호화
            phone_encrypted = json.dumps(aesgcm_encrypt_str(phone))
            phone_hash = hmac_sha256_hex(phone)
            
            email_encrypted = None
            email_hash = None
            if email:
                try:
                    json.loads(email)
                    email_encrypted = email
                except (json.JSONDecodeError, TypeError):
                    email_encrypted = json.dumps(aesgcm_encrypt_str(email))
                    email_hash = hmac_sha256_hex(email)
            
            account_name_encrypted = None
            if account_name:
                try:
                    json.loads(account_name)
                    account_name_encrypted = account_name
                except (json.JSONDecodeError, TypeError):
                    account_name_encrypted = json.dumps(aesgcm_encrypt_str(account_name))
            
            account_number_encrypted = None
            if account_number:
                try:
                    json.loads(account_number)
                    account_number_encrypted = account_number
                except (json.JSONDecodeError, TypeError):
                    account_number_encrypted = json.dumps(aesgcm_encrypt_str(account_number))
            
            # 업데이트
            await session.execute(
                text("""
                    UPDATE teachers 
                    SET phone = :phone, 
                        email = :email,
                        account_name = :account_name,
                        account_number = :account_number,
                        phone_hash = :phone_hash,
                        email_hash = :email_hash
                    WHERE teacher_id = :teacher_id
                """),
                {
                    "phone": phone_encrypted,
                    "email": email_encrypted,
                    "account_name": account_name_encrypted,
                    "account_number": account_number_encrypted,
                    "phone_hash": phone_hash,
                    "email_hash": email_hash,
                    "teacher_id": teacher_id,
                }
            )
            print(f"Teacher {teacher_id}: Encrypted")
        
        await session.commit()
        print(f"Migrated {len(rows)} teachers")


async def main():
    print("Starting encryption migration...")
    print("⚠️  WARNING: Make sure you have a database backup!")
    
    try:
        await migrate_students()
        await migrate_teachers()
        print("✅ Migration completed successfully!")
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())

