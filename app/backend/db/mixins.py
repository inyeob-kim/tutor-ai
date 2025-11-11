"""
SQLAlchemy Mixins for automatic hash field management
암호화된 필드의 해시값을 자동으로 생성합니다.
"""
from sqlalchemy import event
from sqlalchemy.orm import Session
from app.backend.core.crypto import hmac_sha256_hex


def setup_hash_fields(model_class):
    """
    모델 클래스에 해시 필드 자동 업데이트 이벤트 리스너 등록
    """
    @event.listens_for(model_class, "before_insert", propagate=True)
    @event.listens_for(model_class, "before_update", propagate=True)
    def receive_before_insert_or_update(mapper, connection, target):
        """저장/수정 전에 해시 필드 자동 업데이트"""
        # Student 모델
        if hasattr(target, 'name') and hasattr(target, 'name_hash'):
            if target.name and not target.name_hash:
                # name이 있고 name_hash가 없으면 생성
                # name은 암호화 전 평문이어야 함
                target.name_hash = hmac_sha256_hex(target.name)
        if hasattr(target, 'phone') and hasattr(target, 'phone_hash'):
            if target.phone and not target.phone_hash:
                # phone이 있고 phone_hash가 없으면 생성
                target.phone_hash = hmac_sha256_hex(target.phone)
        
        # Teacher 모델
        if hasattr(target, 'phone') and hasattr(target, 'phone_hash'):
            if target.phone and not target.phone_hash:
                target.phone_hash = hmac_sha256_hex(target.phone)
        if hasattr(target, 'email') and hasattr(target, 'email_hash'):
            if target.email:
                if not target.email_hash:
                    target.email_hash = hmac_sha256_hex(target.email)
            else:
                target.email_hash = None

