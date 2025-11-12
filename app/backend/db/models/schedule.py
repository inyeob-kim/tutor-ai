from __future__ import annotations
from datetime import datetime, date
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import BigInteger, Date, DateTime, Text, String, func, ForeignKey, Index

from app.backend.db.base_class import Base
class Schedule(Base):
    __tablename__ = "schedules"

    schedule_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    teacher_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("teachers.teacher_id"), nullable=False, index=True)
    student_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("students.student_id"), nullable=False, index=True)
    lesson_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    start_time: Mapped[str] = mapped_column(String(5), nullable=False)
    end_time: Mapped[str] = mapped_column(String(5), nullable=False)
    subject_id: Mapped[str] = mapped_column(String(50), nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(Text, nullable=False, server_default="confirmed")
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    cancelled_by: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    cancel_reason: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    __table_args__ = (
        Index("ix_schedules_teacher_id_lesson_date", "teacher_id", "lesson_date"),
        Index("ix_schedules_status", "status"),
        Index("ix_schedules_subject_id", "subject_id"),
    )
