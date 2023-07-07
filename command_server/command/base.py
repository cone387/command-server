from typing import Optional, Dict
from cone.utils.classes import ClassManager
from enum import IntEnum
from pydantic import BaseModel


Command = ClassManager(
    name="Command",
    path=[
       "command_server.command.commands",
    ],
    unique_keys=['name'],
)


class CommandStatus(IntEnum):
    DEVELOPING = 0
    AVAILABLE = 1
    STOPPED = 2


class BaseCommandModel(BaseModel):
    name: str
    description: Optional[str]
    status: Optional[CommandStatus] = CommandStatus.AVAILABLE
    kwargs: Optional[Dict] = None


class BaseCommand:
    status = CommandStatus.AVAILABLE
    name: str = None
    description: str = None
    model: BaseCommandModel = BaseCommandModel

    def execute(self, **kwargs):
        raise NotImplementedError
