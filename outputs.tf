output "address" {
  value = "http://${aws_elb.web.dns_name}"
}
output "id" {
  description = "List of IDs of instances"
  value = [
    "${aws_instance.SanchuTest.*.id}"]
}
output "public_ip" {
  description = "List of public_ip's of instances"
  value = [
    "${aws_instance.SanchuTest.*.public_ip}"]
}
output "command" {
  value = "bash /tmp/wait_for_elb.sh"
}

/*
output "id" {
  description = "List of IDs of instances"
  value = [
    "${aws_instance.SanchuTest.*.id}"]
}

output "availability_zone" {
  description = "List of availability zones of instances"
  value = [
    "${aws_instance.SanchuTest.*.availability_zone}"]
}


output "key_name" {
  description = "List of key names of instances"
  value = [
    "${aws_instance.SanchuTest.*.key_name}"]
}
output "public_dns" {
  description = "List of public DNS names assigned to the instances. For EC2-VPC, this is only available if you've enabled DNS hostnames for your VPC"
  value = [
    "${aws_instance.SanchuTest.*.public_dns}"]
}

output "public_ip" {
  description = "List of public IP addresses assigned to the instances, if applicable"
  value = [
    "${aws_instance.SanchuTest.*.public_ip}"]
}
*/

