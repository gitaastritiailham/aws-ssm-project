variable "region" {
  default = "us-east-1"
}

variable "class_no" {
  default = "ie3a26" 
}

# variable "key_name" {
#   default = "ie3a2240794-key" 
# }

variable "db_password" {
  type      = string
  sensitive = true
}