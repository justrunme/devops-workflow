provider "kubernetes" {
  host                   = var.kube_server
  client_certificate     = var.kube_client_cert
  client_key             = var.kube_client_key
  cluster_ca_certificate = var.kube_ca_cert
}

# Deploy Redis
resource "kubernetes_deployment" "redis" {
  metadata {
    name = "redis"
    labels = {
      app = "redis"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "redis"
      }
    }
    template {
      metadata {
        labels = {
          app = "redis"
        }
      }
      spec {
        container {
          name  = "redis"
          image = "redis:alpine"
          port {
            container_port = 6379
          }
          resources {
            limits = {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name = "redis"
    labels = {
      app = "redis"
    }
  }
  spec {
    selector = {
      app = "redis"
    }
    port {
      protocol    = "TCP"
      port        = 6379
      target_port = 6379
    }
  }
}

# Deploy Frontend API
resource "kubernetes_deployment" "frontend_api" {
  metadata {
    name = "frontend-api"
    labels = {
      app = "frontend-api"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "frontend-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "frontend-api"
        }
      }
      spec {
        container {
          name  = "frontend-api"
          image = "${var.docker_username}/devops-workflow-frontend-api:${var.image_tag}" # Image will be dynamically set
          port {
            container_port = 3000
          }
          env {
            name  = "REDIS_URL"
            value = "redis://redis:6379"
          }
          resources {
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "frontend_api" {
  metadata {
    name = "frontend-api"
    labels = {
      app = "frontend-api"
    }
  }
  spec {
    selector = {
      app = "frontend-api"
    }
    type = "NodePort" # Changed from LoadBalancer for Minikube
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 3000
    }
  }
}

# Deploy Backend Worker
resource "kubernetes_deployment" "backend_worker" {
  metadata {
    name = "backend-worker"
    labels = {
      app = "backend-worker"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "backend-worker"
      }
    }
    template {
      metadata {
        labels = {
          app = "backend-worker"
        }
      }
      spec {
        container {
          name  = "backend-worker"
          image = "${var.docker_username}/devops-workflow-backend-worker:${var.image_tag}" # Image will be dynamically set
          env {
            name  = "REDIS_HOST"
            value = "redis"
          }
          resources {
            limits = {
              memory = "256Mi"
              cpu    = "200m"
            }
          }
        }
      }
    }
  }
}