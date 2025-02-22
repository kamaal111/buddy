from datetime import datetime

from buddy.conf import settings


def datetime_now_with_timezone():
    return datetime.now(tz=settings.tzinfo)
