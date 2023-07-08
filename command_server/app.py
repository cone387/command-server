from fastapi import FastAPI
from command_server.command.app import router as command_router

app = FastAPI()
app.include_router(command_router, prefix="/", tags=["command"])


if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app)
