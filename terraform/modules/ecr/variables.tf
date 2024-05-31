
variable "project_name" {
  description = "The project name"
  type        = string
}

variable "tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)

}
