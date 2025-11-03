# app/backend/routers/schedule_controller.py
from fastapi import APIRouter
from schemas.scheduling_schema import ScheduleRequest, ParsedIntentList
from services.gemini_service import parse_command
from intent.intent_router import route_intents

router = APIRouter(prefix="/schedule", tags=["schedule"])

@router.post("/process", response_model=ParsedIntentList)
def schedule_process(req: ScheduleRequest):
    """
    1) LLM에서 intents 리스트 추출
    2) Intent Router가 각 intent별 서비스 호출/조율
    3) 결과(메타 + candidates)를 함께 반환
    """
    parsed_intents = parse_command(req.command)
    return route_intents(parsed_intents, req)
