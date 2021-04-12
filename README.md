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
The `AWS_PROFILE` on your machine is "default".

## Things that you will have to set up without IAC
IAM user with admin privileges. You will also have to use AWS console to generate and download Git credentials to push app code (chief of all Docker image) to CodeCommit.

S3 bucket for storing state. In this repo, we hard-code the bucket name is "ekstest-terraformstatebucket". But you may not be able to create this bucket. If so, rename the hard coded name.