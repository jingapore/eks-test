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

## Structure of modules

### 1_network-resources

### 2_kubernetes-cluster
This initialises the cluster, as well as the node group.

### 3_cicd_resources
This creates two CodePipelines.
- CodePipeline 1: To build image for Lambda function.
- CodePipeline 2: To build new app images detected by changes to CodeCommit, and to update Kubernetes deployment accordingly using Lambda function.

### 4_kubernetes-deployment-and-service
This uses Terraform to provision Kubernetes Deployments and Kubernetes Services.

I had contemplated provisioning the abovementioned via the Lambda function in `3_cicd_resources`. But this would lead to issues destroying AWS resources, in particular the Kubernetes Services' AWS loadbalancers and target groups.

Hence, I opted to stick to Terraform to provision the abovementioned.

There are a few *things to note* when running this module.
1. This module is only run once, to create the initial deployments and services. Subsequent changes are handled by a Lambda function in `3_cicd_resources`.
2. Before running this module, there is a need to re-init Terraform because the Kubernetes provider needs to get data.

# General points
## Working with Lambda functions

To run using emulator, run this command:

```
docker run -d -v ~/.aws-lambda-rie:/aws-lambda -p 9000:8080 \
--entrypoint /aws-lambda/aws-lambda-rie \
lambda:latest \
/usr/local/bin/python -m awslambdaric app.handler
```

# Gotchas to watch out for

Be careful not to run `3_cicd-resources` when virtualenv is running, because the aws executable called will be different from what is otherwise running on your local machine.

The result of runnning virtualenv on my computer, is that the command `aws codecommit` does not upload the decoded base64 representation. Rather, the raw base64 representation goes into CodeCommit. This may in fact be OK, but could be due to the different aws executables being called.