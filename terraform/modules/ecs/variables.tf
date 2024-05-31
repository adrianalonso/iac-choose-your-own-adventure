
variable "project_name" {
  description = "The project name"
  type        = string
}

variable "cloudwatch_group" {
  description = "The cloudwatch group"
  type        = string
}

variable "container_cpu" {
  description = "The number of CPU units used by the task."
  type        = number
  default     = 128
}

variable "container_memory" {
  description = "The amount of memory (in MiB) used by the task."
  type        = number
  default     = 512
}

variable "vpc_id" {
  description = "Vpc id"
  type        = string
}

variable "subnets" {
  description = "Subnets"
  type        = list(string)
}

variable "load_balancer_target_group_arn" {
  description = "ARN of Load Balancer Target Group"
  type        = string
}

variable "docker_image" {
  description = "Image of ECR to deploy"
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)

}
