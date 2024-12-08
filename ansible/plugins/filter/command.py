import shutil

class FilterModule(object):
    def filters(self):
        return {
            "which": shutil.which,
        }

