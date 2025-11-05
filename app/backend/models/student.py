from sqlalchemy import Column, Integer, String, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from .base import BaseModel

class Student(Base, BaseModel):
    __tablename__ = "students"

    user_id = Column(Integer, ForeignKey("users.id"))
    name = Column(String, index=True)
    total_sessions = Column(Integer, default=0)
    used_sessions = Column(Integer, default=0)

    user = relationship("User", back_populates="students")
    schedules = relationship("Schedule", back_populates="student")

    @property
    def remaining_sessions(self):
        return self.total_sessions - self.used_sessions