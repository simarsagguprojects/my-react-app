variable "app_name" {
  description = "Application name used for tagging"
  type        = string
  default     = "claude-react-app"
}

variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "Prod"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}
