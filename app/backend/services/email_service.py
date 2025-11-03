# app/backend/services/email_service.py
from typing import Dict, Any
from schemas.scheduling_schema import Intent

def handle_email_intent(intent: Intent) -> Dict[str, Any]:
    """
    이메일 전송 (데모: 실제 전송 대신 본문 미리보기 생성)
    """
    subject = f"[과외] {intent.student or '학생'} 수업 관련 문의"
    body = intent.message or "안내드립니다."
    # TODO: Gmail API 연동 시 실제 전송/초안 저장 구현
    return {
        "subject": subject,
        "preview_body": body,
        "sent": False,
        "note": "현재는 전송 대신 미리보기만 생성합니다."
    }
