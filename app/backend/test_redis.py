# test_redis.py
from core.redis import r

print(r.ping())  # True면 성공!