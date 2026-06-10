# Troubleshooting — TF09

## Problemas Comuns

---

### SSH: "Permission denied (publickey)"

**Causa:** Chave errada ou permissões incorretas no arquivo.

```bash
# Verificar permissão da chave
ls -la ~/.ssh/tf09-vitor-key.pem
# Deve ser -r-------- (400)

# Corrigir se necessário
chmod 400 ~/.ssh/tf09-vitor-key.pem

# Conectar com verbose para debug
ssh -vvv -i ~/.ssh/tf09-vitor-key.pem ec2-user@<IP>
```

---

### SSH: "Connection timed out"

**Causa:** Security Group bloqueando o IP ou instância não está rodando.

```bash
# Verificar se seu IP mudou
curl https://checkip.amazonaws.com

# Atualizar regra SSH no Security Group
aws ec2 authorize-security-group-ingress \
  --group-id <SG_WEB_ID> \
  --protocol tcp --port 22 \
  --cidr $(curl -s https://checkip.amazonaws.com)/32

# Verificar estado da instância
aws ec2 describe-instances --instance-ids <INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].State.Name'
```

---

### Aplicação não acessível no navegador

**Causa:** Docker não subiu ou porta bloqueada.

```bash
# Na EC2, verificar containers
docker-compose ps
docker-compose logs web

# Testar localmente na EC2
curl http://localhost:5000/health

# Verificar se porta 5000 está aberta no SG
aws ec2 describe-security-groups --group-ids <SG_WEB_ID> \
  --query 'SecurityGroups[0].IpPermissions'
```

---

### Script de criação falha: "VPCIdNotSpecified" ou similar

**Causa:** Recurso anterior não foi limpo corretamente.

```bash
# Listar VPCs existentes com a tag do projeto
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=tf09-vitor-vpc"

# Rodar limpeza primeiro
./cleanup-infrastructure.sh

# Depois criar novamente
./create-infrastructure.sh
```

---

### "Unable to locate credentials"

**Causa:** AWS CLI não configurado.

```bash
aws configure list
aws configure
# Inserir: Access Key, Secret Key, região us-east-1, formato json
```

---

### Docker Compose: "permission denied"

**Causa:** Usuário não está no grupo docker.

```bash
sudo usermod -aG docker ec2-user
# Sair e reconectar SSH
exit
ssh -i ~/.ssh/tf09-vitor-key.pem ec2-user@<IP>
```
