import json
import inspect
from fastapi import APIRouter
from command_server.command import Command, BaseCommand


router = APIRouter()


@router.get("/list/")
async def list_commands():
    commands = []
    for x in Command.values():
        schema = x.model.schema()
        required = schema["required"]
        kwargs_properties = {
            k: {
                "type": v.annotation.__name__,
                "default": v.default,
                "required": k in required,
            } for k, v in inspect.signature(x.execute).parameters.items()
        }
        kwargs_properties.pop("self", None)
        schema["properties"]["kwargs"]["properties"] = kwargs_properties
        commands.append({
            "name": x.name,
            "description": x.description,
            "scheme": schema,
        })
    return {
        "message": "%s commands found" % len(commands),
        "commands": commands
    }


@router.get("/execute/")
async def execute_command(name: str, kwargs: str = None):
    error, message = False, None
    if kwargs is not None:
        try:
            kwargs = json.loads(kwargs)
        except json.JSONDecodeError:
            error = True
            message = "Invalid JSON"
    else:
        kwargs = {}
    if not error:
        try:
            command: BaseCommand = Command(name=name, is_registry=False)
        except KeyError:
            message = f"Command not found"
        else:
            try:
                defined_kwargs = inspect.signature(command.execute).parameters
                for x in kwargs:
                    if x not in defined_kwargs:
                        raise TypeError(f"unknown kwarg {x}, available: {list(defined_kwargs.keys())}")
                result = command.execute(**kwargs)
            except Exception as e:
                message = str(e)
            else:
                return {
                    "status": "success",
                    "message": f"execute success",
                    "command": name,
                    "kwargs": kwargs,
                    "result": result
                }
    return {
        "status": "error",
        "message": message,
        "command": name,
        "kwargs": kwargs,
    }
