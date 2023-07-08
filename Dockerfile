FROM python:3.11.4

MAINTAINER cone
USER root

ENV PROJECT_DIR /home/admin/command-server

copy . $PROJECT_DIR

WORKDIR $PROJECT_DIR

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN pip install -r requirements.txt

ENTRYPOINT gunicorn command_server.app:app -c gunicorn.py
