# variable "db_username" {
#   description = "The username for the database"
#   type        = string
#   sensitive = true
# }
# variable "db_password" {
#   description = "The password for the database"
#   type        = string
#   sensitive   = true
# }
variable "pub_subnets_cidr" {
  description = "public subnet cidr block"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
variable "pri_subnets_cidr" {
  description = "private subnet cidr block"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24"]
}
variable "azs" {
  type        = list(string)
  description = "Availablity zone for public subnet"
  default     = ["us-east-1a", "us-east-1b"]
}
variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "my-key"
}
variable "region" {
  type        = string
  description = "vpc region"
  default     = "us-east-1"
}
variable "security_group" {
  type        = string
  description = "security group"
  default     = "main_sg"
}
variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t2.micro"
}