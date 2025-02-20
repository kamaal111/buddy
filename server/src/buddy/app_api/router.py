from fastapi import APIRouter

from buddy.auth.router import auth_router

app_api_router = APIRouter(prefix="/app-api/v1")

app_api_router.include_router(auth_router)
