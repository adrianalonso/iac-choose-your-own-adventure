
variable "project_name" {
  description = "The project name"
  type        = string
  default     = "cya"
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
