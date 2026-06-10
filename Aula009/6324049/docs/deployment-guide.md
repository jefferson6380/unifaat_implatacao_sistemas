# Deploy do Projeto
```bash
# Clonar o Repositório 

git clone https://github.com/Danilo8922/unifaat_implatacao_sistemas.git

# Acessar a pasta do projeto

cd unifaat_implatacao_sistemas

# Entra na pasta da aula

cd Aula009

# Entra na pasta do projeto 

cd 6324049

# entre na pasta para subir a infraestrutura

cd infrastructure

# Permissões para a executar os scripts

chmod +x cleanup-infrastructure.sh create-infrastructure.sh

# Depois execute:

./create-infrastructure.sh

# Para subir a aplicação toda depois que terminar de subir a Instancia vamos descobrir  IP puplico dela, para executar o proximo comando e acessar a pagina: 

aws ec2 describe-instances \
--query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress]" \
--output table \
--region us-east-1

# Ira aparecer algo assim 

#------------------------------------------------
#|              DescribeInstances               |
#+----------------------+-----------------------+
#|  i-0bd10da35d82840e1 |  IP-PUBLICO AQUI       |
#+----------------------+-----------------------+

# Depois rode o comando 

ssh -i TF09-KeyPair.pem ubuntu@IP_PUBLICO

# Dentro do servidor execute os seguintes comandos 

# Atualiza sistema
sudo apt update -y
sudo apt upgrade -y

# Instala dependencias
sudo apt install -y \
git \
docker.io \
docker-compose

# Inicia docker
sudo systemctl start docker
sudo systemctl enable docker

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


### Verificação
- **Site:** http://IP_PULICO:80
- **Health Check:** http://IP_PULICO:5000/health
- **API Projetos:** http://IP_PULICO:5000/api/projects

---
