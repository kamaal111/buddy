from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, Form
from pydantic import EmailStr

from buddy.auth.controller import AuthControllable, get_auth_controller
from buddy.auth.schemas import LoginResponse, RegisterResponse
from buddy.schemas import ErrorResponse

auth_router = APIRouter(prefix="/auth")


@auth_router.post(
    "/register",
    status_code=HTTPStatus.CREATED,
    responses={
        HTTPStatus.CREATED: {
            "model": RegisterResponse,
            "description": "Return whether the user account has been created successfully.",
        },
        HTTPStatus.CONFLICT: {
            "model": ErrorResponse,
            "description": "Provided user credentials already exist.",
        },
        HTTPStatus.UNPROCESSABLE_ENTITY: {
            "model": ErrorResponse,
            "description": "Invalid payload provided.",
        },
    },
)
def register(
    email: Annotated[EmailStr, Form()],
    password: Annotated[str, Form()],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
) -> RegisterResponse:
    return controller.register(email=email, password=password)


@auth_router.post(
    "/login",
    status_code=HTTPStatus.OK,
    responses={
        HTTPStatus.OK: {
            "model": LoginResponse,
            "description": "Return the access token of the user logging in.",
        },
        HTTPStatus.UNAUTHORIZED: {
            "model": ErrorResponse,
            "description": "Invalid credentials provided.",
        },
        HTTPStatus.UNPROCESSABLE_ENTITY: {
            "model": ErrorResponse,
            "description": "Invalid payload provided.",
        },
    },
)
def login(
    email: Annotated[EmailStr, Form()],
    password: Annotated[str, Form()],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
) -> LoginResponse:
    return controller.login(email=email, password=password)
