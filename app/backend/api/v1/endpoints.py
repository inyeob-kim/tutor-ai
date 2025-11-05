# app/api/v1/endpoints.py
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
from schemas.command import CommandRequest, ActionPlan
from services.intent_extractor import extract_intent
from services.orchestra import execute_action_plan

router = APIRouter()

@router.post("/command", response_model=dict)
async def process_command(
    request: CommandRequest,
    db: Session = Depends(get_db)
):
    try:
        # 1. LLM → ActionPlan
        action_plan: ActionPlan = extract_intent(request.message)
        
        # 2. 오케스트레이터 → DB 사용
        result = execute_action_plan(db, request.user_id, action_plan)
        
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {e}")