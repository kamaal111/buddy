from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends, Form, Header
from pydantic import EmailStr

from buddy.auth.controller import AuthControllable, get_auth_controller
from buddy.auth.middleware import get_request_user
from buddy.auth.models import User
from buddy.auth.schemas import (
    LoginResponse,
    RefreshHeaders,
    RefreshPayload,
    RefreshResponse,
    RegisterResponse,
    SessionHeaders,
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
def session(
    headers: Annotated[SessionHeaders, Header()],
    user: Annotated[User | None, Depends(get_request_user)],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
):
    return controller.session(user=user)


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
def refresh(
    payload: RefreshPayload,
    headers: Annotated[RefreshHeaders, Header()],
    user: Annotated[User | None, Depends(get_request_user)],
    controller: Annotated[AuthControllable, Depends(get_auth_controller)],
):
    return controller.refresh(
        user=user,
        refresh_token=payload.refresh_token,
        access_token=headers.authorization,
    )
