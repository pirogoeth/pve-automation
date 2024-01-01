class FilterModule(object):
    def filters(self):
        return {
            "all": all,
            "any": any,
        }