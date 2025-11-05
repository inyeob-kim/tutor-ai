# app/models/base.py
from sqlalchemy import Column, Integer, DateTime, func

class BaseModel:
    id = Column(Integer, primary_key=True, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())