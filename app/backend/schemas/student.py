# app/backend/schemas/student.py
from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime

class StudentBase(BaseModel):
    name: str
    email: Optional[str] = None
    grade: Optional[str] = None
    student_phone: Optional[str] = None
    guardian_phone: Optional[str] = None
    memo: Optional[str] = None

class StudentCreate(StudentBase):
    pass

class StudentUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    grade: Optional[str] = None
    student_phone: Optional[str] = None
    guardian_phone: Optional[str] = None
    memo: Optional[str] = None

class StudentOut(StudentBase):
    model_config = ConfigDict(from_attributes=True)
    user_id: int
    created_at: datetime
    updated_at: datetime

class StudentListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[StudentOut]
