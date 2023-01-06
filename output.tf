output "bucket_regional_domain_name" {
  value       = module.s3-bucket.s3_bucket_bucket_regional_domain_name
  description = "The bucket region-specific domain name"
}

output "bucket_domain_name" {
  value       = module.s3-bucket.s3_bucket_bucket_domain_name
  description = "The bucket region-specific domain name"
}

output "bucket_website_endpoint" {
  value       = module.s3-bucket.s3_bucket_website_endpoint
  description = "The bucket region-specific domain name"
}

output "cloudfront_website_endpoint" {
  value       = module.cdn.cloudfront_distribution_domain_name
  description = "The cloudfront distribution domain name"
}

output "cloudfront_deploy_status" {
  value       = module.cdn.cloudfront_distribution_status
  description = "The cloudfront distribution status"
}

