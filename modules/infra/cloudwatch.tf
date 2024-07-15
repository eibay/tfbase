# Log Group on CloudWatch to get container logs
resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.app_name}-${var.app_environment}-logs"

  tags = {
    Name        = var.app_name
    Environment = var.app_environment
  }
}
