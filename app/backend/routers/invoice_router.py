from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime

from app.backend.db.database import get_session
from app.backend.db.models import Invoice, InvoiceItem
from app.backend.schemas.invoice import (
    InvoiceCreate,
    InvoiceOut,
    InvoiceListResp,
    InvoiceUpdate,
    InvoiceItemCreate,
)

router = APIRouter(prefix="/invoices", tags=["invoices"])


@router.post("", response_model=InvoiceOut, status_code=201)
async def create_invoice(payload: InvoiceCreate, session: AsyncSession = Depends(get_session)):
    """청구하기 버튼 클릭 시 청구 데이터 적재"""
    data = payload.model_dump(exclude_unset=True, exclude={"items"})
    cols = set(Invoice.__table__.columns.keys())
    safe = {k: v for k, v in data.items() if k in cols}
    
    invoice = Invoice(**safe)
    session.add(invoice)
    await session.flush()  # invoice_id 생성
    
    # 청구 항목 추가
    for item_data in payload.items:
        item = InvoiceItem(invoice_id=invoice.invoice_id, **item_data.model_dump())
        session.add(item)
    
    await session.commit()
    await session.refresh(invoice)
    # items 로드
    await session.refresh(invoice, ["items"])
    return invoice


@router.get("", response_model=InvoiceListResp)
async def list_invoices(
    teacher_id: int | None = Query(None),
    student_id: int | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    pageSize: int = Query(20, ge=1, le=200),
    session: AsyncSession = Depends(get_session),
):
    stmt = select(Invoice)
    cnt = select(func.count()).select_from(Invoice)
    
    if teacher_id:
        stmt = stmt.where(Invoice.teacher_id == teacher_id)
        cnt = cnt.where(Invoice.teacher_id == teacher_id)
    if student_id:
        stmt = stmt.where(Invoice.student_id == student_id)
        cnt = cnt.where(Invoice.student_id == student_id)
    if status:
        stmt = stmt.where(Invoice.status == status)
        cnt = cnt.where(Invoice.status == status)
    
    total = (await session.execute(cnt)).scalar_one()
    rows = (
        await session.execute(
            stmt.order_by(Invoice.created_at.desc())
            .offset((page - 1) * pageSize)
            .limit(pageSize)
        )
    ).scalars().all()
    
    # items 로드
    for invoice in rows:
        await session.refresh(invoice, ["items"])
    
    return InvoiceListResp(total=total, page=page, pageSize=pageSize, items=rows)


@router.get("/{invoice_id}", response_model=InvoiceOut)
async def get_invoice(invoice_id: int, session: AsyncSession = Depends(get_session)):
    invoice = await session.get(Invoice, invoice_id)
    if not invoice:
        raise HTTPException(404, "Invoice not found")
    await session.refresh(invoice, ["items"])
    return invoice


@router.patch("/{invoice_id}", response_model=InvoiceOut)
async def update_invoice(
    invoice_id: int,
    payload: InvoiceUpdate,
    session: AsyncSession = Depends(get_session),
):
    """청구 상태 업데이트 (카카오페이 링크 저장, 결제 완료 처리 등)"""
    invoice = await session.get(Invoice, invoice_id)
    if not invoice:
        raise HTTPException(404, "Invoice not found")
    
    data = payload.model_dump(exclude_unset=True)
    cols = set(Invoice.__table__.columns.keys())
    for k, v in data.items():
        if k in cols:
            setattr(invoice, k, v)
    
    # 결제 완료 시 paid_at 자동 설정
    if data.get("status") == "paid" and not invoice.paid_at:
        invoice.paid_at = datetime.now()
    
    await session.commit()
    await session.refresh(invoice, ["items"])
    return invoice


@router.post("/{invoice_id}/send-link", response_model=InvoiceOut)
async def send_kakao_pay_link(
    invoice_id: int,
    kakao_pay_link: str,
    session: AsyncSession = Depends(get_session),
):
    """카카오페이 청구 링크 발송 (상태를 sent로 변경)"""
    invoice = await session.get(Invoice, invoice_id)
    if not invoice:
        raise HTTPException(404, "Invoice not found")
    
    if invoice.status not in ["draft", "sent"]:
        raise HTTPException(400, f"Cannot send link for invoice with status: {invoice.status}")
    
    invoice.kakao_pay_link = kakao_pay_link
    invoice.status = "sent"
    
    await session.commit()
    await session.refresh(invoice, ["items"])
    return invoice


@router.post("/{invoice_id}/complete-payment", response_model=InvoiceOut)
async def complete_payment(
    invoice_id: int,
    kakao_pay_tid: str | None = None,
    session: AsyncSession = Depends(get_session),
):
    """결제 완료 처리 (카카오페이 콜백 또는 앱에서 호출)"""
    invoice = await session.get(Invoice, invoice_id)
    if not invoice:
        raise HTTPException(404, "Invoice not found")
    
    if invoice.status == "paid":
        raise HTTPException(400, "Invoice already paid")
    
    invoice.status = "paid"
    invoice.paid_at = datetime.now()
    if kakao_pay_tid:
        invoice.kakao_pay_tid = kakao_pay_tid
    
    await session.commit()
    await session.refresh(invoice, ["items"])
    return invoice


@router.delete("/{invoice_id}", status_code=204)
async def delete_invoice(invoice_id: int, session: AsyncSession = Depends(get_session)):
    invoice = await session.get(Invoice, invoice_id)
    if not invoice:
        raise HTTPException(404, "Invoice not found")
    
    if invoice.status == "paid":
        raise HTTPException(400, "Cannot delete paid invoice")
    
    await session.delete(invoice)
    await session.commit()
    return None

