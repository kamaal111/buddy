from collections import OrderedDict

_USER_TIERS = OrderedDict([("FREE", "FREE")])


class UserTiers:
    @staticmethod
    def get_by_key(key: str):
        return _USER_TIERS[key]

    @staticmethod
    def get_choices():
        return list(_USER_TIERS.items())
