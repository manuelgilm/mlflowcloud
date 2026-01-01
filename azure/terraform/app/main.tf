
data "terraform_remote_state" "core" {
  backend = "azurerm"
  config = {
    resource_group_name  = "gilsamasstudyapitfstate"
    storage_account_name = "gilsamastfstatestg"
    container_name       = "mlflowcloudtfstate"
    key                  = "terraform.core.tfstate"
  }
}

resource "azurerm_container_app" "res-3" {
  container_app_environment_id = data.terraform_remote_state.core.outputs.container_app_env_id
  name                         = var.azure_container_app_name
  resource_group_name          = data.terraform_remote_state.core.outputs.resource_group_name
  revision_mode                = "Single"
  tags                         = {}
  workload_profile_name        = "Consumption"
  registry {
    identity             = "system-environment"
    server               = data.terraform_remote_state.core.outputs.acr_login_server
  }
  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 5000
    transport                  = "auto"
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    max_replicas = 10
    min_replicas = 0
    container {
      cpu    = 1
      args   = ["mlflow", "server", "--default-artifact-root", data.terraform_remote_state.core.outputs.artifact_root]
      image  = "${data.terraform_remote_state.core.outputs.acr_login_server}/${var.image_name}"
      memory = "2Gi"
      name   = "mlflow"
      env {
        name  = "MLFLOW_HOST"
        value = "0.0.0.0"
      }
      env {
        name  = "MLFLOW_PORT"
        value = "5000"
      }
      env {
        name  = "MLFLOW_SERVER_ALLOWED_HOSTS"
        value = "*"
      }
      env {
        name  = "AZURE_STORAGE_CONNECTION_STRING"
        value = data.terraform_remote_state.core.outputs.primary_connection_string
      }
      env {
        name  = "AZURE_STORAGE_ACCESS_KEY"
        value = data.terraform_remote_state.core.outputs.primary_access_key
      }
    }
  }
}