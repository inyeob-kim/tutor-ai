from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Integer, BigInteger, DateTime, ForeignKey, Text, CheckConstraint
from sqlalchemy.dialects.postgresql import TIMESTAMP
from datetime import datetime, timezone

def now_utc() -> datetime:
    return datetime.now(timezone.utc)

from ..db.database import Base

class Course(Base):
    __tablename__ = "courses"
    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id"), nullable=False, index=True)
    subject: Mapped[str] = mapped_column(String(200), nullable=False)
    default_duration_min: Mapped[int] = mapped_column(Integer, nullable=False)
    location_mode: Mapped[str] = mapped_column(String(16), nullable=False)  # online/offline
    location_place: Mapped[str | None] = mapped_column(String(255))
    rate_type: Mapped[str] = mapped_column(String(16), nullable=False)  # hourly/per-session
    rate_amount: Mapped[int] = mapped_column(Integer, nullable=False)
    recurrence_kind: Mapped[str | None] = mapped_column(String(16))      # weekly/biweekly
    recurrence_weekday: Mapped[int | None] = mapped_column(Integer)      # 0..6
    recurrence_start_time: Mapped[str | None] = mapped_column(String(5)) # HH:MM
    created_at: Mapped[datetime] = mapped_column(TIMESTAMP(timezone=True), default=now_utc)
