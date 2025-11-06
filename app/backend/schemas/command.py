# app/schemas/command.py
from pydantic import BaseModel
from typing import Literal, Dict, Any, Optional


# === API 요청 ===
class CommandRequest(BaseModel):
    user_id: str
    message: str


# === LLM이 정보 충분할 때만 생성되는 액션 ===
class ActionPlan(BaseModel):
    action: Literal[
        "schedule_create",
        "schedule_update",
        "schedule_cancel",
        "schedule_list",
        "session_use",
        "session_add"
    ]
    params: Dict[str, Any] = {}  # 기본값 빈 dict → schedule_list 등 사용 가능