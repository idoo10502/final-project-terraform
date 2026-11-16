# All the input variables, with validation blocks
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-north-1"
}

variable "name_prefix" {
  description = "Prefix for every name (same as in the bootstrap)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{1,12}$", var.name_prefix))
    error_message = "name_prefix: lowercase letters, digits and hyphens, up to 12 characters."
  }
}

variable "env" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be dev or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR of the VPC (a /16)"
  type        = string
}

variable "image_tag" {
  description = "Image tag to run (the git commit SHA in CI)"
  type        = string
}

variable "desired_count" {
  description = "Number of tasks per service"
  type        = number
}

variable "option_a" {
  description = "First voting option"
  type        = string
  default     = "ביבי"
}

variable "option_b" {
  description = "Second voting option"
  type        = string
  default     = "אייזנקוט"
}
