# TF09 - Portfólio Pessoal na AWS

**Aluno:** Danilo Lenardi de Almeida  
**RA:** 6324049  
**Disciplina:** Implementação de Sistemas  
**Curso:** Análise e Desenvolvimento de Sistemas - UniFAAT  

---

## Visão Geral

Projeto de deploy de aplicação web na AWS utilizando EC2, VPC, Security Groups e Docker.
A aplicação é um portfólio pessoal com frontend em Nginx e backend em Python/Flask.

---

## Arquitetura de Rede

### VPC Configuration
- **CIDR Block:** 10.0.0.0/16
- **Region:** us-east-1 (N. Virginia)

### Subnets
| Nome | CIDR | AZ | Tipo |
|------|------|----|------|
| TF09-Subnet-Publica | 10.0.1.0/24 | us-east-1a | Pública |
| TF09-Subnet-Privada | 10.0.2.0/24 | us-east-1b | Privada |

### Recursos de Rede
| Recurso | ID |
|---------|-----|
| VPC | vpc-ID |
| Subnet Pública | subnet-ID |
| Subnet Privada | subnet-ID |
| Internet Gateway | igw-ID |
| Route Table | rtb-ID |

### Routing
- **Public Route Table:** 0.0.0.0/0 → igw-ID
- **Private Route Table:** Apenas tráfego local (10.0.0.0/16)

---

## Segurança Implementada

### Security Groups

#### TF09-SG-Web (sg-0c2436eecf9ba66f2)
| Porta | Protocolo | Origem | Descrição |
|-------|-----------|--------|-----------|
| 80 | TCP | 0.0.0.0/0 | HTTP público |
| 443 | TCP | 0.0.0.0/0 | HTTPS público |
| 5000 | TCP | 0.0.0.0/0 | API Backend |
| 22 | TCP | 187.0.234.39/32 | SSH restrito |

#### TF09-SG-Database (sg-01e9afcd38989916d)
| Porta | Protocolo | Origem | Descrição |
|-------|-----------|--------|-----------|
| 5432 | TCP | sg-ID| PostgreSQL só pelo EC2 |

### Medidas de Segurança
- ✅ VPC isolada com subnets pública e privada
- ✅ SSH restrito ao IP do desenvolvedor (187.0.234.39/32)
- ✅ Banco de dados em subnet privada sem acesso externo
- ✅ Princípio do menor privilégio aplicado
- ✅ Chave SSH com permissão 400

---

## Instância EC2

| Recurso | Valor |
|---------|-------|
| Instance ID | i-ID |
| Tipo | t3.micro (Free Tier) |
| AMI | Ubuntu 20.04 LTS |
| IP Público | Variavel |
| Region | us-east-1 |

---

## Tecnologias Utilizadas

| Tecnologia | Uso |
|------------|-----|
| AWS EC2 | Servidor de aplicação |
| AWS VPC | Rede privada isolada |
| Docker | Containerização |
| Docker Compose | Orquestração de containers |
| Python/Flask | API Backend |
| Nginx | Servidor Web Frontend |
| PostgreSQL | Banco de dados |

---

## Como Executar

### Pré-requisitos
- AWS CLI configurado
- Docker e Docker Compose instalados

### Deploy
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

## Custos Estimados

| Recurso | Custo |
|---------|-------|
| EC2 t3.micro | Free Tier (750h/mês) |
| VPC | Gratuito |
| Internet Gateway | Gratuito |
| Security Groups | Gratuito |
| Transferência de dados | ~$0.01/GB |
| **Total estimado** | **$0,00 (Free Tier)** |

---

## Limpeza de Recursos
```bash
cd infrastructure
chmod +x cleanup-infrastructure.sh
./cleanup-infrastructure.sh
```

---

## Documentação Adicional
- [Guia de Deploy](docs/deployment-guide.md)
- [Análise de Segurança](docs/security-analysis.md)
- [Troubleshooting](docs/troubleshooting.md)
