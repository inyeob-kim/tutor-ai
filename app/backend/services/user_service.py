from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorDatabase
from typing import Optional, Dict, Any
from ..models.user import User

async def upsert_social_user(
    db: AsyncIOMotorDatabase,
    *,
    provider: str,
    oauth_id: str,
    email: Optional[str],
    name: Optional[str],
    picture: Optional[str],
) -> User:
    now = datetime.now(timezone.utc)
    found = await db.users.find_one({"provider": provider, "oauth_id": oauth_id})
    if found:
        await db.users.update_one(
            {"_id": found["_id"]},
            {"$set": {"email": email, "name": name, "picture": picture, "last_login_at": now}},
        )
        found.update({"email": email, "name": name, "picture": picture, "last_login_at": now})
        return User(**found)

    doc: Dict[str, Any] = {
        "_id": f"usr_{int(now.timestamp()*1000)}",
        "provider": provider,
        "oauth_id": oauth_id,
        "email": email,
        "name": name,
        "picture": picture,
        "role": "tutor",
        "created_at": now,
        "last_login_at": now,
    }
    await db.users.insert_one(doc)
    return User(**doc)
