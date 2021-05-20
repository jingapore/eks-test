resource "aws_iam_role" "codebuild" {
  name               = "codebuild"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "codebuild.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "codebuild_put_image_to_ecr" {
  name        = "codebuild_to_ecr"
  description = "Policy for CodeBuild to put images to ECR."
  policy      = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "CodeBuildDefaultPolicy",
          "Effect": "Allow",
          "Action": [
            "codebuild:*",
            "iam:PassRole"
          ],
          "Resource": "*"      
        },
        {
          "Sid": "CloudWatchLogsAccessPolicy",
          "Effect": "Allow",
          "Action": [
            "logs:FilterLogEvents",
            "logs:GetLogEvents",
            "logs:PutLogEvents",
            "logs:CreateLogGroup",
            "logs:CreateLogStream"
          ],
          "Resource": "*"
        },
        {
            "Sid": "EnableCreationAndManagementOfCloudwatchLogGroupsAndStreams",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:DescribeLogStreams",
                "logs:PutRetentionPolicy",
                "logs:CreateLogGroup"
            ],
            "Resource": "*"
        },
        {
          "Sid": "S3AccessPolicy",
          "Effect": "Allow",
          "Action": [
            "s3:CreateBucket",
            "s3:GetObject",
            "s3:List*",
            "s3:PutObject"
          ],
          "Resource": "*"
        },
        {
          "Sid": "S3BucketIdentity",
          "Effect": "Allow",
          "Action": [
            "s3:GetBucketAcl",
            "s3:GetBucketLocation"
          ],
          "Resource": "*"
        }, 
        {
          "Sid": "PutImageToEcr",
          "Effect": "Allow",
          "Action": [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken"
          ],
          "Resource": "*"
        }
      ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuild_put_image_to_ecr.arn
}

resource "aws_codebuild_project" "build_docker_image" {
  name          = "BuildDockerImage"
  build_timeout = "30"
  service_role  = aws_iam_role.codebuild.arn

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = var.aws_account_id
    }
  }

  # buildspec is located in sub dir, where there are 2 subdirs: 
  # (1) infra, and (2) app. 
  # but within buildspec, the home is not the subdir (i.e. app) 
  # so you have to reference the full path from the root dir 
  # in the buildspec.

  source {
    type      = "CODEPIPELINE"
    buildspec = "app/buildspec.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }
}
