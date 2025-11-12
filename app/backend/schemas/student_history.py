from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Dict

from pydantic import BaseModel, ConfigDict


class StudentHistoryChangeType(str, Enum):
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DELETE = "DELETE"


class StudentHistoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    history_id: int
    student_id: int
    teacher_id: int | None = None
    change_type: StudentHistoryChangeType
    payload: Dict[str, Any]
    changed_at: datetime


