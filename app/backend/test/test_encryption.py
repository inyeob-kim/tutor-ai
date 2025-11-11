"""
암호화 테스트 스크립트
"""
import asyncio
from app.backend.db.database import async_session_maker
from app.backend.db.models import Student
from app.backend.core.crypto import aesgcm_decrypt_str, hmac_sha256_hex
import json


async def test_encryption():
    """암호화가 제대로 작동하는지 테스트"""
    async with async_session_maker() as session:
        # 테스트 학생 생성
        student = Student(
            name="테스트학생",
            phone="01012345678",
            name_hash=hmac_sha256_hex("테스트학생"),
            phone_hash=hmac_sha256_hex("01012345678")
        )
        session.add(student)
        await session.flush()  # DB에 저장 (암호화 실행)
        
        # 실제 DB에서 조회하여 암호화 확인
        from sqlalchemy import text
        result = await session.execute(
            text("SELECT name, phone, name_hash, phone_hash FROM students WHERE student_id = :id"),
            {"id": student.student_id}
        )
        row = result.fetchone()
        
        if row:
            name_raw, phone_raw, name_hash, phone_hash = row
            print(f"DB에 저장된 name (raw): {name_raw[:100]}...")
            print(f"DB에 저장된 phone (raw): {phone_raw[:100]}...")
            print(f"name_hash: {name_hash}")
            print(f"phone_hash: {phone_hash}")
            
            # 암호화되었는지 확인 (JSON 형태인지)
            try:
                name_envelope = json.loads(name_raw)
                print(f"✅ name은 암호화되어 있습니다: {name_envelope.get('alg')}")
                
                # 복호화 테스트
                decrypted_name = aesgcm_decrypt_str(name_envelope)
                print(f"복호화된 name: {decrypted_name}")
            except (json.JSONDecodeError, TypeError):
                print(f"❌ name이 암호화되지 않았습니다 (평문)")
            
            try:
                phone_envelope = json.loads(phone_raw)
                print(f"✅ phone은 암호화되어 있습니다: {phone_envelope.get('alg')}")
                
                # 복호화 테스트
                decrypted_phone = aesgcm_decrypt_str(phone_envelope)
                print(f"복호화된 phone: {decrypted_phone}")
            except (json.JSONDecodeError, TypeError):
                print(f"❌ phone이 암호화되지 않았습니다 (평문)")
        
        # ORM으로 조회 (자동 복호화)
        await session.refresh(student)
        print(f"\nORM으로 조회한 name: {student.name}")
        print(f"ORM으로 조회한 phone: {student.phone}")
        
        # 테스트 데이터 삭제
        await session.delete(student)
        await session.commit()
        print("\n✅ 테스트 완료")


if __name__ == "__main__":
    asyncio.run(test_encryption())

