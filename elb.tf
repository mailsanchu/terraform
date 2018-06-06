# The provider here is aws but it can be other provider
provider "aws" {
  shared_credentials_file = "/home/svarkey/.aws/credentials"
  profile = "default"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "terraform_vpc" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Terraform_Vpc"
  }
}


# Create a way out to the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  tags {
    Name = "Terraform_Internet_Gateway"
  }
}

# Public route as way out to the internet
resource "aws_route" "internet_access" {
  route_table_id = "${aws_vpc.terraform_vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}


# Create a subnet in the AZ eu-east-1
resource "aws_subnet" "subnet_us_east_1a" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"
  cidr_block = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  //  default_for_az = true
  tags = {
    Name = "Terraform_Subnet"
  }
}


# Associate subnet subnet_eu_west_1a to public route table
resource "aws_route_table_association" "subnet_eu_west_1a_association" {
  subnet_id = "${aws_subnet.subnet_us_east_1a.id}"
  route_table_id = "${aws_vpc.terraform_vpc.main_route_table_id}"
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.terraform_vpc.default_network_acl_id}"

  ingress {
    protocol = -1
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  egress {
    protocol = -1
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.terraform_vpc.id}"

  ingress {
    protocol = -1
    self = true
    from_port = 0
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  depends_on = [
    "aws_internet_gateway.gw"]
}


resource "aws_instance" "TerraformDemo" {
  ami = "ami-14c5486b"
  instance_type = "t2.micro"
  key_name = "svarkey_private"

  subnet_id = "${aws_subnet.subnet_us_east_1a.id}"
  count = "${var.num_of_instances}"
  # Creating three EC2 instances
  vpc_security_group_ids = [
    "${aws_default_security_group.default.id}"]
  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = [
      "private_ip",
      "root_block_device"]
  }
  tags {
    Name = "TerraformDemo_Instance_${count.index}"
  }

}

resource "aws_elb" "web" {
  name = "terraform-demo"
  # The same availability zone as our instance
  subnets = [
    "${aws_subnet.subnet_us_east_1a.id}"]
  security_groups = [
    "${aws_default_security_group.default.id}"]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }
  # The instance is registered automatically
  instances = [
    "${aws_instance.TerraformDemo.*.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400
  depends_on = [
    "aws_instance.TerraformDemo"]
  provisioner "local-exec" {
    command = "cp -f /home/svarkey/dev/code/demo/terraform/wait_for_elb.sh /tmp/wait_for_elb.sh"
    on_failure = "continue"
  }
  provisioner "local-exec" {
    command = "sed -Ei 's/LOAD_BAL_DNS/${aws_elb.web.dns_name}/g' /tmp/wait_for_elb.sh"
    on_failure = "continue"
  }
  provisioner "local-exec" {
    command = "chmod a+x /tmp/wait_for_elb.sh"
    on_failure = "continue"
  }
}

resource "null_resource" "nginx_install" {
  depends_on = [
    "aws_instance.TerraformDemo"]
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  count = "${var.num_of_instances}"
  triggers {
    current_ec2_instance_id = "${element(aws_instance.TerraformDemo.*.id, count.index)}"
    instance_number = "${count.index + 1}"
  }
  connection {
    host = "${element(aws_instance.TerraformDemo.*.public_ip, count.index)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo yum -y install nginx",
      "sudo service nginx start",
      "sudo sed -Ei 's/Amazon Linux AMI/Amazon Linux AMI-${element(aws_instance.TerraformDemo.*.public_ip, count.index)}/g' /usr/share/nginx/html/index.html",
    ]
    connection {
      user = "ec2-user"
      type = "ssh"
      private_key = "${file("/home/svarkey/dev/data/vpn/aws/svarkey_private.pem")}"
      timeout = "5m"
      agent = false
    }
  }
  provisioner "local-exec" {
    command = "/tmp/wait_for_elb.sh"
    interpreter = [
      "/bin/bash",
      "-c"]
    on_failure = "continue"
  }
}


/*

# THIS ONE WORKS
resource "aws_elb_attachment" "search-svc-elb-attach-0" {
  elb = "${aws_security_group.elb.id}"
  instance = "${element(aws_instance.SanchuTest.*.id, 0)}"
}


## THE FOLLOWING TWO THROW AN ERROR
resource "aws_elb_attachment" "search-svc-elb-attach-1" {
  elb = "${aws_security_group.elb.id}"
  instance = "${element(aws_instance.SanchuTest.*.id, 1)}"
}
*/

