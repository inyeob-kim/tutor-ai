# app/schemas/command.py
from pydantic import BaseModel
from typing import Literal, Dict, Any

# Request model (for API input)
class CommandRequest(BaseModel):
    user_id: str
    message: str

# Response model (from LLM)
class ActionPlan(BaseModel):
    action: Literal[
        "schedule_create",
        "schedule_update",
        "schedule_cancel",
        "schedule_list",
        "session_use",
        "session_add"
    ]
    params: Dict[str, Any]
    requires_validation: bool = True