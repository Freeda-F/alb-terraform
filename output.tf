# ALB DNS value

output "alb-dns-name" {
  value = aws_lb.alb.dns_name
}

