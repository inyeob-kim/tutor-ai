# app/backend/services/kakao_service.py
from typing import Dict, Any
from schemas.scheduling_schema import Intent

def _build_kakao_message(intent: Intent) -> str:
    # intent.meta의 후보시간을 활용해서 메시지 템플릿 생성
    cands = (intent.meta or {}).get("candidates", [])
    lines = []
    for c in cands[:3]:
        lines.append(f"- {c['date']} {c['time']}")
    listing = "\n".join(lines) if lines else "(제안 가능한 시간이 없습니다)"

    student = intent.student or "학생"
    return (
        f"안녕하세요, {student} 부모님 😊\n"
        f"가능하신 시간 확인 부탁드립니다.\n\n"
        f"{listing}\n\n"
        f"편하신 시간 알려주시면 일정 확정하겠습니다!"
    )

def handle_kakao_intent(intent: Intent) -> Dict[str, Any]:
    """
    카카오 메시지 전송 (현재는 실제 전송 대신 메시지 초안만 생성)
    intent.meta 안에 일정 후보가 있다면 템플릿에 반영
    """
    msg = _build_kakao_message(intent)
    # TODO: 카카오톡 비즈 메시지/친구톡 API 연동 (토큰/템플릿 관리)
    return {
        "channel": intent.channel or "카카오톡",
        "preview_message": msg,
        "sent": False,
        "note": "현재는 전송 대신 미리보기만 생성합니다."
    }
