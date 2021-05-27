resource "kubernetes_namespace" "eks_test" {
  metadata {
    name = "eks-test"
  }
}

resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.eks_test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        #which nodes to deploy on
        app = "backend"
      }
    }
    template {
      metadata {
        labels = {
          #what to label the pods with
          app = "backend" 
        }
      }
      spec {
        container {
          image = "${var.aws_account_id}.dkr.ecr.ap-southeast-1.amazonaws.com/backend-repo:${var.backend_commit_id}"
          image_pull_policy = "Always"
          name  = "backend-container"
          port {
            container_port = 5000
          }
          env_from {
            config_map_ref {
              name = "backend-config"
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.backend]
}
  
resource "kubernetes_service" "backend" {
  metadata {
    name = "backend-balancer"
    namespace = kubernetes_namespace.eks_test.metadata.0.name
    annotations = {
      # References:
      # https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
      # https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/guide/service/annotations/
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-name" = "eks-test-nlb"
      "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type" = "instance"
      "service.beta.kubernetes.io/aws-load-balancer-scheme": "internet-facing"
      "service.beta.kubernetes.io/aws-load-balancer-subnets": "${var.public_subnet_az_a_id}, ${var.public_subnet_az_b_id}"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.backend.spec.0.template.0.metadata.0.labels.app
    }
    session_affinity = "None"
    port {
      port        = 8080
      target_port = 5000
    }
    cluster_ip = var.backend_balancer_ip

    type = "LoadBalancer"
  }
  wait_for_load_balancer = "true"
}