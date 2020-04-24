variable "env_prefix_name" {
  type        = "string"
  description = "please enter Name of your choice. like your organization name, Default is Test and this will create Test-VPC"
  default     = "Test"

}


variable "aws_ip_cidr_range" {
  default     = "10.0.0.0/16"
  type        = "string"
  description = "IP CIDR Range for VPC."
}

variable "availibility_zones" {
  type = "map"
  default = {
    zone1 = "ap-southeast-2a"
    zone2 = "ap-southeast-2b"
  }
}

variable "region" {
  default     = "ap-southeast-2"
  type        = "string"
  description = "Region for VPC."
}

