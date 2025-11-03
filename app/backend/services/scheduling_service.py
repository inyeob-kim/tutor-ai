# app/backend/services/scheduling_service.py
from typing import Dict, Any
from datetime import time
from schemas.scheduling_schema import Intent, ScheduleRequest
from services.calendar_service import find_available_slots

def _parse_hhmm(hhmm: str) -> time:
    h, m = (hhmm or "18:00").split(":")
    return time(int(h), int(m))

def handle_schedule_intent(intent: Intent, req: ScheduleRequest) -> Dict[str, Any]:
    """
    스케줄 확인/변경 의도 처리:
    - FreeBusy 기반 후보 시간 계산
    - 결과를 meta에 담아 반환
    """
    candidates = find_available_slots(
        local_tz=req.timezone or "Asia/Seoul",
        days=req.days or 7,
        work_start=_parse_hhmm(req.work_start or "18:00"),
        work_end=_parse_hhmm(req.work_end or "21:00"),
        slot_minutes=req.slot_minutes or 60,
        min_gap_minutes=req.min_gap_minutes or 5,
        max_candidates=req.max_candidates or 3,
    )

    return {
        "student": intent.student,
        "time_pref": intent.time_pref,
        "candidates": candidates,
        "note": "Google Calendar FreeBusy 기반 후보 시간입니다."
    }
