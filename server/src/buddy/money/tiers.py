from enum import auto

from buddy.utils.enum_utils import AutoNameEnum


class UserTiers(str, AutoNameEnum):
    FREE = auto()

    @staticmethod
    def get_by_key(key: str):
        tier = UserTiers.__members__.get(key)
        if tier is None:
            return None

        return tier

    @staticmethod
    def get_choices() -> list[tuple[str, str]]:
        choices = []
        for key, tier in UserTiers.__members__.items():
            assert isinstance(tier.name, str)
            choices.append((key, tier.name))

        assert len(choices) > 0
        assert choices[0][0] == "FREE"

        return choices
