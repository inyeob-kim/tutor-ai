from __future__ import annotations
from datetime import time
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, BigInteger, Integer, Time, ForeignKey

from app.backend.db.base_class import Base


class StudentSubject(Base):
    __tablename__ = "student_subjects"

    student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id"), primary_key=True, nullable=False
    )
    teacher_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("teachers.teacher_id"), primary_key=True, nullable=False
    )
    subject: Mapped[str] = mapped_column(String(50), primary_key=True, nullable=False)
    hourly_rate: Mapped[int] = mapped_column(Integer, nullable=False)
    lesson_day: Mapped[str | None] = mapped_column(String(20), nullable=True)
    start_time: Mapped[time | None] = mapped_column(Time, nullable=True)
    end_time: Mapped[time | None] = mapped_column(Time, nullable=True)

