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

variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "cya"
    owner       = "adrian.alonso@volkswagen-groupservices.com"
  }
}
