FROM python:3.8-slim-buster

#set ENV timezone for timestamping
ENV TZ Asia/Singapore

WORKDIR /home

RUN mkdir backend_app
COPY backend/ backend_app/

# COPY ["requirements.txt", "start.sh"]

# RUN ["chmod", "+x", "start.sh"]

# # install dependencies
# RUN apt-get update && \
#     apt-get upgrade -y && \
#     apt-get install -y netcat-openbsd gcc libpq-dev python3-dev redis-server && \
#     apt-get install libsasl2-dev libldap2-dev libssl-dev && \
#     apt-get clean

# RUN pip3 install -r requirements.txt

# CMD ["./start.sh"]