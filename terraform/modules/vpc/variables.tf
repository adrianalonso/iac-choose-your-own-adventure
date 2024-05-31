variable "project_name" {
  description = "The project name"
  type        = string
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "cidr_block_subnet_1" {
  description = "The CIDR block for the subnet 1"
  type        = string
}

variable "cidr_block_subnet_2" {
  description = "The CIDR block for the subnet 2"
  type        = string
}

variable "az_subnet_1" {
  description = "The CIDR block for the subnet 1"
  type        = string
}

variable "az_subnet_2" {
  description = "The CIDR block for the subnet 2"
  type        = string
}


variable "tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)

}
