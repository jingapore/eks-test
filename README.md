# Purpose
Demo CICD using Kubernetes with with:
- Repo as CodeCommit;
- Pipeline and build as CodePipeline and CodeBuild; and
- Kubernetes orchestrator as EKS.

# Outcome
A public endpoint that returns a website defined in a Docker image.

# Directory structure
`infra` dir for Terraform scripts.

`app` dir for Docker images.

# infra dir

## Things that we assume
Your local machine has:
- aws cli installed;
- sed installed.

The above requirements are due to running of local-exec provisioner, to bootstrap certain components.

## Things that you will have to set up without IAC
IAM user with admin privileges. You will also have to use AWS console to generate and download Git credentials to push app code (chief of all Docker image) to CodeCommit.

S3 bucket for storing state. In this repo, we hard-code the bucket name is "ekstest-terraformstatebucket". But you may not be able to create this bucket. If so, rename the hard coded name.

# Lambda function

To run using emulator, run this command:

```
docker run -d -v ~/.aws-lambda-rie:/aws-lambda -p 9000:8080 \
--entrypoint /aws-lambda/aws-lambda-rie \
lambda:latest \
/usr/local/bin/python -m awslambdaric app.handler
```