resource "aws_instance" "fleetman-server" {
    ami = "ami-0861f4e788f5069dd"       
    instance_type = "t2.micro"
    tags={
     Name = "webserver"
     Descriptions= "Configuration-Server for fleetman webapp"
    }
    vpc_security_group_ids = [aws_security_group.sg_fleetman.id]
    key_name=aws_key_pair.web_key.key_name
}

resource "aws_security_group" "sg_fleetman" {
    name = "Security-group fleetman server"
    description = "Allow SSH access and outbound rules"
    ingress {
        from_port=22
        to_port=22
        protocol= "tcp"
        cidr_blocks=["0.0.0.0/0"]      # can be changed to enhance security
    }
      egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "web_key" {
    public_key=file("<path_to_your_ssh_public_key>")
}

output "Public_IP" {
    value=aws_instance.fleetman-server.public_ip
}