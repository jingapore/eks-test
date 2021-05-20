resource "kubernetes_config_map" "backend" {
  metadata {
    name      = "backend-config"
    namespace = kubernetes_namespace.eks_test.metadata.0.name
  }

  # variables are read-in by shell script
  data = {
    MOCK_VARIABLE_1 = var.backend_variables_mock_variable_1
  }
}