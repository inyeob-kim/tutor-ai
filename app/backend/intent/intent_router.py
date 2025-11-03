# app/backend/intent/intent_router.py
from typing import Dict, Any
from schemas.scheduling_schema import ParsedIntentList, Intent, ScheduleRequest
from intent.intent_types import (
    INTENT_SCHEDULE_CHECK, INTENT_SCHEDULE_CHANGE,
    INTENT_MESSAGE_SEND, INTENT_EMAIL_SEND, INTENT_PRIORITY
)
from services.scheduling_service import handle_schedule_intent
from services.kakao_service import handle_kakao_intent
from services.email_service import handle_email_intent

def route_intents(parsed_intent_list: ParsedIntentList, req: ScheduleRequest) -> ParsedIntentList:
    """
    복합 의도 처리:
    - intents 배열을 받아 intent 우선순위로 정렬 후 순차 실행
    - 실행 결과(예: candidate_times, message 등)를 intents[i].meta에 기록
    - 최종 intents 결과를 그대로 반환 (response_model=ParsedIntentList)
    """
    # 우선순위 정렬
    intents_sorted = sorted(
        parsed_intent_list.intents,
        key=lambda it: INTENT_PRIORITY.get(it.type, 0),
        reverse=True
    )

    for it in intents_sorted:
        result: Dict[str, Any] = {}
        if it.type in (INTENT_SCHEDULE_CHECK, INTENT_SCHEDULE_CHANGE):
            result = handle_schedule_intent(it, req)
        elif it.type == INTENT_MESSAGE_SEND:
            result = handle_kakao_intent(it)
        elif it.type == INTENT_EMAIL_SEND:
            result = handle_email_intent(it)
        else:
            result = {"warning": f"지원하지 않는 intent: {it.type}"}

        # 실행 결과를 meta에 붙임
        it.meta = result

    # 의도 배열 업데이트 후 반환
    parsed_intent_list.intents = intents_sorted
    return parsed_intent_list
