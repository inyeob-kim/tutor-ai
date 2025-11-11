from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.backend.routers.student_router import router as students_router

app = FastAPI(title="Tutor API", version="0.1.0")

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
