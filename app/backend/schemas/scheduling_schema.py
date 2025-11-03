# app/backend/schemas/scheduling_schema.py
from pydantic import BaseModel
from typing import List, Optional, Dict, Any

# 클라이언트 요청 DTO
class ScheduleRequest(BaseModel):
    command: str
    timezone: Optional[str] = "Asia/Seoul"
    days: Optional[int] = 7
    work_start: Optional[str] = "18:00"
    work_end: Optional[str] = "21:00"
    slot_minutes: Optional[int] = 60
    min_gap_minutes: Optional[int] = 5
    max_candidates: Optional[int] = 3

# Intent 1개
class Intent(BaseModel):
    type: str
    student: Optional[str] = None
    channel: Optional[str] = None
    message: Optional[str] = None
    time_pref: Optional[str] = None
    meta: Optional[Dict[str, Any]] = None  # 실행결과(후보시간/전송결과 등)를 담는 컨테이너

# 복합 Intent 리스트
class ParsedIntentList(BaseModel):
    intents: List[Intent]
