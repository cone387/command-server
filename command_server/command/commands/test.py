
from command_server.command.base import Command, BaseCommand


@Command.register()
class TestCommand(BaseCommand):
    name = "test"

    def execute(self, name: str = None):
        return f"Hello {name}"
