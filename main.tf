terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.39.0"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = var.aws_region
}

provider "aws" {
  alias  = "acm_cloudfront"
  region = var.aws_acm_region
}

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.6.0"

  bucket        = var.s3_bucket_name
  acl           = "private"
  attach_policy = true
  policy        = file("policy.json")

  website = {
    index_document = "index.html"
    error_document = "404.html"
  }

  versioning = {
    status     = true
    mfa_delete = false
  }
}

resource "aws_route53_zone" "primary" {
  name = var.domain_name
}

resource "aws_route53_record" "A" {
  name    = var.domain_name
  type    = "A"
  zone_id = aws_route53_zone.primary.id
  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

module "acm_3kc_resume" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.acm_cloudfront
  }

  domain_name = var.domain_name
  zone_id     = aws_route53_zone.primary.id
  dns_ttl     = 300

  subject_alternative_names = [
    "*.${var.domain_name}",
    "www.${var.domain_name}"
  ]

  wait_for_validation = true
  tags = {
    Name = var.domain_name
  }
}

module "cdn" {
  source  = "terraform-aws-modules/cloudfront/aws"
  version = "3.1.0"

  aliases = ["www.${var.domain_name}", "${var.domain_name}"]

  comment             = "My awesome resume CloudFront"
  enabled             = true
  is_ipv6_enabled     = false
  price_class         = "PriceClass_100"
  retain_on_delete    = false
  wait_for_deployment = false
  default_root_object = "index.html"

  origin = {

    "${module.s3-bucket.s3_bucket_website_endpoint}" = {
      domain_name = "${module.s3-bucket.s3_bucket_website_endpoint}"
      custom_origin_config = {
        http_port              = "80"
        https_port             = "443"
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  default_cache_behavior = {
    target_origin_id       = "${module.s3-bucket.s3_bucket_website_endpoint}"
    viewer_protocol_policy = "allow-all"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    use_forwarded_values   = false
  }

  viewer_certificate = {
    acm_certificate_arn      = "${module.acm_3kc_resume.acm_certificate_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

}