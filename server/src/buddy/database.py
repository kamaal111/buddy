from typing import Any, Generator, Protocol

from sqlalchemy import Engine
from sqlmodel import create_engine

from buddy.conf import settings


class Databaseable(Protocol):
    engine: Engine


class BaseDatabase:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine


def create_db_and_tables(database: Databaseable) -> None: ...


class Database(BaseDatabase):
    def __init__(self) -> None:
        super().__init__(create_engine(settings.database_url, echo=True))


__database = Database()
create_db_and_tables(__database)


def get_database() -> Generator[Databaseable, Any, None]:
    yield __database
