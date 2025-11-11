# app/backend/db/models/student.py (경로는 사용하는 구조에 맞춰주세요)
from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, Integer, BigInteger, DateTime, Text, func
from app.backend.db.base_class import Base

class Student(Base):
    __tablename__ = "students"

    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    email: Mapped[str | None] = mapped_column(String(120), nullable=True)
    student_phone: Mapped[str | None] = mapped_column(String(20), nullable=True, index=True)
    grade: Mapped[str | None] = mapped_column(String(20), nullable=True, index=True)
    guardian_phone: Mapped[str | None] = mapped_column(String(20), nullable=True, index=True)
    memo: Mapped[str | None] = mapped_column(Text, nullable=True)
    user_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, index=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )
    # migration에 updated_at이 있으면 모델에도 추가
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )
