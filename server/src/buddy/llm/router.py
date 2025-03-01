from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends

from buddy.llm.controller import LLMControllable, get_llm_controller
from buddy.llm.schemas import ChatPayload, ChatResponse
from buddy.schemas import ErrorResponse

llm_router = APIRouter(prefix="/llm")


@llm_router.post(
    "/chat",
    status_code=HTTPStatus.OK,
    responses={
        HTTPStatus.OK: {
            "model": ChatResponse,
            "description": "Return the chat response after sending a message.",
        },
        HTTPStatus.FORBIDDEN: {
            "model": ErrorResponse,
            "description": "Forbidden LLM has been selected",
        },
    },
)
def chat(
    payload: ChatPayload,
    controller: Annotated[LLMControllable, Depends(get_llm_controller)],
) -> ChatResponse:
    return controller.chat(payload)
