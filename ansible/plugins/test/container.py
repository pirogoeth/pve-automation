def dict_contains(container: dict, key: str) -> bool:
    return key in container


class TestModule(object):
    def tests(self):
        return {
            "dict_contains": dict_contains,
        }