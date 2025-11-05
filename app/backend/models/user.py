# app/models/user.py
from sqlalchemy import Column, String, Integer
from sqlalchemy.orm import relationship
from .base import BaseModel  # 공통 컬럼
from database import Base   # SQLAlchemy Base

class User(Base, BaseModel):
    __tablename__ = "users"

    google_id = Column(String, unique=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)

    students = relationship("Student", back_populates="user")
    schedules = relationship("Schedule", back_populates="user")