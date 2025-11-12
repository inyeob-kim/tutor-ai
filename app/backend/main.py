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
from app.backend.routers.ai_router import router as ai_router

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

# 전역 예외 핸들러는 Swagger UI와 충돌할 수 있으므로 제거
# 대신 필요한 경우에만 특정 예외 타입을 처리
# @app.exception_handler(Exception)  # 주석 처리 - Swagger UI 호환성

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
# 개발 환경: 모든 localhost 포트 허용 (Flutter 웹 앱은 매번 다른 포트 사용)
origins = [
    "http://localhost:5173",   # Vite
    "http://localhost:3000",   # CRA/Next
]

# 개발 환경에서는 모든 localhost 포트 허용
if app.debug:
    # localhost의 모든 포트 허용 (개발 환경)
    # 정규식 패턴: http://localhost:포트번호
    origin_regex = r"http://localhost:\d+"
    app.add_middleware(
        CORSMiddleware,
        allow_origin_regex=origin_regex,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=["*"],
    )
    logger.info("CORS: Development mode - Allowing all localhost ports")
else:
    # 프로덕션 환경: 특정 origin만 허용
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

# 라우터 등록
app.include_router(students_router)
app.include_router(teachers_router)
app.include_router(schedules_router)
app.include_router(invoices_router)
app.include_router(ai_router)
