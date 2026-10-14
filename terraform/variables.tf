variable "project_name" {
  description = "Name of the Cloud DevOps project."
  type        = string
  default     = "todo-saas"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition = contains(
      ["dev", "test", "prod"],
      var.environment
    )

    error_message = "Environment must be dev, test, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for project resources."
  type        = string
  default     = "us-east-1"
}

variable "kubernetes_version" {
  description = "Amazon EKS Kubernetes version."
  type        = string
  default     = "1.33"
}

variable "vpc_cidr" {
  description = "VPC CIDR range."
  type        = string
  default     = "10.20.0.0/16"
}

variable "node_instance_types" {
  description = "EKS worker-node instance types."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  description = "Minimum worker-node count."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum worker-node count."
  type        = number
  default     = 4
}

variable "node_desired_size" {
  description = "Desired worker-node count."
  type        = number
  default     = 2
}
