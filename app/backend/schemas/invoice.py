from __future__ import annotations

from datetime import datetime
from typing import Optional, Literal
from pydantic import BaseModel, ConfigDict

InvoiceStatus = Literal["draft", "sent", "partial", "paid", "void"]


class InvoiceItemBase(BaseModel):
    description: str
    subject: Optional[str] = None
    quantity: int = 1
    unit_price: int
    amount: int
    lesson_date: Optional[str] = None
    notes: Optional[str] = None


class InvoiceItemCreate(InvoiceItemBase):
    pass


class InvoiceItemOut(InvoiceItemBase):
    model_config = ConfigDict(from_attributes=True)
    item_id: int
    invoice_id: int


class InvoiceBase(BaseModel):
    teacher_id: int
    student_id: int
    invoice_number: str
    status: InvoiceStatus = "draft"
    total_amount: int
    tax_amount: int = 0
    final_amount: int
    billing_period_start: Optional[datetime] = None
    billing_period_end: Optional[datetime] = None
    notes: Optional[str] = None


class InvoiceCreate(InvoiceBase):
    items: list[InvoiceItemCreate] = []


class InvoiceUpdate(BaseModel):
    status: Optional[InvoiceStatus] = None
    kakao_pay_link: Optional[str] = None
    kakao_pay_tid: Optional[str] = None
    paid_at: Optional[datetime] = None
    notes: Optional[str] = None


class InvoiceOut(InvoiceBase):
    model_config = ConfigDict(from_attributes=True)
    invoice_id: int
    kakao_pay_link: Optional[str] = None
    kakao_pay_tid: Optional[str] = None
    paid_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
    items: list[InvoiceItemOut] = []


class InvoiceListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[InvoiceOut]

