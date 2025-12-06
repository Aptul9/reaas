# # ACM Certificate for wildcard domain
# resource "aws_acm_certificate" "wildcard" {
#   domain_name               = "*.${var.domain_name}"
#   subject_alternative_names = [var.domain_name]
#   validation_method         = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.project_name}-wildcard-cert"
#   }
# }

# data "aws_route53_zone" "main" {
#   name         = var.domain_name
#   private_zone = false
# }
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# resource "aws_acm_certificate_validation" "wildcard" {
#   certificate_arn         = aws_acm_certificate.wildcard.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }

# # Output certificate ARN
# output "acm_certificate_arn" {
#   description = "ARN of the wildcard ACM certificate"
#   value       = aws_acm_certificate.wildcard.arn
# }

# output "acm_certificate_validation_records" {
#   description = "DNS validation records for manual configuration"
#   value = {
#     for dvo in aws_acm_certificate.wildcard.domain_validation_options : dvo.domain_name => {
#       name  = dvo.resource_record_name
#       type  = dvo.resource_record_type
#       value = dvo.resource_record_value
#     }
#   }
# }