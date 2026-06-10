# Deployment Guide - TF09 Portfólio AWS

**Aluno:** Allison Henrique da Silva Oliveira | RA: 6324603

---

## Pré-requisitos

### Para rodar localmente (Docker)
- Docker Desktop instalado e rodando
- Git instalado

### Para deploy na AWS
- AWS CLI instalado (`aws --version`)
- Conta AWS configurada (`aws configure`)
- Git Bash ou WSL no Windows
- Docker instalado

---

## Opção A — Rodar Localmente com Docker

### Passo 1 — Clonar o repositório
```bash
git clone <url-do-repositorio>
cd Aula009/6324603
```

### Passo 2 — Subir a aplicação
```bash
cd application/
docker-compose up -d --build
```

### Passo 3 — Verificar se está rodando
```bash
docker-compose ps
```
Deve mostrar dois containers com status `Up`:
- `portfolio-api` (backend Node.js)
- `portfolio-frontend` (Nginx)

### Passo 4 — Acessar no navegador
- **Portfólio:** http://localhost:9000
- **Health Check:** http://localhost:4000/api/health
- **Projetos:** http://localhost:4000/api/projects

### Passo 5 — Ver logs
```bash
docker-compose logs -f
```

### Passo 6 — Parar
```bash
docker-compose down
```

---

## Opção B — Deploy na AWS com EC2

### Passo 1 — Configurar AWS CLI
```bash
aws configure
# AWS Access Key ID: <sua chave>
# AWS Secret Access Key: <sua chave secreta>
# Default region name: us-east-1
# Default output format: json
```

### Passo 2 — Criar infraestrutura
```bash
cd infrastructure/
chmod +x create-infrastructure.sh cleanup-infrastructure.sh
./create-infrastructure.sh
```

O script cria automaticamente:
- VPC `10.0.0.0/16`
- Subnet pública `10.0.1.0/24` (us-east-1a)
- Subnet privada `10.0.2.0/24` (us-east-1b)
- Internet Gateway
- Route Tables (pública e privada)
- Security Group Web Server (portas 22, 80, 443, 3000)
- Security Group Database (porta 5432 apenas do web server)
- Key Pair `portfolio-key.pem`
- EC2 t3.micro com Amazon Linux 2

Ao final exibe:
```
IP Público da EC2: X.X.X.X
SSH: ssh -i portfolio-key.pem ec2-user@X.X.X.X
App: http://X.X.X.X
```

### Passo 3 — Aguardar EC2 inicializar
```bash
# Aguardar ~2 minutos para o Docker ser instalado automaticamente
source infrastructure-ids.env
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID
```

### Passo 4 — Copiar aplicação para EC2
```bash
source infrastructure-ids.env
scp -i portfolio-key.pem -r ../application/ ec2-user@$PUBLIC_IP:~/app/
```

### Passo 5 — Acessar EC2 e fazer deploy
```bash
ssh -i portfolio-key.pem ec2-user@$PUBLIC_IP

# Dentro da EC2:
cd ~/app
cp .env.example .env
docker-compose up -d
```

### Passo 6 — Verificar funcionamento
```bash
# Health check
curl http://$PUBLIC_IP/api/health

# Listar projetos
curl http://$PUBLIC_IP/api/projects

# Status dos containers
docker-compose ps
```

### Passo 7 — Acessar no navegador
```
http://<IP_PUBLICO_EC2>
```

---

## Comandos de Verificação

```bash
# Status dos containers
docker-compose ps

# Logs em tempo real
docker-compose logs -f

# Testar criação de projeto via API
curl -X POST http://localhost:4000/api/projects \
  -H "Content-Type: application/json" \
  -d '{"name":"Meu Projeto","description":"Descrição do projeto","technologies":"Node.js, AWS"}'

# Testar remoção de projeto
curl -X DELETE http://localhost:4000/api/projects/1
```

---

## Limpeza de Recursos AWS

```bash
cd infrastructure/
./cleanup-infrastructure.sh
```

Confirme no AWS Console que não há recursos em:
- EC2 → Instances
- VPC → Your VPCs
- EC2 → Key Pairs
- EC2 → Security Groups

---

## Troubleshooting Rápido

| Problema | Solução |
|----------|---------|
| Porta já em uso | Editar `docker-compose.yml` e trocar a porta |
| Container não sobe | `docker-compose logs backend` para ver o erro |
| SSH recusado na EC2 | Atualizar regra SSH no Security Group com seu IP atual |
| App não abre no browser | Verificar se Security Group libera porta 80 |
| `permission denied` na chave | `chmod 400 portfolio-key.pem` |

Veja mais detalhes em `docs/troubleshooting.md`.
