from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends

from buddy.llm.controller import LLMControllable, get_llm_controller
from buddy.llm.schemas import CreateChatMessagePayload, CreateChatMessageResponse
from buddy.schemas import ErrorResponse

llm_router = APIRouter(prefix="/llm")


@llm_router.post(
    "/chats",
    status_code=HTTPStatus.CREATED,
    responses={
        HTTPStatus.CREATED: {
            "model": CreateChatMessageResponse,
            "description": "Return the chat response after sending a message.",
        },
        HTTPStatus.FORBIDDEN: {
            "model": ErrorResponse,
            "description": "Forbidden LLM has been selected",
        },
        HTTPStatus.INTERNAL_SERVER_ERROR: {
            "model": ErrorResponse,
            "description": "Something unexpected went wrong",
        },
    },
)
def create_chat_message(
    payload: CreateChatMessagePayload,
    controller: Annotated[LLMControllable, Depends(get_llm_controller)],
) -> CreateChatMessageResponse:
    return controller.create_chat_message(payload)
