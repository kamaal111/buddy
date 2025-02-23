from typing import Any, Generator, Protocol

from sqlalchemy import Engine
from sqlmodel import SQLModel, create_engine

from buddy.conf import settings


class Databaseable(Protocol):
    engine: Engine


class BaseDatabase:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine


def create_db_and_tables(database: Databaseable) -> None:
    from buddy.auth.models import User, UserToken  # noqa: F401

    SQLModel.metadata.create_all(database.engine)


class Database(BaseDatabase):
    def __init__(self) -> None:
        engine = create_engine(settings.database_url, echo=True)

        super().__init__(engine=engine)


__database = Database()
create_db_and_tables(__database)


def get_database() -> Generator[Databaseable, Any, None]:
    yield __database
