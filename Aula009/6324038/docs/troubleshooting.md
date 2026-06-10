# Troubleshooting - TF09 Portfólio AWS

## Infraestrutura

### Instância não inicia / fica em "pending"

```bash
# Verificar status e mensagem de erro
aws ec2 describe-instances --instance-ids $WEB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].{State:State.Name,Reason:StateTransitionReason}'

# Ver output do console (user data logs)
aws ec2 get-console-output --instance-id $WEB_INSTANCE_ID --output text
```

### Não consegue conectar via SSH

```bash
# 1. Confirmar IP público atual
aws ec2 describe-instances --instance-ids $WEB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

# 2. Verificar regra SSH no Security Group
aws ec2 describe-security-groups --group-ids $WEB_SG_ID \
    --query 'SecurityGroups[0].IpPermissions'

# 3. Atualizar regra SSH com IP atual
MY_IP=$(curl -s https://checkip.amazonaws.com)
# Remover regra antiga e adicionar nova com IP atual
aws ec2 revoke-security-group-ingress --group-id $WEB_SG_ID \
    --protocol tcp --port 22 --cidr 0.0.0.0/0  # ajuste o CIDR antigo
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID \
    --protocol tcp --port 22 --cidr ${MY_IP}/32
```

## Aplicação

### Health check retorna 503 (banco inacessível)

```bash
# Na instância web, testar conectividade com o banco
ssh -i TF09-Portfolio-KeyPair.pem ec2-user@$WEB_PUBLIC_IP

# Dentro da instância:
nc -zv $DB_PRIVATE_IP 3306   # deve conectar
cat ~/app/.env               # verificar DB_HOST
sudo docker-compose logs app # ver erro específico
```

### Página não carrega (timeout na porta 80)

```bash
# Verificar se Nginx está rodando
ssh -i TF09-Portfolio-KeyPair.pem ec2-user@$WEB_PUBLIC_IP \
    "sudo docker-compose -f ~/app/docker-compose.yml ps"

# Verificar Security Group
aws ec2 describe-security-groups --group-ids $WEB_SG_ID \
    --query 'SecurityGroups[0].IpPermissions[?FromPort==`80`]'
```

### Docker Compose não encontrado

```bash
# Verificar se user data terminou
sudo cat /var/log/user-data.log

# Instalar manualmente se necessário
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Limpeza

### Recursos não deletados (erro de dependência)

```bash
# Verificar se instâncias foram terminadas antes de deletar SGs
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=TF09-Portfolio-*" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
    --output table

# Aguardar terminação completa
aws ec2 wait instance-terminated --instance-ids $WEB_INSTANCE_ID $DB_INSTANCE_ID
```

### Verificar recursos órfãos após cleanup

```bash
# Listar todos os recursos com a tag do projeto
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=TF09-Portfolio-VPC" \
    --query 'Vpcs[].VpcId' --output text

aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=TF09-Portfolio-*" "Name=instance-state-name,Values=running,stopped,pending" \
    --query 'Reservations[].Instances[].InstanceId' --output text
```
