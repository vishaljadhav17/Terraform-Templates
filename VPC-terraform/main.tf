#create_VPC
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}
#create_Subnet
resource "aws_subnet" "sub1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}

#create_igw
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}

#create_routetabele
resource "aws_route_table" "route1" {
  vpc_id = aws_vpc.myvpc.id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.myigw.id
   }
}

#create_route_table_association
resource "aws_route_table_association" "rt1a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.route1.id
}
resource "aws_route_table_association" "rt1b" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.route1.id
}

#create_security_group
resource "aws_security_group" "mysg" {
  name_prefix = "web.mysg"
  vpc_id      = aws_vpc.myvpc.id
#add inboud_rule
ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
#add outbound_rule
egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

#create_s3_bucket
resource "aws_s3_bucket" "mys3bucket" {
  bucket = "my-vj-bucket-17"
}

#create_ec2_instance
resource "aws_instance" "webserver1" {
  ami  = "ami-0522ab6e1ddcc7055"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode (file("script.sh"))
}
resource "aws_instance" "webserver2" {
  ami  = "ami-0522ab6e1ddcc7055"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.mysg.id]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode (file("script1.sh"))
}

#create_load_balancer
resource "aws_lb" "mylb" {
  name               = "terraform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}

#create target_group

resource "aws_lb_target_group" "targetgroup" {
  name     = "terraform-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

 health_check {
   path = "/"
   port = "traffic-port"
 }
}

#create target_group_association

resource "aws_lb_target_group_attachment" "attachtg1" {
  target_group_arn = aws_lb_target_group.targetgroup.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attachtg2" {
  target_group_arn = aws_lb_target_group.targetgroup.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

#make_sure_to_add_listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targetgroup.arn
  }
}

#make_a_habit_of_output
output "loadbalancerdns" {
   value = aws_lb.mylb.dns_name
}
