variable "docker_username" {
  description = "Your Docker Hub username or GitHub Container Registry username."
  type        = string
}

variable "image_tag" {
  description = "The Docker image tag to deploy."
  type        = string
}

variable "kube_server" {
  description = "Kubernetes API server address."
  type        = string
}

variable "kube_ca_cert" {
  description = "Kubernetes cluster CA certificate."
  type        = string
}

variable "kube_client_cert" {
  description = "Kubernetes client certificate."
  type        = string
}

variable "kube_client_key" {
  description = "Kubernetes client key."
  type        = string
}