from fastapi import FastAPI, Request
from pydantic import ValidationError

from buddy.app_api.router import app_api_router
from buddy.exceptions import BuddyValidationError
from buddy.health.router import health_router

app = FastAPI()


@app.exception_handler(ValidationError)
async def unicorn_exception_handler(_: Request, exc: ValidationError):
    raise BuddyValidationError(exc) from exc


app.include_router(health_router)
app.include_router(app_api_router)
