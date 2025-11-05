# app/database.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

# SQLite (MVP) — 나중에 PostgreSQL로 변경
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./tutor.db")

engine = create_engine(
    DATABASE_URL, 
    connect_args={"check_same_thread": False}  # SQLite only
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()