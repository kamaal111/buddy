import json

from sqlalchemy import ARRAY, JSON, String, TypeDecorator


class ArrayOfJSON(TypeDecorator):
    """Converts list to/from text when using SQLite."""

    impl = String

    cache_ok = True

    def load_dialect_impl(self, dialect):
        if dialect.name == "postgresql":
            return dialect.type_descriptor(ARRAY(JSON))
        else:
            return dialect.type_descriptor(String)

    def process_bind_param(self, value, dialect):
        if dialect.name == "postgresql":
            return value
        if value is not None:
            return json.dumps(value)

    def process_result_value(self, value, dialect):
        if dialect.name == "postgresql":
            return value
        if value is not None:
            return json.loads(value)
