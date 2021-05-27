resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster"

  assume_role_policy = <<-EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

data "aws_subnet_ids" "web" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*web*"
  }
}

data "aws_subnet_ids" "app" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*app*"
  }
}

data "aws_subnet_ids" "db" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*db*"
  }
}

data "aws_subnet_ids" "private_total" {
  vpc_id = var.vpc_id

  tags = {
    Name = "eks-test-sub-*-*"
    Tier = "Private"
  }
}

data "aws_subnet_ids" "total" {
  vpc_id = var.vpc_id

  tags = {
    Name = "eks-test-sub-*-*"
  }
}

data "aws_subnet" "total" {
  for_each = data.aws_subnet_ids.total.ids
  id       = each.value
}

# # this is used for security group for vpcendpoints (except s3)
# data "aws_subnet" "web" {
#   for_each = data.aws_subnet_ids.web.ids
#   id       = each.value
# }

resource "aws_eks_cluster" "aws_eks" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    # to turn public access off after module 3
    # in the meantime, while public access is allowed 
    # to only allow whitelisted IPs
    subnet_ids              = data.aws_subnet_ids.total.ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.eks_public_access_cidrs
  }

  tags = {
    Name = "eks-cluster-app-subnets"
  }
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group"

  assume_role_policy = <<-EOF
    {
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
        }
    ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# # launch template for frontend
# # we use a launch template to augment default template, 
# # so that we can change the instance size, and also 
# # tag the instance
# resource "aws_launch_template" "node_group_frontend" {
#   name = "node_group_frontend"

#   instance_type = "t3.micro"

#   tag_specifications {
#     resource_type = "instance"

#     tags = {
#       Name = "eks-test-node-frontend"
#     }
#   }
# }

# resource "aws_eks_node_group" "frontend" {
#   cluster_name    = aws_eks_cluster.aws_eks.name
#   node_group_name = "app_frontend_group"
#   node_role_arn   = aws_iam_role.eks_nodes.arn
#   subnet_ids      = data.aws_subnet_ids.app.ids
#   launch_template {
#     id      = aws_launch_template.node_group_frontend.id
#     version = aws_launch_template.node_group_frontend.latest_version
#   }

#   scaling_config {
#     desired_size = 1
#     max_size     = 1
#     min_size     = 1
#   }

#   labels = {
#     app = "frontend"
#   }

#   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
#   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
#   depends_on = [
#     aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
#   ]
# }

# launch template for backend
# we use a launch template to augment default template, 
# so that we can change the instance size, and also 
# tag the instance
resource "aws_launch_template" "node_group_backend" {
  name = "node_group_backend"

  instance_type = "t3.small"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "eks-test-node-backend"
    }
  }
}

resource "aws_eks_node_group" "backend" {
  cluster_name    = aws_eks_cluster.aws_eks.name
  node_group_name = "app_backend_group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = data.aws_subnet_ids.app.ids

  launch_template {
    id      = aws_launch_template.node_group_backend.id
    version = aws_launch_template.node_group_backend.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  labels = {
    app = "backend"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
