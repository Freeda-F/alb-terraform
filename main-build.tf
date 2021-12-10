## creating launch configuration1

resource "aws_launch_configuration" "launch-config1" {
  name_prefix = "lc1-"
  image_id      = var.ami-id
  instance_type = var.type
  user_data = file ("setup.sh")
  key_name = aws_key_pair.key.id
  security_groups =[aws_security_group.web-sg.id]

  lifecycle {
    create_before_destroy = true
  }
      tags = {
     Name = "${var.project}-lc1"
   }
}

## creating launch configuration2

resource "aws_launch_configuration" "launch-config2" {
  name_prefix = "lc2-"
  image_id      = var.ami-id
  instance_type = var.type
  user_data = file ("setup1.sh")
  key_name = aws_key_pair.key.id
  security_groups =[aws_security_group.web-sg.id]

  lifecycle {
    create_before_destroy = true
  }
      tags = {
     Name = "${var.project}-lc2"
   }
}

##creation of Application load balancer
resource "aws_lb" "alb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo-all.id]
  #enable_deletion_protection = false
  subnets = data.aws_subnet_ids.vpc.ids
  depends_on = [ aws_lb_target_group.target1]


    tags = {
     Name = "${var.project}-lb"
   }
}

## creation of target group-1
resource "aws_lb_target_group" "target1" {
  name     = "tg-1"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc-id
  deregistration_delay = 60

  health_check {
    protocol ="HTTP"
    path = "/"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 30
    
  }
      tags = {
     Name = "${var.project}-tg1"
   }
}

## creation of target group-2
resource "aws_lb_target_group" "target2" {
  name     = "tg-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc-id
  deregistration_delay = 60

  health_check {
    protocol ="HTTP"
    path = "/"
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 10
    interval = 30
    
  }
      tags = {
     Name = "${var.project}-tg2"
   }
}

#create - Listener1 : Fixed response rule
resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.alb.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  depends_on = [  aws_lb.alb ]
}

# Listener - HTTPS
resource "aws_lb_listener" "listener-https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert-arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No website available"
      status_code  = "200"
    }
  }
}

## First forwarding rule
resource "aws_lb_listener_rule" "rule1" {
  listener_arn = aws_lb_listener.listener-https.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target1.arn
  }

  condition {
    host_header {
      values = ["version1.freeda-francis.tech"]
    }
  }
}

## second forwarding rule
resource "aws_lb_listener_rule" "rule2" {
  listener_arn = aws_lb_listener.listener-https.arn
  priority     = 50

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target2.arn
  }

  condition {
    host_header {
      values = ["version2.freeda-francis.tech"]
    }
  }
}

## ASG -1
resource "aws_autoscaling_group" "asg-1" {

  launch_configuration    = aws_launch_configuration.launch-config1.id
  health_check_type       = "EC2"
  min_size                = var.asg_count
  max_size                = var.asg_count
  desired_capacity        = var.asg_count
  vpc_zone_identifier     = data.aws_subnet_ids.vpc.ids
  target_group_arns       = [ aws_lb_target_group.target1.arn ]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Asg-1"
  }

  lifecycle {
    create_before_destroy = true
  }
}

## ASG -2
resource "aws_autoscaling_group" "asg-2" {

  launch_configuration    = aws_launch_configuration.launch-config2.id
  health_check_type       = "EC2"
  min_size                = var.asg_count
  max_size                = var.asg_count
  desired_capacity        = var.asg_count
  vpc_zone_identifier     = data.aws_subnet_ids.vpc.ids
  target_group_arns       = [ aws_lb_target_group.target2.arn ]
  tag {
    key = "Name"
    propagate_at_launch = true
    value = "Asg-2"
  }

  lifecycle {
    create_before_destroy = true
  }
}