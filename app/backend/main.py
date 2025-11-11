import logging
import traceback
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from sqlalchemy.exc import SQLAlchemyError
from app.backend.routers.student_router import router as students_router
from app.backend.routers.teacher_router import router as teachers_router
from app.backend.routers.schedule_router import router as schedules_router
from app.backend.routers.invoice_router import router as invoices_router

# 로깅 설정
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(),
    ]
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Tutor API", version="0.1.0", debug=True)

# 전역 예외 핸들러
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """모든 예외를 처리하여 상세한 오류 메시지 반환"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": str(exc),
            "type": type(exc).__name__,
            "traceback": traceback.format_exc() if app.debug else None,
        }
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """요청 검증 오류 처리"""
    logger.error(f"Validation error: {exc.errors()}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "detail": exc.errors(),
            "body": exc.body,
        }
    )

@app.exception_handler(SQLAlchemyError)
async def sqlalchemy_exception_handler(request: Request, exc: SQLAlchemyError):
    """SQLAlchemy 오류 처리"""
    logger.error(f"Database error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "detail": f"Database error: {str(exc)}",
            "type": type(exc).__name__,
        }
    )

# 헬스체크
@app.get("/healthz")
def health():
    return {"ok": True}

# 🔐 프론트 도메인/포트 맞추기
origins = [
    "http://localhost:5173",   # Vite
    "http://localhost:3000",   # CRA/Next
]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],       # 필요시 ["GET","POST","PATCH","DELETE"]
    allow_headers=["*"],
)

# 라우터 등록
app.include_router(students_router)
app.include_router(teachers_router)
app.include_router(schedules_router)
app.include_router(invoices_router)
