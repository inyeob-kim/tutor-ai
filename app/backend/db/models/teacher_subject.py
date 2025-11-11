from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import String, BigInteger, Integer, ForeignKey

from app.backend.db.base_class import Base


class TeacherSubject(Base):
    __tablename__ = "teacher_subjects"

    teacher_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("teachers.teacher_id"), primary_key=True, nullable=False
    )
    subject: Mapped[str] = mapped_column(String(50), primary_key=True, nullable=False)
    hourly_rate: Mapped[int | None] = mapped_column(Integer, nullable=True)

