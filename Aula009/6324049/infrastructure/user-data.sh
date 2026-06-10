#!/bin/bash

# Atualiza sistema
sudo apt update -y
sudo apt upgrade -y

# Instala dependencias
sudo apt install -y \
git \
docker.io \
docker-compose

# Inicia docker
systemctl start docker
systemctl enable docker

# Adiciona ubuntu ao grupo docker
usermod -aG docker ubuntu

# Vai para home
cd /home/ubuntu

# Clona repositorio
git clone https://github.com/Danilo8922/unifaat_implatacao_sistemas.git

# Entra na pasta do projeto
cd unifaat_implatacao_sistemas

# Entra na pasta da aula

cd Aula009

# Entra na pasta do projeto 

cd 6324049

cd application

sudo usermod -aG docker ubuntu

newgrp docker

# Sobe containers
docker-compose up --build -d