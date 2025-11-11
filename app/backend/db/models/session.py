from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Integer, BigInteger, DateTime, ForeignKey, Text, CheckConstraint
from sqlalchemy.dialects.postgresql import TIMESTAMP
from datetime import datetime, timezone

def now_utc() -> datetime:
    return datetime.now(timezone.utc)

from ..db.database import Base

class Session(Base):
    __tablename__ = "sessions"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    course_id: Mapped[int | None] = mapped_column(ForeignKey("courses.id"))
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), index=True, nullable=False)
    subject: Mapped[str] = mapped_column(String(200), nullable=False)
    start_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False, index=True)
    end_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    location_mode: Mapped[str] = mapped_column(String(16), nullable=False)  # online/offline
    location_place: Mapped[str | None] = mapped_column(String(255))
    attendance_status: Mapped[str | None] = mapped_column(String(16))  # present/absent/late
    attendance_memo: Mapped[str | None] = mapped_column(Text())
    attendance_marked_at: Mapped[datetime | None] = mapped_column(TIMESTAMP(timezone=True))
