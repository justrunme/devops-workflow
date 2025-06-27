variable "docker_username" {
  description = "Your Docker Hub username or GitHub Container Registry username."
  type        = string
}

variable "image_tag" {
  description = "The Docker image tag to deploy."
  type        = string
}