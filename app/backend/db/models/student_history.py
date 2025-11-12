from __future__ import annotations

from datetime import datetime

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, func, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.backend.db.base_class import Base


class StudentHistory(Base):
    __tablename__ = "student_history"
    __table_args__ = (
        Index("ix_student_history_student_id_changed_at", "student_id", "changed_at"),
        Index("ix_student_history_teacher_id", "teacher_id"),
    )

    history_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="CASCADE"), nullable=False, index=True
    )
    teacher_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("teachers.teacher_id"), nullable=True
    )
    change_type: Mapped[str] = mapped_column(String(20), nullable=False)
    payload: Mapped[dict] = mapped_column(JSONB, nullable=False)
    changed_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
