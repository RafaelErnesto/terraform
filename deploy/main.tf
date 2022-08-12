provider "aws" {
    region = "us-east-2"
}

#launch configuration that tells how ASG will configure EC2 instances
resource "aws_launch_configuration" "central" {
    image_id = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
    security_groups = [ aws_security_group.instance.id ]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.web_server_port} &
              EOF
    
    lifecycle {
      create_before_destroy = true
    }
}


# retrieves data about the default vpc
data "aws_vpc" "default" {
  default = true
}


#retrieves data about the default vpc's subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#creates an autoscaling group that will spawn at leas 2 ec2 instances 
resource "aws_autoscaling_group" "central-asg" {
  launch_configuration = aws_launch_configuration.central.name
  vpc_zone_identifier = data.aws_subnets.default.ids 
  target_group_arns = [aws_lb_target_group.central-lb-target-group.arn]# sets the ALB target group
  health_check_type = "ELB"#uses target group's health check

  min_size = 2
  max_size = 3

  tag{
    key = "Name"
    value = "asg-central"#name of each ec2 spawned by the asg
    propagate_at_launch = true
  }
}

#variable that defines the default web server port http
variable "web_server_port" {
 description = "Port for HTTP requests"
 type = number
 default = 8080 
}

# security group for ec2 instances
resource "aws_security_group" "instance" {
    name = "instance-sec-group"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = var.web_server_port
      protocol = "tcp"
      to_port = var.web_server_port
    }
  
}


#creates a variable used on elb
variable "central-lb_port" {
 description = "Port for Central ALB"
 type = number
 default = 80
}

#creates the security group for the ELB
resource "aws_security_group" "central-lb-sec-group" {
  name = "central-lb-sec-group"

  # Allow inbound HTTP requests
  ingress {
    from_port   = var.central-lb_port
    to_port     = var.central-lb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#creates the Application ELB
resource "aws_lb" "central-lb" {
  name               = "celtral-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids#may be distribuited across all subnets
  security_groups    = [aws_security_group.central-lb-sec-group.id]#attaches the security group create for elb
}

#ELB listener
resource "aws_lb_listener" "central-http-listener" {
  load_balancer_arn = aws_lb.central-lb.arn
  port              = 80
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

#defines the ELB target group with health check matcher on status code 200(OK)
resource "aws_lb_target_group" "central-lb-target-group" {
  name     = "central-lb-target-group"
  port     = var.web_server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#ELB listener rule, that accepts every path and pass the requests to the target group
resource "aws_lb_listener_rule" "central-http-listener-rule" {
  listener_arn = aws_lb_listener.central-http-listener.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.central-lb-target-group.arn
  }
}

#outputs the ELB DNS if everything was successful
output "alb_dns_name" {
  value       = aws_lb.central-lb.dns_name
  description = "The domain name of the load balancer"
}