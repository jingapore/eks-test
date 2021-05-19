# purpose of lambda function is to automate KubeCtl
# this function will be triggered by CodePipeline
# this function will run within a VPC subnet, so that EKS does not need a public endpoint

# define function

resource "aws_iam_role" "lambda" {
  name = "eks-test-lambda"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "lambda_put_job_to_codepipeline_and_access_eks" {
  name   = "lambda-put-job-to-codepipeline-and-access-eks"
  policy = <<-EOF
  {
    "Statement": [
      {
        "Action": [
          "codepipeline:PutJobSuccessResult",
          "codepipeline:PutJobFailureResult"
          ],
          "Effect": "Allow",
          "Resource": "*"
     },
     {
       "Action": "eks:*",
       "Effect": "Allow",
       "Resource": "*"
      }
    ],
    "Version": "2012-10-17"
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_put_job_to_codepipeline_and_access_eks" {
  policy_arn = aws_iam_policy.lambda_put_job_to_codepipeline_and_access_eks.arn
  role       = aws_iam_role.lambda.name
}

# build function by
# a) send it to CodeCommit
# b) trigger CodeBuild
# we build function remotely, because we do not wish to reply on local tooling machine 
# to have necessary packages.

locals {
  lambda_apppy_base64           = filebase64("${path.module}/lambda/app.py")
  lambda_dockerfile_base64      = filebase64("${path.module}/lambda/Dockerfile")
  lambda_buildspecyml_base64    = filebase64("${path.module}/lambda/buildspec.yml")
  lambda_requirementstxt_base64 = filebase64("${path.module}/lambda/requirements.txt")
}

resource "aws_codecommit_repository" "eks_test_lambda" {
  repository_name = "eks-test-lambda"
  description     = "repository for code that will build lambda function"
  default_branch  = "main"
  tags = {
    Name = "codecommit-ekstest-lambda"
  }

  # the reason behind using aws codecommit instead of git 
  # is how this reduces complexity required on tooling machine, 
  # e.g. no need to install git, or to even run git init.
  # but even when using codecommit, there is a  need for tooling machine to parse json 
  # using jq. so the reason for using aws codecommit is not watertight.
  provisioner "local-exec" {
    command = <<-EOT
    aws codecommit put-file --repository-name ${aws_codecommit_repository.eks_test_lambda.repository_name} \
    --branch-name main --file-path lambda/app.py \
    --file-content ${local.lambda_apppy_base64} \
    --commit-message 'Scripts to build function that will run Kubectl.' && \
    aws codecommit put-file --repository-name ${aws_codecommit_repository.eks_test_lambda.repository_name} \
    --branch-name main --file-path lambda/Dockerfile \
    --file-content ${local.lambda_dockerfile_base64} \
    --parent-commit-id `aws codecommit get-branch --repository-name=eks-test-lambda --branch-name main | jq -r '.branch.commitId'` \
    --commit-message 'Dockerfile for function that will run Kubectl.' && \
    aws codecommit put-file --repository-name ${aws_codecommit_repository.eks_test_lambda.repository_name} \
    --branch-name main --file-path lambda/buildspec.yml \
    --file-content ${local.lambda_buildspecyml_base64} \
    --parent-commit-id `aws codecommit get-branch --repository-name=eks-test-lambda --branch-name main | jq -r '.branch.commitId'` \
    --commit-message 'buildspec for lambda image.' && \
    aws codecommit put-file --repository-name ${aws_codecommit_repository.eks_test_lambda.repository_name} \
    --branch-name main --file-path lambda/requirements.txt \
    --file-content ${local.lambda_requirementstxt_base64} \
    --parent-commit-id `aws codecommit get-branch --repository-name=eks-test-lambda --branch-name main | jq -r '.branch.commitId'` \
    --commit-message 'requirements to load into Python runtime.'
    EOT
    environment = {
      AWS_PROFILE = var.aws_profile
    }
  }
}

resource "aws_codepipeline" "lambda_codepipeline" {
  name = "lambda-codepipeline"
  # sharing same role as main codepipeline
  role_arn = aws_iam_role.codepipeline.arn

  # sharing same bucket as main codepipeline
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  # under stage/action's output_artifacts, we use abbreviated name, 
  # e.g. "source" instead of "source_output". 
  # this is because AWS truncates the s3 bucket key for the dir.
  # according to the forums, this is to ensure that the s3 key meets s3 policies, 
  # after appending the hash.

  stage {
    name = "Source"
    action {
      name             = "Source"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.eks_test_lambda.repository_name
        BranchName           = "main"
        PollForSourceChanges = true
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      version          = "1"

      configuration = {
        ProjectName          = aws_codebuild_project.build_lambda_image.name
        EnvironmentVariables = "[{\"name\":\"COMMIT_ID\",\"value\":\"#{SourceVariables.CommitId}\",\"type\":\"PLAINTEXT\"}]"
      }
    }
  }

}

resource "aws_codebuild_project" "build_lambda_image" {
  name          = "BuildLambdaImage"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild.arn

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "lambda/buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}

resource "aws_ecr_repository" "lambda" {
  name                 = "lambda"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "time_sleep" "wait_300_seconds" {
  depends_on      = [aws_codepipeline.lambda_codepipeline, aws_codecommit_repository.eks_test_lambda]
  create_duration = "300s"
}

resource "null_resource" "get_lambda_commit_id" {
  provisioner "local-exec" {
    command = <<-EOT
    aws ecr describe-images --repository-name lambda \
    --query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[0]' | \
    sed -e 's/^"//' -e 's/"$//' | \
    tr -d "\n" > lambda/lambda-commit-id.txt
    EOT
  }
  depends_on = [time_sleep.wait_300_seconds, aws_codepipeline.lambda_codepipeline, aws_codecommit_repository.eks_test_lambda]
}

data "local_file" "lambda_commit_id" {
  filename   = "${path.module}/lambda/lambda-commit-id.txt"
  depends_on = [null_resource.get_lambda_commit_id]
}

resource "aws_lambda_function" "deploy_kubernetes" {
  image_uri     = "${var.aws_account_id}.dkr.ecr.ap-southeast-1.amazonaws.com/lambda:${data.local_file.lambda_commit_id.content}"
  function_name = "deploy_kubernetes"
  role          = aws_iam_role.lambda.arn
  package_type  = "Image"
  timeout       = 900
  environment {
    variables = {
      AWS_ACCOUNT_ID  = var.aws_account_id
      LAMBDA_ROLE_ARN = aws_iam_role.lambda.arn
    }
  }
}
