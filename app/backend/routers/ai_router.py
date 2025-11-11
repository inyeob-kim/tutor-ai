"""
AI 어시스턴트 라우터
- 음성 입력 처리
- LLM 처리
- 음성 응답 생성
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession
from app.backend.db.database import get_session
from app.backend.services.speech_service import SpeechService
from app.backend.services.intent_extractor import extract_intent_with_history
from app.backend.services.orchestra import _execute_action
from app.backend.schemas.command import ActionPlan
import uuid
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ai", tags=["ai"])

# SpeechService 인스턴스
speech_service = SpeechService()


@router.post("/process_audio")
async def process_audio(
    audio: UploadFile = File(...),
    session_id: str | None = None,
    teacher_id: int = 1,  # TODO: 실제 인증에서 가져오기
    db: AsyncSession = Depends(get_session),
):
    """
    음성 입력을 처리하고 음성 응답을 반환
    
    Flow:
    1. 음성 → 텍스트 (Whisper)
    2. 텍스트 → LLM 처리 (의도 추출 + 실행)
    3. 응답 텍스트 → 음성 (TTS)
    
    Returns:
        - text: LLM 응답 텍스트
        - audio: TTS 오디오 (base64 인코딩)
    """
    try:
        # 세션 ID 생성 (없으면)
        if not session_id:
            session_id = str(uuid.uuid4())
        
        # 1. 오디오 파일 읽기
        audio_data = await audio.read()
        if not audio_data:
            raise HTTPException(status_code=400, detail="오디오 데이터가 없습니다.")
        
        logger.info(f"Received audio: {len(audio_data)} bytes, session_id: {session_id}")
        
        # 2. Speech-to-Text
        try:
            user_text = speech_service.speech_to_text(
                audio_data, 
                filename=audio.filename or "recording.webm"
            )
            logger.info(f"Transcribed: {user_text}")
        except Exception as e:
            logger.error(f"STT error: {e}")
            raise HTTPException(status_code=500, detail=f"음성 인식 실패: {str(e)}")
        
        if not user_text or not user_text.strip():
            raise HTTPException(status_code=400, detail="음성을 인식할 수 없습니다.")
        
        # 3. LLM 처리 (의도 추출 + 실행)
        try:
            # 의도 추출
            intent_result = extract_intent_with_history(session_id, user_text)
            
            # 자연어 질문인 경우 (추가 정보 필요)
            if "response" in intent_result:
                ai_response_text = intent_result["response"]
            else:
                # 액션 실행
                if "action" in intent_result:
                    action_plan = ActionPlan(**intent_result["action"])
                    action_result = _execute_action(db, teacher_id, action_plan)
                    
                    # ai_response는 이미 intent_result에 있음
                    ai_response_text = intent_result.get("ai_response", "처리 완료되었습니다.")
                else:
                    ai_response_text = "처리 완료되었습니다."
            
            logger.info(f"AI Response: {ai_response_text}")
            
        except Exception as e:
            logger.error(f"LLM processing error: {e}")
            ai_response_text = "죄송해요, 다시 말씀해 주세요."
        
        # 4. Text-to-Speech
        try:
            audio_bytes = speech_service.text_to_speech(ai_response_text, voice="nova")
        except Exception as e:
            logger.error(f"TTS error: {e}")
            # TTS 실패해도 텍스트는 반환
            audio_bytes = None
        
        # 5. 응답 생성
        import base64
        
        response_data = {
            "text": ai_response_text,
            "session_id": session_id,
        }
        
        if audio_bytes:
            # 오디오를 base64로 인코딩
            audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
            response_data["audio"] = audio_base64
        
        return response_data
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"처리 중 오류가 발생했습니다: {str(e)}")


@router.post("/process_text")
async def process_text(
    message: str,
    session_id: str | None = None,
    teacher_id: int = 1,  # TODO: 실제 인증에서 가져오기
    db: AsyncSession = Depends(get_session),
):
    """
    텍스트 입력을 처리하고 텍스트 응답을 반환 (음성 없이)
    """
    try:
        # 세션 ID 생성 (없으면)
        if not session_id:
            session_id = str(uuid.uuid4())
        
        # LLM 처리
        intent_result = extract_intent_with_history(session_id, message)
        
        if "response" in intent_result:
            ai_response_text = intent_result["response"]
        else:
            # 액션 실행
            if "action" in intent_result:
                action_plan = ActionPlan(**intent_result["action"])
                action_result = _execute_action(db, teacher_id, action_plan)
                
                # ai_response는 이미 intent_result에 있음
                ai_response_text = intent_result.get("ai_response", "처리 완료되었습니다.")
            else:
                ai_response_text = "처리 완료되었습니다."
        
        return {
            "text": ai_response_text,
            "session_id": session_id,
        }
        
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"처리 중 오류가 발생했습니다: {str(e)}")

