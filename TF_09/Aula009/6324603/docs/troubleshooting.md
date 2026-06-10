# Troubleshooting Guide - TF09 Portfólio AWS

**Aluno:** Allison Henrique da Silva Oliveira | RA: 6324603

---

## Problemas de Infraestrutura

### EC2 não inicia
```bash
# Verificar eventos da instância
aws ec2 describe-instance-status \
  --instance-ids $INSTANCE_ID \
  --include-all-instances

# Ver log do sistema
aws ec2 get-console-output --instance-id $INSTANCE_ID
```

### Não consigo conectar via SSH
```bash
# 1. Verificar se o IP mudou
curl https://checkip.amazonaws.com

# 2. Atualizar regra SSH no Security Group
aws ec2 revoke-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 22 --cidr <IP-ANTIGO>/32

aws ec2 authorize-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 22 --cidr <SEU-NOVO-IP>/32

# 3. Verificar permissão da chave
chmod 400 portfolio-key.pem

# 4. Testar conexão com verbose
ssh -v -i portfolio-key.pem ec2-user@$PUBLIC_IP
```

### Script de criação falha no meio
```bash
# Verificar o que foi criado
cat infrastructure-ids.env

# Executar cleanup e recomeçar
./cleanup-infrastructure.sh
./create-infrastructure.sh
```

---

## Problemas de Aplicação

### Containers não sobem
```bash
# Ver logs detalhados
docker-compose logs backend
docker-compose logs frontend

# Verificar se Docker está rodando
sudo systemctl status docker

# Reiniciar containers
docker-compose down && docker-compose up -d
```

### API retorna 502 Bad Gateway
```bash
# Backend pode não ter iniciado ainda
docker-compose ps
docker-compose logs backend

# Verificar se porta 3000 está em uso
ss -tlnp | grep 3000
```

### Frontend não carrega
```bash
# Verificar se Nginx está rodando
docker-compose ps frontend

# Testar diretamente
curl http://localhost:80
curl http://localhost:3000/api/health
```

### Banco de dados com erro
```bash
# Verificar volume
docker volume ls
docker volume inspect 6324603_db-data

# Acessar container e verificar DB
docker exec -it portfolio-api sh
ls -la /app/data/
```

---

## Problemas de Rede

### Aplicação não acessível pelo browser
```bash
# 1. Verificar Security Group
aws ec2 describe-security-groups --group-ids $SG_WEB_ID

# 2. Verificar se EC2 tem IP público
aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress'

# 3. Testar da EC2 localmente
curl http://localhost:80
curl http://localhost:3000/api/health
```

### Route Table não funciona
```bash
# Verificar rotas
aws ec2 describe-route-tables --route-table-ids $PUBLIC_RT_ID

# Verificar associação com subnet
aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET_ID
```

---

## Limpeza de Recursos Órfãos

Se o cleanup falhar, remova manualmente nesta ordem:

```bash
# 1. Terminar EC2
aws ec2 terminate-instances --instance-ids <ID>
aws ec2 wait instance-terminated --instance-ids <ID>

# 2. Deletar Key Pair
aws ec2 delete-key-pair --key-name portfolio-key

# 3. Deletar Security Groups
aws ec2 delete-security-group --group-id <SG-DB-ID>
aws ec2 delete-security-group --group-id <SG-WEB-ID>

# 4. Desassociar e deletar Route Tables
aws ec2 disassociate-route-table --association-id <ASSOC-ID>
aws ec2 delete-route-table --route-table-id <RT-ID>

# 5. Desanexar e deletar IGW
aws ec2 detach-internet-gateway --internet-gateway-id <IGW-ID> --vpc-id <VPC-ID>
aws ec2 delete-internet-gateway --internet-gateway-id <IGW-ID>

# 6. Deletar Subnets
aws ec2 delete-subnet --subnet-id <SUBNET-ID>

# 7. Deletar VPC
aws ec2 delete-vpc --vpc-id <VPC-ID>
```

### Verificar recursos restantes
```bash
# Listar todas as VPCs do projeto
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=portfolio-tf09"

# Listar instâncias do projeto
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=portfolio-tf09" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name]'
```
