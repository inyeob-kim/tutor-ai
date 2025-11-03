# app/backend/intent/intent_types.py

# 의도명 상수/Enum (간단 상수로 유지)
INTENT_SCHEDULE_CHECK = "스케줄 확인"
INTENT_SCHEDULE_CHANGE = "스케줄 변경"
INTENT_MESSAGE_SEND   = "메시지 전송"
INTENT_EMAIL_SEND     = "이메일 전송"

# Intent 우선순위 (필요 시 조정)
INTENT_PRIORITY = {
    INTENT_SCHEDULE_CHANGE: 10,
    INTENT_SCHEDULE_CHECK:  9,
    INTENT_MESSAGE_SEND:    5,
    INTENT_EMAIL_SEND:      4,
}
