# Guia de Deploy - TF09 Portfólio Pessoal

**Aluno:** Luan Teixeira | **RA:** 6322504

## Pré-requisitos

- AWS CLI instalado e configurado (`aws configure`)
- Conta AWS com permissões EC2 e VPC
- Bash (Linux/macOS) ou Git Bash (Windows)

## Passo a Passo

### 1. Criar Infraestrutura

```bash
cd infrastructure/
chmod +x create-infrastructure.sh
./create-infrastructure.sh
```

Anote os IPs exibidos ao final do script.

### 2. Conectar ao Web Server

```bash
ssh -i TF09-KeyPair.pem ec2-user@<WEB_PUBLIC_IP>
```

### 3. Deploy da Aplicação

Na instância EC2:

```bash
# Criar diretório da aplicação
mkdir -p ~/app && cd ~/app

# Clonar ou transferir os arquivos (via scp):
# scp -i TF09-KeyPair.pem -r application/ ec2-user@<IP>:~/app/

# Criar arquivo .env
cat > .env << EOF
DB_HOST=<DB_PRIVATE_IP>
DB_USER=appuser
DB_PASSWORD=SecurePass123!
DB_NAME=portfoliodb
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
EOF

# Subir a aplicação
sudo docker-compose up -d --build
```

### 4. Verificar Deploy

```bash
# Status dos containers
sudo docker-compose ps

# Logs
sudo docker-compose logs

# Health check
curl http://localhost/health
```

### 5. Acesso via Navegador

Acesse: `http://<WEB_PUBLIC_IP>`

## Comandos de Verificação

```bash
# Verificar instâncias ativas
aws ec2 describe-instances --filters "Name=tag:Name,Values=TF09-*" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress]' \
    --output table

# Verificar Security Groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=TF09-*" \
    --query 'SecurityGroups[].[GroupName,GroupId]' --output table

# Testar API
curl http://<WEB_PUBLIC_IP>/api/info
curl http://<WEB_PUBLIC_IP>/health
```

## Troubleshooting

| Problema | Causa Provável | Solução |
|---|---|---|
| SSH recusado | IP mudou ou SG errado | Atualizar regra SSH no Security Group |
| App não carrega | Docker não iniciou | `sudo systemctl start docker && sudo docker-compose up -d` |
| Erro de banco | DB_HOST errado no .env | Verificar IP privado da instância DB |
| Timeout no browser | Porta 80 bloqueada | Verificar regra HTTP no Web SG |

## Limpeza

```bash
cd infrastructure/
chmod +x cleanup-infrastructure.sh
./cleanup-infrastructure.sh
```
