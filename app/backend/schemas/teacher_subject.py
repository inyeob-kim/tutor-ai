from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class TeacherSubjectBase(BaseModel):
    teacher_id: int
    subject_id: int
    price_per_hour: int
    is_active: bool = True


class TeacherSubjectCreate(TeacherSubjectBase):
    pass


class TeacherSubjectUpdate(BaseModel):
    price_per_hour: int | None = None
    is_active: bool | None = None


class TeacherSubjectOut(TeacherSubjectBase):
    model_config = ConfigDict(from_attributes=True)

