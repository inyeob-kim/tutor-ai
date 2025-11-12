# app/backend/db/models/student.py
from __future__ import annotations
from datetime import datetime, date
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Integer, BigInteger, DateTime, Date, Text, Boolean, func, UniqueConstraint
from app.backend.db.base_class import Base
from app.backend.db.types import EncryptedString, HashedString
from app.backend.db.mixins import setup_hash_fields

class Student(Base):
    __tablename__ = "students"

    student_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(EncryptedString, nullable=False)
    phone: Mapped[str] = mapped_column(EncryptedString, nullable=False)
    parent_phone: Mapped[str | None] = mapped_column(EncryptedString, nullable=True)
    
    # 해시 필드 (unique constraint 및 검색용)
    name_hash: Mapped[str] = mapped_column(HashedString, nullable=False, index=True)
    phone_hash: Mapped[str] = mapped_column(HashedString, nullable=False, index=True)
    
    school: Mapped[str | None] = mapped_column(String(100), nullable=True)
    grade: Mapped[str | None] = mapped_column(String(20), nullable=True)
    subject: Mapped[str | None] = mapped_column(String(100), nullable=True)
    start_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    lesson_day: Mapped[str | None] = mapped_column(String(50), nullable=True)
    lesson_time: Mapped[str | None] = mapped_column(String(50), nullable=True)
    hourly_rate: Mapped[int | None] = mapped_column(Integer, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, server_default="1")
    is_adult: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False, server_default="0")

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    __table_args__ = (
        UniqueConstraint('name_hash', 'phone_hash', name='uniq_name_phone'),
    )

# 해시 필드 자동 업데이트 이벤트 리스너 등록
setup_hash_fields(Student)
