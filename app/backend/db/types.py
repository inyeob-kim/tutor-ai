"""
SQLAlchemy 암호화 타입 정의
DB에 저장될 때 자동으로 암호화하고, 읽을 때 자동으로 복호화합니다.
"""
from __future__ import annotations
import json
from typing import Any
from sqlalchemy import TypeDecorator, Text, String
from sqlalchemy.dialects.postgresql import JSONB

from app.backend.core.crypto import aesgcm_encrypt_str, aesgcm_decrypt_str, hmac_sha256_hex


class EncryptedString(TypeDecorator):
    """
    암호화된 문자열 타입
    DB에는 JSON 형태의 암호화된 envelope로 저장됩니다.
    """
    impl = Text
    cache_ok = True

    def process_bind_param(self, value: str | None, dialect: Any) -> str | None:
        """DB에 저장하기 전 암호화"""
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError(f"EncryptedString expects str, got {type(value)}")
        
        # 이미 암호화된 JSON 문자열인지 확인 (중복 암호화 방지)
        try:
            test_envelope = json.loads(value)
            if isinstance(test_envelope, dict) and "alg" in test_envelope and "ct" in test_envelope:
                # 이미 암호화된 값이면 그대로 반환
                return value
        except (json.JSONDecodeError, TypeError, AttributeError):
            pass  # 평문이므로 암호화 진행
        
        # 암호화 (envelope 형태로 반환)
        envelope = aesgcm_encrypt_str(value)
        # JSON 문자열로 저장
        return json.dumps(envelope)

    def process_result_value(self, value: str | None, dialect: Any) -> str | None:
        """DB에서 읽을 때 복호화"""
        if value is None:
            return None
        if not isinstance(value, str):
            return None
        
        try:
            # JSON 문자열을 파싱하여 envelope 복원
            envelope = json.loads(value)
            # 복호화
            return aesgcm_decrypt_str(envelope)
        except (json.JSONDecodeError, ValueError, KeyError) as e:
            # 기존 평문 데이터가 있을 수 있으므로 그대로 반환 (마이그레이션 전)
            # 로그를 남기고 평문 반환
            import logging
            logging.warning(f"Failed to decrypt value (may be plaintext): {e}")
            return value


class HashedString(TypeDecorator):
    """
    해시된 문자열 타입 (검색 및 unique constraint용)
    원본 값을 HMAC-SHA256으로 해시하여 저장합니다.
    같은 값은 항상 같은 해시값을 생성하므로 unique constraint에 사용 가능합니다.
    """
    impl = String(64)  # SHA256 hex = 64 chars
    cache_ok = True

    def process_bind_param(self, value: str | None, dialect: Any) -> str | None:
        """DB에 저장하기 전 해시"""
        if value is None:
            return None
        if not isinstance(value, str):
            raise ValueError(f"HashedString expects str, got {type(value)}")
        
        # 이미 해시값인지 확인 (64자 hex 문자열)
        if len(value) == 64 and all(c in '0123456789abcdef' for c in value.lower()):
            # 이미 해시값이면 그대로 반환
            return value
        
        # 평문이면 해시 생성
        return hmac_sha256_hex(value)

    def process_result_value(self, value: str | None, dialect: Any) -> str | None:
        """해시값은 복호화하지 않고 그대로 반환 (검색용)"""
        return value
