from http import HTTPStatus
from typing import Annotated

from fastapi import APIRouter, Depends

from buddy.llm.controller import LLMControllable, get_llm_controller
from buddy.llm.schemas import ModelsResponse

llm_router = APIRouter(prefix="/llm")


@llm_router.get(
    "/models",
    status_code=HTTPStatus.OK,
    responses={
        HTTPStatus.OK: {
            "model": ModelsResponse,
            "description": "Return models available to the user.",
        },
    },
)
async def models(
    controller: Annotated[LLMControllable, Depends(get_llm_controller)],
) -> ModelsResponse:
    return await controller.models()
