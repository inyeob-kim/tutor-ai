from sqlalchemy import Column, Integer, String, Date, Time, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from .base import BaseModel

class Schedule(Base, BaseModel):
    __tablename__ = "schedules"

    user_id = Column(Integer, ForeignKey("users.id"))
    student_id = Column(Integer, ForeignKey("students.id"))
    google_event_id = Column(String, nullable=True)
    date = Column(Date)
    start_time = Column(Time)
    end_time = Column(Time)
    duration_minutes = Column(Integer)
    status = Column(String, default="confirmed")

    user = relationship("User", back_populates="schedules")
    student = relationship("Student", back_populates="schedules")