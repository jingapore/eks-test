# definition fo codepipeline iam roles and config.
# also include s3 bucket and codecommit resources, 
# where s3 bucket is used to store output from codepipeline, 
# and codecommit is the source.

resource "aws_s3_bucket" "codepipeline_bucket" {
  # verbose bucket name to achieve uniqueness, which is required
  bucket = "codepipeline-bucket-for-eks-test"
  acl    = "private"
  versioning {
    enabled = false
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "codepipeline"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "codepipeline.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "codepipeline" {
  name   = "codepipeline"
  policy = <<-EOF
  {
    "Statement": [
      {
        "Sid": "AllowS3ObjectAccessOnCodePipelineBuckets",
        "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
        ],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Sid": "AllowCodeBuildActions",
        "Action": [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Sid": "AllowCodeCommitActions",
        "Action": [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",      
          "codecommit:CancelUploadArchive"
        ],
        "Resource": "*",
        "Effect": "Allow"
      },
      {
        "Sid": "AllowLambdaActions",
        "Action": [
          "lambda:InvokeFunction",
          "lambda:ListFunctions"
        ],
        "Resource": "*",
        "Effect": "Allow"
      }
    ],
    "Version": "2012-10-17"
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline_attachment" {
  role       = aws_iam_role.codepipeline.name
  policy_arn = aws_iam_policy.codepipeline.arn
}

resource "aws_s3_bucket_policy" "codepipeline_bucket_policy" {
  # this bucket is used by 2 codepipelines: 
  # (1) for main, (2) for lambda image.
  # but there is no need to give separate permissions for each pipeline, 
  # because the roles of both CodePipeline and CodeBuild are the same.
  bucket = aws_s3_bucket.codepipeline_bucket.id
  policy = <<-EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Principal": "*",
              "Effect": "Deny",
              "Action": [
                  "s3:*"
              ],
              "Resource": "${aws_s3_bucket.codepipeline_bucket.arn}/*",
              "Condition": {
                  "StringNotLike": {
                      "aws:userid": [
                          "${aws_iam_role.codepipeline.unique_id}:*",
                          "${aws_iam_role.codebuild.unique_id}:*",
                          "${var.terraform_iam_identifier}"
                      ]
                  }
              }
          }
      ]
  }
  EOF
}

resource "aws_codepipeline" "codepipeline" {
  name     = "codepipeline"
  role_arn = aws_iam_role.codepipeline.arn

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
        RepositoryName       = aws_codecommit_repository.eks_test.repository_name
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
        ProjectName          = aws_codebuild_project.build_docker_image.name
        EnvironmentVariables = "[{\"name\":\"COMMIT_ID\",\"value\":\"#{SourceVariables.CommitId}\",\"type\":\"PLAINTEXT\"}]"
      }
    }
  }

  stage {
    name = "Invoke"

    action {
      name     = "Invoke"
      category = "Invoke"
      owner    = "AWS"
      provider = "Lambda"
      version  = "1"

      configuration = {
        FunctionName   = aws_lambda_function.deploy_kubernetes.function_name
        UserParameters = "#{SourceVariables.CommitId}"
      }
    }
  }
}


resource "aws_codecommit_repository" "eks_test" {
  repository_name = "eks-test"
  description     = "repository for code, including Docker images"
  default_branch  = "main"
  tags = {
    Name = "codecommit-ekstest"
  }
}

resource "aws_ecr_repository" "backend_repo" {
  name                 = "backend-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
