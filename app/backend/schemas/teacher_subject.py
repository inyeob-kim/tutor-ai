from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class TeacherSubjectBase(BaseModel):
    teacher_id: int
    subject: str
    hourly_rate: int | None = None


class TeacherSubjectCreate(TeacherSubjectBase):
    pass


class TeacherSubjectUpdate(BaseModel):
    hourly_rate: int | None = None


class TeacherSubjectOut(TeacherSubjectBase):
    model_config = ConfigDict(from_attributes=True)

