# app/backend/services/calendar_service.py
from __future__ import annotations
from datetime import datetime, timedelta, time
from typing import List, Dict, Tuple
from zoneinfo import ZoneInfo

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

TOKEN_PATH = "token.json"
SCOPES = ["https://www.googleapis.com/auth/calendar"]

def _get_calendar_service():
    creds = Credentials.from_authorized_user_file(TOKEN_PATH, SCOPES)
    # cache_discovery=False 권장(로컬 경합 회피)
    return build("calendar", "v3", credentials=creds, cache_discovery=False)

def get_freebusy_blocks(start_utc: datetime, end_utc: datetime) -> List[Tuple[datetime, datetime]]:
    """
    primary 캘린더의 busy 구간(UTC)을 [(start, end), ...] 로 반환
    """
    service = _get_calendar_service()
    body = {
        "timeMin": start_utc.isoformat(),
        "timeMax": end_utc.isoformat(),
        "items": [{"id": "primary"}],
    }
    resp = service.freebusy().query(body=body).execute()
    blocks = []
    for b in resp["calendars"]["primary"].get("busy", []):
        s = datetime.fromisoformat(b["start"].replace("Z", "+00:00"))
        e = datetime.fromisoformat(b["end"].replace("Z", "+00:00"))
        blocks.append((s, e))
    return blocks

def _overlaps(a_start: datetime, a_end: datetime, b_start: datetime, b_end: datetime) -> bool:
    return not (a_end <= b_start or b_end <= a_start)

def find_available_slots(
    local_tz: str = "Asia/Seoul",
    days: int = 7,
    work_start: time = time(18, 0),
    work_end: time = time(21, 0),
    slot_minutes: int = 60,
    min_gap_minutes: int = 5,
    max_candidates: int = 3,
) -> List[Dict[str, str]]:
    """
    FreeBusy 결과를 이용해 로컬 타임존 기준의 '가능 슬롯' 반환.
    각 슬롯: {"date":"YYYY-MM-DD","time":"HH:MM"}
    """
    tz = ZoneInfo(local_tz)
    now_local = datetime.now(tz).replace(second=0, microsecond=0)
    window_start_local = now_local
    window_end_local = (now_local + timedelta(days=days)).replace(second=0, microsecond=0)
    window_start_utc = window_start_local.astimezone(ZoneInfo("UTC"))
    window_end_utc = window_end_local.astimezone(ZoneInfo("UTC"))

    busy = get_freebusy_blocks(window_start_utc, window_end_utc)

    candidates: List[Dict[str, str]] = []
    cur_day = window_start_local.date()
    slot_delta = timedelta(minutes=slot_minutes)
    gap_delta = timedelta(minutes=min_gap_minutes)

    while cur_day <= window_end_local.date() and len(candidates) < max_candidates:
        day_start_local = datetime.combine(cur_day, work_start, tzinfo=tz)
        day_end_local = datetime.combine(cur_day, work_end, tzinfo=tz)

        slot_start_local = max(day_start_local, window_start_local)
        while slot_start_local + slot_delta <= day_end_local and len(candidates) < max_candidates:
            slot_end_local = slot_start_local + slot_delta

            s_utc = slot_start_local.astimezone(ZoneInfo("UTC")) - gap_delta
            e_utc = slot_end_local.astimezone(ZoneInfo("UTC")) + gap_delta

            conflict = any(_overlaps(s_utc, e_utc, b_start, b_end) for b_start, b_end in busy)
            if not conflict:
                candidates.append({
                    "date": slot_start_local.strftime("%Y-%m-%d"),
                    "time": slot_start_local.strftime("%H:%M"),
                })

            slot_start_local += slot_delta

        cur_day = cur_day + timedelta(days=1)

    return candidates
