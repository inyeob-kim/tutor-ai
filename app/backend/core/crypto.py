# app/backend/core/crypto.py
from __future__ import annotations

import os
import base64
import hmac
import hashlib
from typing import Optional, Union, Any, Dict

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import phonenumbers

from .config import settings

# ─────────────────────────────────────────────────────────────
# Key material (32 bytes each) — validate early to fail fast
# ─────────────────────────────────────────────────────────────
def _b64decode_env(name: str) -> bytes:
    raw = getattr(settings, name, None)
    if not raw:
        raise RuntimeError(f"{name} is missing in environment")
    try:
        key = base64.b64decode(raw)
    except Exception as e:
        raise RuntimeError(f"{name} is not valid base64") from e
    return key

AES_KEY: bytes = _b64decode_env("AES_KEY_B64")     # 32 bytes expected
HMAC_KEY: bytes = _b64decode_env("HMAC_KEY_B64")   # 32 bytes expected

if len(AES_KEY) != 32:
    raise RuntimeError(f"AES_KEY_B64 must decode to 32 bytes, got {len(AES_KEY)}")
if len(HMAC_KEY) != 32:
    raise RuntimeError(f"HMAC_KEY_B64 must decode to 32 bytes, got {len(HMAC_KEY)}")

# AES-GCM requires 12-byte nonce for best practices
_NONCE_LEN = 12

# Versioning to allow future rotation/format updates
_ENVELOPE_VERSION = "v1"
_ENVELOPE_ALG = "AES-256-GCM"


# ─────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────
def _to_bytes(data: Union[str, bytes]) -> bytes:
    return data if isinstance(data, (bytes, bytearray)) else str(data).encode("utf-8")

def _aad_bytes(aad: Optional[Union[str, bytes, Dict[str, Any]]]) -> Optional[bytes]:
    if aad is None:
        return None
    if isinstance(aad, (bytes, bytearray)):
        return bytes(aad)
    if isinstance(aad, str):
        return aad.encode("utf-8")
    # dict 등은 안정적 직렬화를 위해 키 정렬된 JSON을 권장하지만,
    # 여기서는 간단화를 위해 str() 사용. 필요하면 json.dumps(aad, sort_keys=True)로 교체.
    return str(aad).encode("utf-8")


# ─────────────────────────────────────────────────────────────
# Phone utilities
# ─────────────────────────────────────────────────────────────
def to_e164(phone: str, region: str = "KR") -> str:
    """Normalize phone number to E.164 (+821012345678)."""
    try:
        num = phonenumbers.parse(phone, region)
    except phonenumbers.NumberParseException as e:
        raise ValueError(f"Invalid phone number format: {e}") from e
    if not phonenumbers.is_valid_number(num):
        raise ValueError("Invalid phone number: not a valid number")
    return phonenumbers.format_number(num, phonenumbers.PhoneNumberFormat.E164)


# ─────────────────────────────────────────────────────────────
# HMAC (SHA-256)
# ─────────────────────────────────────────────────────────────
def hmac_sha256_hex(data: Union[str, bytes]) -> str:
    """Return hex-encoded HMAC-SHA256 signature."""
    return hmac.new(HMAC_KEY, _to_bytes(data), hashlib.sha256).hexdigest()

def hmac_verify_hex(data: Union[str, bytes], hex_sig: str) -> bool:
    """Constant-time verification of hex signature."""
    try:
        calc = hmac_sha256_hex(data)
        return hmac.compare_digest(calc, hex_sig)
    except Exception:
        return False


# ─────────────────────────────────────────────────────────────
# AES-256-GCM (AEAD)
# Envelope format:
# {
#   "v": "v1",
#   "alg": "AES-256-GCM",
#   "nonce": "<base64>",
#   "ct": "<base64>"     # ciphertext + tag (GCM tag is appended by cryptography)
# }
# AAD(optional) can be passed for contextual binding (e.g., user_id)
# ─────────────────────────────────────────────────────────────
def aesgcm_encrypt(plaintext: Union[str, bytes], *, aad: Optional[Union[str, bytes, Dict[str, Any]]] = None) -> Dict[str, str]:
    aes = AESGCM(AES_KEY)
    nonce = os.urandom(_NONCE_LEN)
    ct = aes.encrypt(nonce, _to_bytes(plaintext), _aad_bytes(aad))
    return {
        "v": _ENVELOPE_VERSION,
        "alg": _ENVELOPE_ALG,
        "nonce": base64.b64encode(nonce).decode("utf-8"),
        "ct": base64.b64encode(ct).decode("utf-8"),
    }

def aesgcm_decrypt(env: Dict[str, str], *, aad: Optional[Union[str, bytes, Dict[str, Any]]] = None) -> bytes:
    """Return raw bytes; caller can .decode('utf-8') if it expects text."""
    if not isinstance(env, dict):
        raise ValueError("Invalid envelope: must be a dict")
    if env.get("v") not in {None, _ENVELOPE_VERSION}:
        raise ValueError(f"Unsupported envelope version: {env.get('v')}")
    if env.get("alg") not in {None, _ENVELOPE_ALG}:
        raise ValueError(f"Unsupported algorithm: {env.get('alg')}")

    try:
        nonce = base64.b64decode(env["nonce"])
        ct = base64.b64decode(env["ct"])
    except KeyError as e:
        raise ValueError(f"Missing field in envelope: {e}") from e
    except Exception as e:
        raise ValueError("Envelope contains invalid base64") from e

    if len(nonce) != _NONCE_LEN:
        raise ValueError("Invalid nonce length for AES-GCM")

    aes = AESGCM(AES_KEY)
    try:
        return aes.decrypt(nonce, ct, _aad_bytes(aad))
    except Exception as e:
        # authentication failure (tag mismatch) or malformed input
        raise ValueError("Decryption failed (auth/tag verification error)") from e


# ─────────────────────────────────────────────────────────────
# Convenience string APIs (utf-8)
# ─────────────────────────────────────────────────────────────
def aesgcm_encrypt_str(plaintext: str, *, aad: Optional[Union[str, bytes, Dict[str, Any]]] = None) -> Dict[str, str]:
    return aesgcm_encrypt(plaintext, aad=aad)

def aesgcm_decrypt_str(env: Dict[str, str], *, aad: Optional[Union[str, bytes, Dict[str, Any]]] = None) -> str:
    return aesgcm_decrypt(env, aad=aad).decode("utf-8")
