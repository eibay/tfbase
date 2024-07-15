resource "aws_alb" "alb" {
  name                       = "${var.app_name}-${var.app_environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public.*.id
  enable_deletion_protection = false

  tags = {
    Name        = "${var.app_name}-alb",
    Environment = var.app_environment
  }
}

resource "aws_alb_target_group" "alb-tg" {
  name        = "${var.app_name}-${var.app_environment}-alb-tg"
  port        = var.infra_params.app_port #8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main_vpc.id
  depends_on  = [aws_alb.alb]

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200-299"
    timeout             = "3"
    path                = "/api/health"
    unhealthy_threshold = 5
  }

  tags = {
    Name        = "${var.app_name}-alb-tg",
    Environment = var.app_environment
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.alb.id
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.infra_params.alb_tls_cert_arn

  default_action {
    target_group_arn = aws_alb_target_group.alb-tg.id
    type             = "forward"
  }
}
