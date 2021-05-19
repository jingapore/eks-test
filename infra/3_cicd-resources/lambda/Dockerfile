# reference: https://github.com/aws-samples/aws-lambda-layer-kubectl/blob/master/Dockerfile
# but do not install helm.

# edited following from "public.ecr.aws/lambda/provided:latest" 
# to "public.ecr.aws/lambda/python:3.8".
FROM public.ecr.aws/lambda/python:3.8

# most updated version of KUBECTL available on s3 is stated here:
# https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
ARG KUBECTL_VERSION=1.19.6/2021-01-05

COPY app.py requirements.txt ./
RUN pip install -r requirements.txt

CMD ["app.handler"]