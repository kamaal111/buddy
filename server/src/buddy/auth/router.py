from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, Form, Header
from pydantic import EmailStr

from buddy.auth.controller import AuthControllable, get_auth_controller
from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.auth.schemas import (
    LoginResponse,
    RefreshPayload,
    RefreshResponse,
    RegisterResponse,
    SessionResponse,
)
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
async def register(
    email: Annotated[EmailStr, Form()],
    password: Annotated[str, Form()],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
) -> RegisterResponse:
    return await controller.register(email=email, password=password)


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
async def login(
    email: Annotated[EmailStr, Form()],
    password: Annotated[str, Form()],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
) -> LoginResponse:
    return await controller.login(email=email, password=password)


@auth_router.get(
    "/session",
    status_code=HTTPStatus.OK,
    responses={
        HTTPStatus.OK: {
            "model": SessionResponse,
            "description": "Return the session data for the user that is logged in.",
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
async def session(
    user: Annotated[User, Depends(get_request_user)],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
):
    return await controller.session(user=user)


@auth_router.post(
    "/refresh",
    status_code=HTTPStatus.OK,
    responses={
        HTTPStatus.OK: {
            "model": RefreshResponse,
            "description": "Return the refresh token for the user that is logged in.",
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
async def refresh(
    payload: RefreshPayload,
    authorization: Annotated[str, Header()],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
):
    return await controller.refresh(
        refresh_token=payload.refresh_token,
        authorization=authorization,
    )
