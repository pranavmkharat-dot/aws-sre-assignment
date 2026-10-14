output "alb_dns_name" {
  value = aws_lb.web.dns_name
}
output "autoscaling_group_name" {
  value = aws_autoscaling_group.web.name
}
output "target_group_arn" {
  value = aws_lb_target_group.web.arn
}
output "launch_template_id" {
  value = aws_launch_template.web.id
}
