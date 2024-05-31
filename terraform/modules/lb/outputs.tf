output "load_balancer_url" {
  value = aws_lb.loadbalancer.dns_name
}

output "load_balancer_target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}
