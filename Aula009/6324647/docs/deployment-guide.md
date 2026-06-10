# Deployment Guide

## Pré-requisitos

- AWS CLI v2 instalado e configurado (`aws configure`)
- Conta AWS com permissões: EC2, VPC
- Docker e Docker Compose instalados (para desenvolvimento local)
- Bash (Linux/macOS/WSL)

## Passo a Passo

### 1. Clonar o repositório
```bash
git clone https://github.com/<seu-usuario>/portfolio-aws.git
cd portfolio-aws/Aula009/6324647
```

### 2. Criar a infraestrutura AWS
```bash
cd infrastructure/
chmod +x create-infrastructure.sh cleanup-infrastructure.sh
./create-infrastructure.sh
```
O script exibirá o IP público da instância ao final.

### 3. Aguardar inicialização
A instância leva ~3 minutos para executar o user-data (instalar Docker e subir a aplicação).

### 4. Verificar a aplicação
```bash
# Health check
curl http://<EC2_PUBLIC_IP>/api/health

# Acessar no navegador
open http://<EC2_PUBLIC_IP>
```

### 5. Acesso SSH (se necessário)
```bash
ssh -i infrastructure/portfolio-keypair.pem ec2-user@<EC2_PUBLIC_IP>
# Ver logs da aplicação
docker-compose -f /home/ec2-user/app/application/docker-compose.yml logs
```

## Comandos de Verificação

```bash
# Verificar status da VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=portfolio-vpc"

# Verificar Security Groups
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<VPC_ID>"

# Verificar instância
aws ec2 describe-instances --filters "Name=tag:Name,Values=portfolio-webserver"

# Testar endpoints da API
curl http://<IP>/api/health
curl http://<IP>/api/projects
curl http://<IP>/api/skills
```

## Desenvolvimento Local

```bash
cd application/
cp .env.example .env
docker-compose up -d
# Acesse: http://localhost
```

## Limpeza de Recursos

```bash
cd infrastructure/
./cleanup-infrastructure.sh
```

Confirme no console AWS que não há recursos órfãos em: EC2 > VPC > Security Groups.
