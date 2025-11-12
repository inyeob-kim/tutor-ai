"""
음성 처리 서비스
- Speech-to-Text: OpenAI Whisper
- Text-to-Speech: OpenAI TTS
"""
import os
import io
from openai import OpenAI
from app.backend.core.config import settings
import logging

logger = logging.getLogger(__name__)

# OpenAI 클라이언트 초기화 (API 키가 있을 때만)
_openai_api_key = os.getenv("OPENAI_API_KEY") or settings.OPENAI_API_KEY
client = OpenAI(api_key=_openai_api_key) if _openai_api_key else None


class SpeechService:
    """음성 처리 서비스"""
    
    def __init__(self):
        """초기화"""
        if not os.getenv("OPENAI_API_KEY"):
            logger.warning("OPENAI_API_KEY가 설정되지 않았습니다.")
        logger.info("SpeechService initialized")
    
    def speech_to_text(self, audio_data: bytes, filename: str = "audio.webm") -> str:
        """
        음성을 텍스트로 변환 (OpenAI Whisper)
        
        Args:
            audio_data: 오디오 바이너리 데이터
            filename: 파일명 (확장자로 포맷 인식)
            
        Returns:
            변환된 텍스트
        """
        try:
            # 바이너리 데이터를 파일 객체로 변환
            audio_file = io.BytesIO(audio_data)
            audio_file.name = filename
            
            # Whisper API 호출
            if client is None:
                raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다. 음성 인식을 사용하려면 API 키가 필요합니다.")
            transcript = client.audio.transcriptions.create(
                model="whisper-1",
                file=audio_file,
                language="ko",  # 한국어 지정으로 정확도 향상
            )
            
            text = transcript.text.strip()
            logger.info(f"Speech-to-text: {text[:50]}...")
            return text
            
        except Exception as e:
            logger.error(f"Speech-to-text error: {e}")
            raise Exception(f"음성 인식 실패: {str(e)}")
    
    def text_to_speech(self, text: str, voice: str = "nova") -> bytes:
        """
        텍스트를 음성으로 변환 (OpenAI TTS)
        
        Args:
            text: 변환할 텍스트
            voice: 음성 스타일 (alloy, echo, fable, onyx, nova, shimmer)
            
        Returns:
            오디오 바이너리 데이터 (MP3)
        """
        try:
            if client is None:
                raise ValueError("OPENAI_API_KEY가 설정되지 않았습니다. 음성 생성을 사용하려면 API 키가 필요합니다.")
            response = client.audio.speech.create(
                model="tts-1",  # 빠른 응답을 위해 tts-1 사용 (tts-1-hd는 더 고품질)
                voice=voice,
                input=text,
            )
            
            audio_bytes = response.content
            logger.info(f"Text-to-speech: {len(audio_bytes)} bytes generated")
            return audio_bytes
            
        except Exception as e:
            logger.error(f"Text-to-speech error: {e}")
            raise Exception(f"음성 생성 실패: {str(e)}")

