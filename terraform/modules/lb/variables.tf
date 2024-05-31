
variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)

}

variable "vpc_id" {
  description = "Id of vpc where is attached the load balancer"
  type        = string

}

variable "subnets" {
  description = "Subnets attached"
  type        = list(string)
}

