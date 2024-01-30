FROM python:3.12.1-alpine3.19
RUN apk add --no-cache py3-pip
RUN pip install redis
RUN pip install requests
RUN pip install minio
