from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, BigInteger, Integer, ForeignKey

from app.backend.db.base_class import Base


class InvoiceItem(Base):
    __tablename__ = "invoice_items"

    item_id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    invoice_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("invoices.invoice_id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    # 청구 항목 정보
    description: Mapped[str] = mapped_column(String(200), nullable=False)  # 항목 설명 (예: "수학 수업 4회차")
    subject: Mapped[str | None] = mapped_column(String(50), nullable=True)  # 과목
    quantity: Mapped[int] = mapped_column(Integer, nullable=False, server_default="1")  # 수량 (수업 횟수 등)
    unit_price: Mapped[int] = mapped_column(Integer, nullable=False)  # 단가 (시급)
    amount: Mapped[int] = mapped_column(Integer, nullable=False)  # 금액 (quantity * unit_price)
    
    # 수업 정보 (참고용)
    lesson_date: Mapped[str | None] = mapped_column(String(50), nullable=True)  # 수업 날짜들 (예: "2025-01-01, 2025-01-08")
    notes: Mapped[str | None] = mapped_column(String(500), nullable=True)  # 비고
    
    # Relationship
    invoice: Mapped["Invoice"] = relationship("Invoice", back_populates="items")

