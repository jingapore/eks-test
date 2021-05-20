FROM public.ecr.aws/v8e9s2p2/python37-slim-buster:latest

#set ENV timezone for timestamping
WORKDIR /home
RUN mkdir backend
COPY . backend/
RUN ["chmod", "+x", "/home/backend/start.sh"]
RUN ["pip3", "install", "-r", "/home/backend/requirements.txt"]
CMD ["/home/backend/start.sh"]