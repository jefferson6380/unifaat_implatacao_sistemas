#!/bin/bash
# Script de inicialização da EC2 (user-data)
yum update -y
yum install -y python3 python3-pip git

pip3 install flask flask-cors

# Clonar a aplicação (ajuste a URL do seu repo)
# git clone https://github.com/SEU_USUARIO/SEU_REPO.git /home/ec2-user/app

# Para testes manuais, a aplicação é iniciada via SSH
echo "EC2 pronta para deploy da aplicação."
