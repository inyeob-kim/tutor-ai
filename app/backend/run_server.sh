#!/bin/bash
# 개발 서버 실행 스크립트 (상세 로그 포함)

uvicorn app.backend.main:app \
    --reload \
    --host 0.0.0.0 \
    --port 8000 \
    --log-level debug \
    --access-log \
    --use-colors

