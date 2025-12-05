output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "ALB Route53 Zone ID"
  value       = aws_lb.main.zone_id
}

output "blue_target_group_name" {
  description = "Blue target group name"
  value       = aws_lb_target_group.blue.name
}

output "green_target_group_name" {
  description = "Green target group name"
  value       = aws_lb_target_group.green.name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.main.name
}

output "codedeploy_app_name" {
  description = "CodeDeploy application name"
  value       = aws_codedeploy_app.main.name
}

output "codedeploy_deployment_group_name" {
  description = "CodeDeploy deployment group name"
  value       = aws_codedeploy_deployment_group.main.deployment_group_name
}

output "codedeploy_bucket_name" {
  description = "S3 bucket for CodeDeploy artifacts"
  value       = aws_s3_bucket.codedeploy.id
}

output "health_check_url" {
  description = "Health check endpoint"
  value       = "https://${aws_lb.main.dns_name}/healthz"
}

output "alb_url" {
  description = "ALB public URL"
  value       = "https://${aws_lb.main.dns_name}"
}

output "alb_https_url" {
  description = "HTTPS URL of the Application Load Balancer"
  value       = "https://${aws_lb.main.dns_name}"
}

output "podinfo_public_url" {
  description = "Public HTTPS URL for Podinfo via Route53"
  value       = "https://${var.environment}-podinfo.kalezic.net"
}

output "podinfo_cname_target" {
  description = "CNAME target (ALB DNS name)"
  value       = aws_lb.main.dns_name
}