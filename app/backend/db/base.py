# app/backend/db/base.py
from sqlalchemy import Column, Integer, DateTime, func
from app.backend.db.base_class import Base
# 여기에 모든 모델 import
from app.backend.db.models import (
    Category,
    Subject,
    Student,
    Teacher,
    Schedule,
    Invoice,
    InvoiceItem,
)  # noqa: F401


class BaseModel:
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())