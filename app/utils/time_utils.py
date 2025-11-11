from datetime import datetime, date, timezone, timedelta
from dateutil import tz

KST = tz.gettz("Asia/Seoul")

def kst_datetime(d: date, hhmm: str) -> datetime:
    """Convert date + hh:mm (local) to UTC datetime"""
    h, m = map(int, hhmm.split(":"))
    dt_local = datetime(d.year, d.month, d.day, h, m, tzinfo=KST)
    return dt_local.astimezone(timezone.utc)

def get_kst_range(range_type: str):
    """today/week/month → UTC 범위"""
    now = datetime.now(timezone.utc).astimezone(KST)
    if range_type == "today":
        start = datetime(now.year, now.month, now.day, tzinfo=KST)
        end = start + timedelta(days=1)
    elif range_type == "week":
        start = datetime(now.year, now.month, now.day, tzinfo=KST) - timedelta(days=now.weekday())
        end = start + timedelta(days=7)
    else:
        start = datetime(now.year, now.month, 1, tzinfo=KST)
        if start.month == 12:
            end = datetime(start.year + 1, 1, 1, tzinfo=KST)
        else:
            end = datetime(start.year, start.month + 1, 1, tzinfo=KST)
    return start.astimezone(timezone.utc), end.astimezone(timezone.utc)
