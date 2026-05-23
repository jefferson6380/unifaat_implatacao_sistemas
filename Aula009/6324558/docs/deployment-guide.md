# Deployment Guide - TF09

## Pré-requisitos

- AWS CLI v2 instalada ([download](https://awscli.amazonaws.com/AWSCLIV2.msi))
- Credenciais IAM configuradas com permissões EC2
- Git Bash (Windows) ou terminal Linux/Mac
- Docker instalado localmente (para testes)

---

## Troque de nome o .env:
 .env.example -> .env

## Passo a Passo

### 1. Configurar AWS CLI
```bash
aws configure
# AWS Access Key ID: <sua chave>
# AWS Secret Access Key: <seu secret>
# Default region: us-east-1
# Default output format: json
```

Verificar autenticação:
```bash
aws sts get-caller-identity
```

### 2. Criar Infraestrutura
```bash
cd infrastructure/
./create-infrastructure.sh
```

O script cria automaticamente:
- VPC com CIDR 10.0.0.0/16
- Subnet pública (10.0.1.0/24) e privada (10.0.2.0/24)
- Internet Gateway e Route Table
- Security Group com porta 80 aberta e SSH restrito ao IP do aluno
- Key Pair tf09-key.pem
- Instância EC2 t3.micro com Docker instalado

Ao final, o script exibe o IP público da EC2 e salva todos os IDs em `tf09-ids.env`.

### 3. Transferir Aplicação para EC2
```bash
scp -i tf09-key.pem -r ../application ec2-user@<IP_EC2>:~/
```

### 4. Conectar na EC2
```bash
ssh -i tf09-key.pem ec2-user@<IP_EC2>
```

### 5. Atualizar Docker Buildx (necessário no Amazon Linux 2)
```bash
mkdir -p ~/.docker/cli-plugins
curl -L https://github.com/docker/buildx/releases/download/v0.19.3/buildx-v0.19.3.linux-amd64 \
  -o ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
```

### 6. Subir a Aplicação
```bash
cd ~/application
docker-compose up --build -d
```

Aguardar todos os containers ficarem `Healthy` (aproximadamente 2 minutos).

### 7. Verificar Deploy
```bash
# Health check
curl http://<IP_EC2>/api/health

# Projetos
curl http://<IP_EC2>/api/projects

# Habilidades
curl http://<IP_EC2>/api/skills
```

---

## Comandos de Verificação

```bash
# Status dos containers na EC2
docker ps

# Logs da API
docker logs application-node-api-1

# Logs do Nginx
docker logs application-nginx-1
```

---

## Limpeza de Recursos

Após a avaliação, destruir toda a infraestrutura:
```bash
cd infrastructure/
./cleanup-infrastructure.sh
```

O script remove em ordem: EC2 → Key Pair → Security Group → Route Table → IGW → Subnets → VPC.

---

## Troubleshooting

| Problema | Solução |
|---|---|
| `docker: command not found` | Aguardar 2 min após SSH — o user-data ainda está rodando |
| `compose build requires buildx 0.17.0` | Executar o passo 5 (atualizar buildx) |
| Site não abre no navegador | Verificar se a porta 80 está liberada no Security Group |
| API retorna 502 | Containers ainda inicializando — aguardar e testar novamente |