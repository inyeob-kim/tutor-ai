from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import BigInteger, Integer, ForeignKey, Boolean, text

from app.backend.db.base_class import Base


class TeacherSubject(Base):
    __tablename__ = "teacher_subjects"

    teacher_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("teachers.teacher_id"), primary_key=True, nullable=False
    )
    subject_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("subjects.id"), primary_key=True, nullable=False
    )
    price_per_hour: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))

