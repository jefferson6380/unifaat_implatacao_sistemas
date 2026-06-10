#!/bin/bash
# User Data - Web Server (Amazon Linux 2)
yum update -y
yum install -y docker git

systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app

echo "Web Server setup completed at $(date)" > /var/log/user-data.log
