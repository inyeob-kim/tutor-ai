from __future__ import annotations
from datetime import datetime, date
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy import (
    String,
    BigInteger,
    Integer,
    Boolean,
    Date,
    DateTime,
    Text,
    func,
    UniqueConstraint,
)

from app.backend.db.base_class import Base
from app.backend.db.enums import teacher_tax_type, auth_provider
from app.backend.db.types import EncryptedString, HashedString
from app.backend.db.mixins import setup_hash_fields


class Teacher(Base):
    __tablename__ = "teachers"

    teacher_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    nickname: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)
    phone: Mapped[str] = mapped_column(EncryptedString, nullable=False)
    email: Mapped[str | None] = mapped_column(EncryptedString, nullable=True)
    account_name: Mapped[str | None] = mapped_column(EncryptedString, nullable=True)
    bank_code: Mapped[str | None] = mapped_column(String(3), nullable=True)
    account_number: Mapped[str | None] = mapped_column(EncryptedString, nullable=True)
    
    # 해시 필드 (검색용, 필요시 unique constraint에도 사용 가능)
    phone_hash: Mapped[str] = mapped_column(HashedString, nullable=False, index=True)
    email_hash: Mapped[str | None] = mapped_column(HashedString, nullable=True, index=True)
    
    subject_id: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    tax_type: Mapped[str | None] = mapped_column(teacher_tax_type, nullable=True)
    hourly_rate_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    hourly_rate_max: Mapped[int | None] = mapped_column(Integer, nullable=True)
    available_days: Mapped[str | None] = mapped_column(String(100), nullable=True)
    available_time: Mapped[str | None] = mapped_column(String(200), nullable=True)
    vacation_start: Mapped[date | None] = mapped_column(Date, nullable=True)
    vacation_end: Mapped[date | None] = mapped_column(Date, nullable=True)
    # 수업 시간 설정 (타임슬롯 제한용)
    lesson_start_hour: Mapped[int | None] = mapped_column(Integer, nullable=True, server_default="12")
    lesson_end_hour: Mapped[int | None] = mapped_column(Integer, nullable=True, server_default="22")
    exclude_weekends: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default="false")
    total_students: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    monthly_income: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    # Social auth
    provider: Mapped[str] = mapped_column(auth_provider, nullable=False)
    oauth_id: Mapped[str] = mapped_column(String(191), nullable=False)  # provider-issued subject/id

    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    __table_args__ = (
        UniqueConstraint("provider", "oauth_id", name="uniq_provider_oauth_id"),
    )

# 해시 필드 자동 업데이트 이벤트 리스너 등록
setup_hash_fields(Teacher)
