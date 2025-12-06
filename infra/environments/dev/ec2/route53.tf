# data "aws_route53_zone" "main" {
#   name         = "kalezic.net"
#   private_zone = false
# }

# # Public DNS record for ALB
# resource "aws_route53_record" "podinfo_cname" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "${var.environment}-podinfo"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_lb.main.dns_name]

#   depends_on = [aws_lb.main]
# }
