# app/api/v1/endpoints.py
from fastapi import APIRouter, HTTPException, Depends, Header
from sqlalchemy.orm import Session
from database import get_db
from schemas.command import CommandRequest
from services.orchestra import process_command_with_redis  # ← 변경!
import uuid

router = APIRouter()

@router.post("/command", response_model=dict)
async def process_command(
    request: CommandRequest,
    db: Session = Depends(get_db),
    session_id: str = Header(None, alias="X-Session-ID")  # ← 프론트에서 전달
):
    # 세션 ID 없으면 생성
    if not session_id:
        session_id = str(uuid.uuid4())
    
    try:
        # Redis + 히스토리 + 재질문 포함된 함수 호출
        result = process_command_with_redis(
            db=db,
            user_id=request.user_id,
            message=request.message,
            session_id=session_id
        )
        
        # 응답에 session_id 포함 (프론트에서 유지)
        result["session_id"] = session_id
        return result
        
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"서버 오류: {e}")