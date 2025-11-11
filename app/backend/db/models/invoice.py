from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, BigInteger, Integer, DateTime, Text, func, ForeignKey

from app.backend.db.base_class import Base
from app.backend.db.enums import invoice_status


class Invoice(Base):
    __tablename__ = "invoices"

    invoice_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    teacher_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("teachers.teacher_id"), nullable=False, index=True)
    student_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("students.student_id"), nullable=False, index=True)
    
    # 청구서 정보
    invoice_number: Mapped[str] = mapped_column(String(50), nullable=False, unique=True, index=True)  # 청구서 번호 (예: INV-2025-001)
    status: Mapped[str] = mapped_column(invoice_status, nullable=False, server_default="draft")  # draft(청구전), sent(청구중), paid(청구완료), void(취소)
    
    # 금액 정보
    total_amount: Mapped[int] = mapped_column(Integer, nullable=False)  # 총 청구 금액
    tax_amount: Mapped[int] = mapped_column(Integer, nullable=False, server_default="0")  # 세금
    final_amount: Mapped[int] = mapped_column(Integer, nullable=False)  # 최종 결제 금액
    
    # 카카오페이 연동
    kakao_pay_link: Mapped[str | None] = mapped_column(Text, nullable=True)  # 카카오페이 청구 링크
    kakao_pay_tid: Mapped[str | None] = mapped_column(String(100), nullable=True)  # 카카오페이 거래 ID
    
    # 청구 기간
    billing_period_start: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)  # 청구 기간 시작
    billing_period_end: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)  # 청구 기간 종료
    
    # 결제 정보
    paid_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)  # 결제 완료 시간
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)  # 메모
    
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    
    # Relationship
    items: Mapped[list["InvoiceItem"]] = relationship("InvoiceItem", back_populates="invoice", cascade="all, delete-orphan")

