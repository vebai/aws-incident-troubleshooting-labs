variable "aws_region" {
 type = string
 default = "eu-west-2" 
}

variable "project" {
 type = string
 default = "shop-incident-lab" 
}

variable "instance_type" {
 type = string
 default = "t3.micro" 
}

variable "allowed_http_cidrs" {
 type = list(string)
 default = ["0.0.0.0/0"] 
}

variable "enable_alarm" {
 type = bool
 default = true 
}

variable "confirm_public_http" {

  type = bool
  default = false
  validation {
 condition = var.confirm_public_http || var.allowed_http_cidrs != ["0.0.0.0/0"]
 error_message = "Set confirm_public_http=true to acknowledge public HTTP access, or restrict allowed_http_cidrs." 
}


}

