from fastapi import APIRouter, HTTPException
from schemas.command import CommandRequest, ActionPlan
from services.intent_extractor import extract_intent
from services.orchestra import execute_action_plan

router = APIRouter()

@router.post("/command", response_model=dict)
async def process_command(request: CommandRequest):
    try:
        # 1. LLM으로 의도 추출
        action_plan: ActionPlan = extract_intent(request.user_id, request.message)
        
        # 2. 오케스트레이터 실행
        result = execute_action_plan(action_plan)
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {e}")