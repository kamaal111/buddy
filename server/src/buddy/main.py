from fastapi import FastAPI

from buddy.auth.router import auth_router
from buddy.health.router import health_router

app = FastAPI()


app.include_router(health_router)
app.include_router(auth_router)
