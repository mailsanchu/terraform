#!/bin/sh
sudo yum -y update
sudo yum -y install nginx
sudo service nginx start
IP_ADDR=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo $IP_ADDR
sudo sed -Ei "s/Amazon Linux AMI/Amazon Linux AMI-$IP_ADDR/g" /usr/share/nginx/html/index.html