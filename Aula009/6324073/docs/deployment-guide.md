# Deployment Guide

## Pré-requisitos
- Conta AWS ativa.
- AWS CLI instalado e configurado.
- Docker e Docker Compose instalados na máquina de destino (EC2).

## Passo a Passo

### 1. Provisionamento
Execute o script de criação:
```bash
chmod +x infrastructure/create-infrastructure.sh
./infrastructure/create-infrastructure.sh
```

### 2. Preparação da EC2
Acesse a instância via SSH:
```bash
ssh -i "sua-chave.pem" ec2-user@<IP-DA-INSTANCIA>
```

Instale o Docker:
```bash
sudo yum update -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo usermod -a -G docker ec2-user
```

### 3. Deploy da Aplicação
Clone este repositório e execute:
```bash
docker-compose up -d
```

## Verificação
Acesse `http://<IP-DA-INSTANCIA>/health` para validar o health check.
