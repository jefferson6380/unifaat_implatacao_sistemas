#!/bin/bash
# user-data.sh - Executado automaticamente na inicialização da EC2

yum update -y
yum install -y docker git

# Iniciar Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Criar diretório da aplicação
mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app

echo "EC2 configurada com sucesso" >> /var/log/user-data.log
