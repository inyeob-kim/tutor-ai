from fastapi import APIRouter
from .students import router as students_router
from .courses import router as courses_router
from .sessions import router as sessions_router

api_router = APIRouter()
api_router.include_router(students_router)
api_router.include_router(courses_router)
api_router.include_router(sessions_router)
