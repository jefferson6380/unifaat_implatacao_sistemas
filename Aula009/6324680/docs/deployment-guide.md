# Guia de Deploy — TF09

## Pré-requisitos

- Conta AWS com Free Tier ativo
- AWS CLI configurado (`aws configure`)
- Docker e Docker Compose instalados na EC2
- Git instalado localmente

---

## Passo 1: Criar a infraestrutura

```bash
cd infrastructure/
chmod +x create-infrastructure.sh
./create-infrastructure.sh
```

Ao final, o script imprime o IP público da instância e o comando SSH.

---

## Passo 2: Conectar à instância via SSH

```bash
ssh -i ~/.ssh/tf09-vitor-key.pem ec2-user@<IP_PUBLICO>
```

---

## Passo 3: Instalar Docker na EC2

```bash
sudo yum update -y
sudo yum install -y docker git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ec2-user
# Desconecte e reconecte para aplicar o grupo

# Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

---

## Passo 4: Clonar e subir a aplicação

```bash
git clone https://github.com/<SEU_USUARIO>/<SEU_REPO>.git ~/app
cd ~/app/Aula009/6324680/application
cp .env.example .env
docker-compose up -d
```

---

## Passo 5: Verificar

```bash
# Health check
curl http://localhost:5000/health

# Projetos
curl http://localhost:5000/api/projects
```

Acesse no navegador: `http://<IP_PUBLICO>:5000`

---

## Passo 6: Limpar após avaliação

```bash
# Na sua máquina local:
cd infrastructure/
./cleanup-infrastructure.sh
```

---

## Comandos de verificação

```bash
# Ver instâncias ativas
aws ec2 describe-instances --filters "Name=tag:Name,Values=tf09-vitor-web" \
  --query 'Reservations[].Instances[].{ID:InstanceId,IP:PublicIpAddress,State:State.Name}'

# Ver security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=tf09-vitor-sg-*"

# Ver VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tf09-vitor-vpc"
```
