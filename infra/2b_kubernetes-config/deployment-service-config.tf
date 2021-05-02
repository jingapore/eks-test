provider "aws" {
   profile    = var.aws_profile
   region     = "ap-southeast-1"
 }

terraform {
  backend "s3" {
  }
}

#section to get the subnet ids. This should be in the var file once subnets are fixed.
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

data "aws_subnet_ids" "total" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*dsa*"
  }
}

data "aws_subnet_ids" "subset" {
  vpc_id = var.vpc_id

  tags = {
    Name = "*app*"
  }
}

data "aws_subnet" "total" {
  for_each = data.aws_subnet_ids.total.ids
  id       = each.value
}



data "aws_eks_cluster" "default" {
  #get from var
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "default" {
  name = var.eks_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority.0.data)
  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name]
    command     = "aws"
  }
}


resource "kubernetes_namespace" "coi" {
  metadata {
    name = "coi"
  }
}

resource "kubernetes_deployment" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace.coi.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        #which nodes to deploy on
        app = "frontend"
      }
    }
    template {
      metadata {
        labels = {
          #what to label the pods with
          app = "frontend" 
        }
      }
      spec {
        container {
          image = "409547615589.dkr.ecr.ap-southeast-1.amazonaws.com/frontend-repo:1.0"
          image_pull_policy = "Always"
          name  = "frontend-container"
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = "frontend-config"
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.frontend]
}

  
resource "kubernetes_service" "frontend" {
  metadata {
    name = "frontend-balancer"
    namespace = kubernetes_namespace.coi.metadata.0.name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.frontend.spec.0.template.0.metadata.0.labels.app
    }
    session_affinity = "None"
    port {
      port        = 8080
      target_port = 3000
    }
    cluster_ip = var.frontend_balancer_ip

    type = "LoadBalancer"
  }
  wait_for_load_balancer = "false"
}



resource "kubernetes_deployment" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace.coi.metadata.0.name
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
          image = "409547615589.dkr.ecr.ap-southeast-1.amazonaws.com/backend-repo:1.0"
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
    namespace = kubernetes_namespace.coi.metadata.0.name
    annotations = {
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
  wait_for_load_balancer = "false"
}

resource "kubernetes_deployment" "db" {
  metadata {
    name      = "db"
    namespace = kubernetes_namespace.coi.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        #which nodes to deploy on
        app = "db"
      }
    }
    template {
      metadata {
        labels = {
          #what to label the pods with
          app = "db" 
        }
      }
      spec {
        container {
          image = "409547615589.dkr.ecr.ap-southeast-1.amazonaws.com/db-repo:1.0"
          image_pull_policy = "Always"
          name  = "db-container"
          port {
            container_port = 5000
          }
          env_from {
            config_map_ref {
              name = "db-config"
            }
          }
        }
      }
    }
  }
  depends_on = [kubernetes_config_map.db]
}
  
resource "kubernetes_service" "db" {
  metadata {
    name = "db-balancer"
    namespace = kubernetes_namespace.coi.metadata.0.name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-internal" = "true"
    }
  }
  spec {
    selector = {
      app = kubernetes_deployment.db.spec.0.template.0.metadata.0.labels.app
    }
    session_affinity = "None"
    port {
      name = "http"
      port        = 7474
      target_port = 7474
    }
    port {
      name = "bolt"
      port        = 7687
      target_port = 7687
    }
    cluster_ip = var.db_balancer_ip

    type = "LoadBalancer"
  }
  wait_for_load_balancer = "false"
}