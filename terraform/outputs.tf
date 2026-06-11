output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

# output "bastion_public_ip" {
#   value = aws_instance.bastion.public_ip
# }

