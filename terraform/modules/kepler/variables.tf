
variable "vpc_name" {
  description = "Name of the VPC"
}

variable "kepler_lb_name" {
  description = "Name of flower load balancer"
}

variable "kepler_tg_name" {
  description = "Name of flower target groups"
}

variable "kepler_env" {
  description = "Kepler env name"
}

variable "kepler_certificate_arn" {
  description = "Certificate arn"
}

variable "kepler_branch" {
  description = "Branch for container"
}

variable "cluster_name" {
  description = "ECS cluster name"
}

variable "kepler_port" {
  description = "kepler Port"
  default     = 3000
}

variable "kepler_cpu" {
  description = "kepler Port"
  default     = 1024
}

variable "kepler_memory" {
  description = "kepler Port"
  default     = 8192
}

variable "app_subnet_name" {
  description = "Subnt name for applications"
}

variable "app_public_subnet_name" {
  description = "Subnt name for loadbalancer"
}

variable "task_count" {
  description = "Count of ecs tasks"
  default     = 1
}

variable "load_balancer_sg" {
  description = "Load balancer sg id"
}

variable "CI_COMMIT_ID" {
  description = "CommitId"
}
