from typing import Literal

from fastapi import APIRouter
from pydantic import BaseModel

health_router = APIRouter(prefix="/health")


class PingResponse(BaseModel):
    detail: Literal["PONG"]


@health_router.get("/ping")
async def ping() -> PingResponse:
    return PingResponse(detail="PONG")
