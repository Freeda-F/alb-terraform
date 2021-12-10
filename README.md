# Build AWS Application Load balancer using Terraform

Application Load Balancer operates at the request level (layer 7), routing traffic to targets (EC2 instances, containers, IP addresses, and Lambda functions) based on the content of the request. Create an AWS ALB that automatically redirects traffic to its specified target groups based on the ALB listener rules and also redirects all HTTP incoming traffic to HTTPS.


## Features
This terraform script will provision the following :
- Create 2 Launch configurations for settings up 2 different Auto Scaling Groups (asg-1 & asg-2)
- The Instances in this ASG are registered into 2 different target groups (Target1 & Target2 resprectively).
- Create an application load balancer which redirects the incoming HTTP traffic to HTTPS based on the Listener rules specified. It also redirects the traffic to the specific target groups based on the rules configured in the Listeners.

## Requirements
- [Terraform v1.0.11](https://www.terraform.io/downloads.html)
- IAM user with administrator access to EC2.
- A valid SSL certificate which has been already imported to ACM.

## Usage
### 1. Create the variables.tf file
> The file variables.tf contains the variables used in the script. This can be modified according to the needs.
```

variable "access_key" {
  default = "access-key here"
}

variable "secret_key" {
  default = "secret-key here"
}

variable "region" {
    default = "ap-south-1" #----------------Region----------------#
}

variable "type" {
    default = "t2.micro" #----------------Instane Type----------------#
}

variable "ami-id" {
    default = "ami-052cef05d01020f1d" #----------------Image ID----------------#
}

variable "project" {
  default = "production" #----------------Name of the project----------------#
  
}

variable "asg_count" {
  default =2 #----------------Number of instances in Auto Scaling Group----------------#
  
}

variable "vpc-id" {
  default = "vpc-0eb0bd9a3456c0ac45678d067" #----------------VPC-ID----------------#
}

variable "cert-arn" {
  default = "arn:aws:acm:ap-south-1:384463163042:certificate/a242aa35-46f56796-871e-85bddfghe31c188f" #----------------ARN of the SSL uploaded in ACM----------------#
}
```

### 2. Create the provider file
> Terraform relies on the file called "provider.tf" to interact with cloud providers. Terraform configurations must declare which providers they require so that Terraform can install and use them. In our case, it is AWS. 
```
provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
```
### 3. Extra requirements for setting up a Load balancer. 
> Creating a key-pair for the instances.
```
#key-pair creation
resource "aws_key_pair" "key" {
  key_name   = "devkey"
  public_key = file ("devkey.pub")
}
```

> Gathering the VPC and subnet information.
```
# get details of VPC and its subnets

data "aws_subnet_ids" "vpc" {
  vpc_id = var.vpc-id
}
```

> Creation of Security groups.
```
#security-group creation
resource "aws_security_group" "demo-all" {
  name        = "demo-all"
  description = "Allow all inbound traffic"

  ingress {
    description      = ""
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "demo-all-sg"
  }
}

#security-group for Web Application
resource "aws_security_group" "web-sg" {
  name        = "web-sg"
  description = "Allow 80,443,22 inbound traffic"

  ingress = [
    {
    description      = ""
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
    self = false
  },
  {
    description      = ""
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
     self = false
  },
  {
        description      = ""
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    prefix_list_ids = []
    security_groups = []
     self = false
  }
  ]

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "web-sg"
  }
}
```

### 4. Create Launch Configuration to setup ASG
> Here we are using name_prefix instead of name so that while resusing this scipt no conflict in the names occur. Also, we are using file() to load the required user-data into the launch configuration.

```
## creating launch configuration1

resource "aws_launch_configuration" "launch-config1" {
  name_prefix = "lc1-"
  image_id      = var.ami-id
  instance_type = var.type
  user_data = file ("setup.sh")
  key_name = aws_key_pair.key.id
  security_groups =[aws_security_group.demo.id]

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
  security_groups =[aws_security_group.demo.id]

  lifecycle {
    create_before_destroy = true
  }
      tags = {
     Name = "${var.project}-lc2"
   }
}
```
### 5. Create Target Groups
> Here, we have create 2 target groups to forward the traffic to the specific instances.

```
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
```

### 6.Lauch Auto-Scaling Groups from LC
> creates an Auto-Scaling group-1  which has its target group as tg-1
```
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
```
> creates an Auto-Scaling group-2  which has its target group as tg-2
```
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
```

### 7. Create an Application Load Balancer
```
##creation of Application load balancer
resource "aws_lb" "alb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.demo.id]
  enable_deletion_protection = false
  subnets = data.aws_subnet_ids.vpc.ids
  depends_on = [ aws_lb_target_group.target1]


    tags = {
     Name = "${var.project}-lb"
   }
}
```
### 7.1) Create http listener of application loadbalancer with default redirects action to HTTPS
```
## create - Listener1 : HTTP
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
```
### 7.2) Create https listener of application loadbalancer with default fixed response.
```
# Listener - HTTPS
resource "aws_lb_listener" "listener-https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.cert-arn #----------------SSL cert here---------------#

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No website available"
      status_code  = "200"
    }
  }
}
```

### 7.3) Forwarding traffic based on Host-headers to different target groups.
```
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
      values = ["version1.freeda-francis.tech"] #----------------Provide hostname here----------------#
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
      values = ["version2.freeda-francis.tech"] #----------------Provide hostname here----------------#
    }
  }
}
```

## Provisioning

Navigate to the project directory where the required files are already modified and do the following.

1. Apply 'terraform init' command which is used to initialize a working directory containing Terraform configuration files.
```
$ terraform init
```
Then, use 'terraform plan' command to create an execution plan and then use 'terraform apply' to execute the plan. 
```
$ terraform plan
$ terraform apply
```

## Result
After the execution of this script, you will have an AWS application load balancer.

![image](https://user-images.githubusercontent.com/93197553/145637354-cf659667-2f8e-4304-88dd-15507d097d24.png)
