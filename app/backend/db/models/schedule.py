from __future__ import annotations
from datetime import datetime, date, time
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, BigInteger, Integer, Date, Time, DateTime, Text, func, ForeignKey, UniqueConstraint, Index

from app.backend.db.base_class import Base
from app.backend.db.enums import schedule_type


class Schedule(Base):
    __tablename__ = "schedules"

    schedule_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    teacher_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("teachers.teacher_id"), nullable=False, index=True)
    lesson_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)
    student_id: Mapped[int | None] = mapped_column(BigInteger, ForeignKey("students.student_id"), nullable=True, index=True)
    schedule_type: Mapped[str] = mapped_column(schedule_type, nullable=False)
    title: Mapped[str | None] = mapped_column(String(100), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    color: Mapped[str] = mapped_column(String(7), nullable=False, server_default="#3788D8")

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    __table_args__ = (
        UniqueConstraint("teacher_id", "lesson_date", "start_time", name="uniq_teacher_date_time"),
        Index("idx_teacher", "teacher_id"),
        Index("idx_date", "lesson_date"),
        Index("idx_student", "student_id"),
    )
