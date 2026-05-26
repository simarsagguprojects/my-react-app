output "cloudfront_distribution_id" {
  description = "ID of the react-app-cdn CloudFront distribution"
  value       = aws_cloudfront_distribution.react_app_cdn.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the react-app-cdn CloudFront distribution"
  value       = aws_cloudfront_distribution.react_app_cdn.domain_name
}

output "s3_bucket_name" {
  description = "Name of the react-app-bucket S3 bucket"
  value       = aws_s3_bucket.react_app.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the react-app-bucket S3 bucket"
  value       = aws_s3_bucket.react_app.arn
}

output "access_log_s3_bucket_name" {
  description = "Name of the react-app-bucket-access-logs S3 bucket"
  value       = aws_s3_bucket.access_logs.bucket
}

output "access_log_s3_bucket_arn" {
  description = "ARN of the react-app-bucket-access-logs S3 bucket"
  value       = aws_s3_bucket.access_logs.arn
}
