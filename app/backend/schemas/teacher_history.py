from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any, Dict

from pydantic import BaseModel, ConfigDict


class TeacherHistoryChangeType(str, Enum):
    CREATE = "CREATE"
    UPDATE = "UPDATE"
    DELETE = "DELETE"


class TeacherHistoryOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    history_id: int
    teacher_id: int
    change_type: TeacherHistoryChangeType
    payload: Dict[str, Any]
    changed_at: datetime


