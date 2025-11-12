from fastapi import APIRouter
from .students import router as students_router
from .teachers import router as teachers_router
from .schedules import router as schedules_router
from .categories import router as categories_router
from .subjects import router as subjects_router

api_router = APIRouter()
api_router.include_router(students_router)
api_router.include_router(teachers_router)
api_router.include_router(schedules_router)
api_router.include_router(categories_router)
api_router.include_router(subjects_router)

