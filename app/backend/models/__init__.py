# app/models/__init__.py (맨 아래에 있어야 함!)
from database import SessionLocal
from .user import User
from .student import Student
from .schedule import Schedule 

def create_test_data():
    db = SessionLocal()
    try:
        # 선생님 존재 여부 확인
        if not db.query(User).filter(User.id == 1).first():
            teacher = User(id=1, google_id="test", name="김인엽", email="inyeob.kim@bankwareglobal.com")
            db.add(teacher)

            student = Student(user_id=1, name="이환주", total_sessions=10, used_sessions=0)
            db.add(student)

            db.commit()
            print("테스트 데이터 생성 완료!")
        else:
            print("이미 테스트 데이터 존재")
    except Exception as e:
        print(f"테스트 데이터 생성 실패: {e}")
    finally:
        db.close()

create_test_data()  # 이 줄이 중요!