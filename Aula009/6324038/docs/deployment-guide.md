# Deployment Guide - TF09 Portfólio AWS

## Pré-requisitos

- AWS CLI instalado e configurado (`aws configure`)
- Conta AWS com Free Tier ativo
- Bash (Linux/macOS/WSL)
- Git

## Passo a Passo

### 1. Clonar o repositório

```bash
git clone <url-do-repositorio>
cd Aula009/TF09-Aluno
```

### 2. Criar a infraestrutura

```bash
cd infrastructure
chmod +x create-infrastructure.sh cleanup-infrastructure.sh
./create-infrastructure.sh
```

O script cria automaticamente:
- VPC `10.0.0.0/16` com DNS habilitado
- Subnet pública `10.0.1.0/24` (us-east-1a)
- Subnet privada `10.0.2.0/24` (us-east-1a)
- Internet Gateway + Route Table pública
- Security Group Web Server (portas 22/seu-IP, 80, 443)
- Security Group Database (porta 3306 apenas do Web SG)
- Key Pair salvo em `TF09-Portfolio-KeyPair.pem`
- EC2 Web Server (t3.micro, subnet pública)
- EC2 Database (t3.micro, subnet privada)

Ao final, os IDs são salvos em `.env.infrastructure`.

### 3. Aguardar inicialização

As instâncias levam ~3 minutos para executar o user data. Verifique:

```bash
source infrastructure/.env.infrastructure
aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --output text | tail -5
```

### 4. Fazer deploy da aplicação

```bash
source infrastructure/.env.infrastructure

# Copiar arquivos para o Web Server
scp -i infrastructure/${KEY_NAME}.pem -r application/ ec2-user@${WEB_PUBLIC_IP}:~/app/

# Conectar e iniciar
ssh -i infrastructure/${KEY_NAME}.pem ec2-user@${WEB_PUBLIC_IP}
```

Dentro da instância:

```bash
cd ~/app

# Criar .env com o IP do banco
cat > .env << EOF
DB_HOST=$(grep DB_PRIVATE_IP ~/.env.infrastructure | cut -d= -f2)
DB_USER=appuser
DB_PASSWORD=SecurePass123!
DB_NAME=portfolio_db
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOF

sudo docker-compose up -d --build
```

### 5. Verificar funcionamento

```bash
# Health check
curl http://${WEB_PUBLIC_IP}/health

# API de projetos
curl http://${WEB_PUBLIC_IP}/api/projects

# Abrir no navegador
echo "http://${WEB_PUBLIC_IP}"
```

### 6. Limpeza após avaliação

```bash
cd infrastructure
./cleanup-infrastructure.sh
```

## Comandos de Verificação

```bash
# Status das instâncias
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=TF09-Portfolio-*" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress]' \
    --output table

# Logs da aplicação
ssh -i infrastructure/${KEY_NAME}.pem ec2-user@${WEB_PUBLIC_IP} \
    "sudo docker-compose -f ~/app/docker-compose.yml logs --tail=20"
```

## Troubleshooting

| Problema | Causa provável | Solução |
|---|---|---|
| SSH recusado | IP mudou | Atualizar regra SSH no Security Group |
| `/health` retorna 503 | Banco não acessível | Verificar IP privado no `.env` |
| Página não carrega | Nginx não iniciou | `sudo docker-compose ps` na instância |
| Timeout na porta 80 | Security Group | Verificar regra HTTP no Web SG |
