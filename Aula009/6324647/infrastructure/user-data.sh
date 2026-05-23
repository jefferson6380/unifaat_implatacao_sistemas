#!/bin/bash
# user-data.sh - Executado na inicialização da instância EC2
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

# Clonar e iniciar aplicação
cd /home/ec2-user
git clone https://github.com/gabrielsantiiago/portfolio-aws.git app
cd app/application
cp .env.example .env
docker-compose up -d

echo "Deploy concluído" >> /var/log/user-data.log
