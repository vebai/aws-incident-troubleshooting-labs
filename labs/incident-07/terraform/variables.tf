variable "aws_region" {
  type    = string
  default = "eu-west-2"
}
variable "vpc_id" {
  type = string
}
variable "subnet_id" {
  type = string
}
variable "security_group_id" {
  type = string
}
variable "ami_id" {
  type = string
}
variable "catalog_bucket" {
  type = string
}
variable "catalog_key" {
  type    = string
  default = "catalog.json"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "inject_failure" {
  type    = bool
  default = true
}
variable "project_prefix" {
  type    = string
  default = "shop-incident-07"
}
