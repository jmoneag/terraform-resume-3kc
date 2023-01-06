variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ca-central-1"
}

variable "aws_acm_region" {
  description = "AWS ACM with Cloudfront region"
  type        = string
  default     = "us-east-1"
}
variable "s3_bucket_name" {
  description = "S3 Bucket Name"
  type        = string
}

variable "domain_name" {
  description = "Route53 Domain Name"
  type        = string
}

