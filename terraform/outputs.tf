output "rds_endpoint" {
  value = aws_db_instance.rds.endpoint
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

output "web_a_private_ip" {
  value = aws_instance.websv_a.private_ip
}

output "web_b_private_ip" {
  value = aws_instance.websv_b.private_ip
}