# test_redis.py
from app.backend.core.redis import r

print(r.ping())  # True면 성공!