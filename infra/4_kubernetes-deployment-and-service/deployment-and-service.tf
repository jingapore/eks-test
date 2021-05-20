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
          image = "126966121768.dkr.ecr.ap-southeast-1.amazonaws.com/backend-repo:7bf43cd33ff1239e36b6d2cff76117fcfbdd3a6b"
          # image = "${var.aws_account_id}.dkr.ecr.ap-southeast-1.amazonaws.com/backend-repo:${var.backend_commit_id}"
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
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
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