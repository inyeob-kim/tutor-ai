# app/core/redis.py
import redis
import json
from typing import List, Dict

r = redis.Redis(host='localhost', port=6379, db=0, decode_responses=True)

def save_conversation(session_id: str, messages: List[Dict], ttl: int = 3600):
    r.setex(session_id, ttl, json.dumps(messages))

def get_conversation(session_id: str) -> List[Dict]:
    data = r.get(session_id)
    return json.loads(data) if data else []

def clear_conversation(session_id: str):
    r.delete(session_id)