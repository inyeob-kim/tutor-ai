# app/backend/schemas/student.py
from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime, date

class StudentBase(BaseModel):
    name: str
    phone: str
    parent_phone: Optional[str] = None
    teacher_id: Optional[int] = None
    school: Optional[str] = None
    grade: Optional[str] = None
    subject: Optional[str] = None
    start_date: Optional[date] = None
    lesson_day: Optional[str] = None
    lesson_time: Optional[str] = None
    hourly_rate: Optional[int] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = True
    is_adult: Optional[bool] = False

class StudentCreate(StudentBase):
    pass

class StudentUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    parent_phone: Optional[str] = None
    teacher_id: Optional[int] = None
    school: Optional[str] = None
    grade: Optional[str] = None
    subject: Optional[str] = None
    start_date: Optional[date] = None
    lesson_day: Optional[str] = None
    lesson_time: Optional[str] = None
    hourly_rate: Optional[int] = None
    notes: Optional[str] = None
    is_active: Optional[bool] = None
    is_adult: Optional[bool] = None

class StudentOut(StudentBase):
    model_config = ConfigDict(from_attributes=True)
    student_id: int
    created_at: datetime
    updated_at: datetime

class StudentListResp(BaseModel):
    total: int
    page: int
    pageSize: int
    items: list[StudentOut]
