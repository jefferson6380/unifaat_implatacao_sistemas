# Troubleshooting - TF09

**Aluno:** Luan Teixeira | **RA:** 6322504

## Problemas de Conexão SSH

### "Permission denied (publickey)"
```bash
# Verificar permissões da chave
chmod 400 TF09-KeyPair.pem

# Confirmar usuário correto (Amazon Linux usa ec2-user)
ssh -i TF09-KeyPair.pem ec2-user@<IP>
```

### "Connection timed out"
```bash
# Verificar se regra SSH existe no Security Group
aws ec2 describe-security-groups --group-ids <WEB_SG_ID> \
    --query 'SecurityGroups[0].IpPermissions'

# Verificar seu IP atual
curl https://checkip.amazonaws.com

# Atualizar regra SSH se IP mudou
aws ec2 authorize-security-group-ingress \
    --group-id <WEB_SG_ID> --protocol tcp --port 22 --cidr <SEU_IP>/32
```

## Problemas com Docker

### Aplicação não inicia
```bash
sudo systemctl status docker
sudo systemctl start docker
sudo docker-compose logs
```

### Porta 80 já em uso
```bash
sudo lsof -i :80
sudo docker-compose down && sudo docker-compose up -d
```

## Problemas de Banco de Dados

### "Connection refused" ao conectar no MySQL
```bash
# Verificar se instância DB está running
aws ec2 describe-instances --instance-ids <DB_INSTANCE_ID> \
    --query 'Reservations[0].Instances[0].State.Name'

# Do web server, testar conectividade
telnet <DB_PRIVATE_IP> 3306

# Verificar logs de user-data na instância DB
aws ec2 get-console-output --instance-id <DB_INSTANCE_ID>
```

### Verificar logs do user-data
```bash
sudo cat /var/log/cloud-init-output.log
sudo cat /var/log/user-data.log
```

## Verificar Status Geral

```bash
# Todas as instâncias TF09
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=TF09-*" \
    --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value|[0],State.Name,PublicIpAddress,PrivateIpAddress]' \
    --output table

# Health check da aplicação
curl -v http://<WEB_PUBLIC_IP>/health
```
