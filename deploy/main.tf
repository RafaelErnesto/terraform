provider "aws" {
    region = "us-east-2"
}

resource "aws_instance" "pioneer" {
    ami = "ami-0fb653ca2d3203ac1"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.instance.id ]

    user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF

    user_data_replace_on_change = true
    tags = {
      Name = "pioneer"
    }
}

resource "aws_security_group" "instance" {
    name = "group-1-terraform"

    ingress {
      cidr_blocks = [ "0.0.0.0/0" ]
      from_port = 8080
      protocol = "tcp"
      to_port = 8080
    }
  
}