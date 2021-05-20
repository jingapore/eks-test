# allow lambda in 3_cicd-resources to make changes

# resource "kubernetes_config_map" "aws_auth" {
#   metadata {
#     namespace = "kube-system"
#     name      = "aws-auth"
#   }

#   data = {
#     mapRoles = <<-EOF
#     - rolearn: arn:aws:iam::${var.aws_account_id}:role/eks-node-group
#       username: system:node:{{EC2PrivateDNSName}}
#       groups:
#         - system:bootstrappers
#         - system:nodes
#     - rolearn: arn:aws:iam::${var.aws_account_id}:role/${aws_iam_role.lambda.name}
#       username: ${aws_iam_role.lambda.name}
#       groups:
#         - system:masters
#     EOF
#   }
# }

resource "null_resource" "k8s_patcher" {
  # reference: https://github.com/hashicorp/terraform-provider-kubernetes/issues/723
  # download kubectl and patch the default namespace
  provisioner "local-exec" {
    command = <<-EOH
    cat >/tmp/kube_ca.crt <<-EOF
    ${base64decode(data.aws_eks_cluster.default.certificate_authority.0.data)}
    EOF
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && \
    echo "https://${data.aws_eks_cluster.default.endpoint}" && \
    chmod +x ./kubectl
    ./kubectl \
    --server="${data.aws_eks_cluster.default.endpoint}" \
    --token="${data.aws_eks_cluster_auth.default.token}" \
    --certificate-authority=/tmp/kube_ca.crt \
    -n kube-system \
    patch configmap/aws-auth --patch "${data.template_file.auth_config_new.rendered}"
    EOH
  }
}

data "template_file" "auth_config_new" {
  template = file("${path.module}/auth-config-new.yaml")
  vars = {
    aws_iam_role_lambda_name = aws_iam_role.lambda.name
    var_aws_account_id = var.aws_account_id
  }
}