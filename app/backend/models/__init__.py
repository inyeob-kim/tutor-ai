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
            db.flush()  # ID 확보
            print("선생님 테스트 데이터 생성 완료!")

        # 학생1
        if not db.query(Student).filter(Student.user_id == 1).first():
            student = Student(user_id=1, name="이환주", total_sessions=10, used_sessions=0)
            db.add(student)
            db.commit()
            print("학생1 테스트 데이터 생성 완료!")

        # 학생2
        if not db.query(Student).filter(Student.user_id == 2).first():
            # 먼저 User 생성
            if not db.query(User).filter(User.id == 2).first():
                user2 = User(id=2, google_id="test2", name="최우인", email="woo.choi@example.com")
                db.add(user2)
                db.flush()

            student = Student(user_id=2, name="최우인", total_sessions=10, used_sessions=0)
            db.add(student)
            db.commit()
            print("학생2 테스트 데이터 생성 완료!")

    except Exception as e:
        db.rollback()
        print(f"테스트 데이터 생성 실패: {e}")
    finally:
        db.close()