from fastapi import APIRouter


health_router = APIRouter(prefix="/health")


@health_router.get("/ping")
async def ping():
    return {"message": "PONG"}
