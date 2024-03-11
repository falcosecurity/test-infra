variable "bucket_name" {
  type    = string
  default = "falco-distribution"
}

variable "logging_bucket_name" {
  type    = string
  default = "logging-falco-distribution"
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "distribution_origin_id" {
  type    = string
  default = "falcoDistributionOrigin"
}

variable "distribution_name_alias" {
  type    = string
  default = "download.falco.org"
}

variable "playground_bucket_name" {
  type = string
  default = "falco-playground"
}

variable "playground_name_alias" {
  type = string
  default = "play.falco.org"
}

variable "playground_origin_id" {
  type = string
  default = "falcoPlaygroundOrigin"
}