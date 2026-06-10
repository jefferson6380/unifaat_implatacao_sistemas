# Substituir <IP> pelo IP real da instância
curl http://<IP>/api/health
curl http://<IP>
# Substituir <IP> pelo IP real da instância
curl http://<IP>/api/health
curl http://<IP>
cd infrastructure
chmod +x deploy.sh setup-vpc.sh
./setup-vpc.sh
./deploy.sh
# Substituir <IP> pelo IP real da instância
curl http://<IP>/api/health
curl http://<IP>
# Troubleshooting

## Problemas Comuns

### 1. Aplicação não responde após deploy

**Sintoma:** `curl http://<IP>/api/health` retorna connection refused

**Diagnóstico:**
```bash
# Verificar se a instância está running
aws ec2 describe-instances --instance-ids <INSTANCE_ID> \
  --query 'Reservations[0].Instances[0].State.Name'

# Verificar logs do user-data
ssh -i portfolio-keypair.pem ec2-user@<IP>
sudo cat /var/log/cloud-init-output.log | tail -50
```

**Solução:** Aguardar mais 2-3 minutos. O user-data pode demorar para instalar Docker.

---

### 2. Erro de permissão na chave SSH

**Sintoma:** `WARNING: UNPROTECTED PRIVATE KEY FILE!`

**Solução:**
```bash
chmod 400 infrastructure/portfolio-keypair.pem
```

---

### 3. SSH: Connection timed out

**Sintoma:** Timeout ao tentar conectar via SSH

**Diagnóstico:**
```bash
# Verificar seu IP atual
curl https://checkip.amazonaws.com

# Verificar regra SSH no Security Group
aws ec2 describe-security-groups --group-ids <SG_WEB_ID> \
  --query 'SecurityGroups[0].IpPermissions'
```

**Solução:** Atualizar a regra SSH com o IP atual:
```bash
# Remover regra antiga
aws ec2 revoke-security-group-ingress --group-id <SG_ID> \
  --protocol tcp --port 22 --cidr <IP-ANTIGO>/32

# Adicionar novo IP
aws ec2 authorize-security-group-ingress --group-id <SG_ID> \
  --protocol tcp --port 22 --cidr <SEU-IP-ATUAL>/32
```

---

### 4. Containers não sobem

**Sintoma:** `docker-compose ps` mostra containers parados

**Diagnóstico:**
```bash
ssh -i portfolio-keypair.pem ec2-user@<IP>
cd /home/ec2-user/app/application
docker-compose logs
```

**Solução comum:** Verificar se o arquivo `.env` existe e tem os valores corretos.

---

### 5. Erro no script de cleanup: route table association

**Sintoma:** `InvalidAssociationID.NotFound`

**Solução:** A subnet pode não ter associação explícita (usa a default). Ignorar o erro e continuar:
```bash
aws ec2 delete-route-table --route-table-id <RT_ID> 2>/dev/null || true
```

---

### 6. VPC não pode ser deletada

**Sintoma:** `DependencyViolation` ao deletar VPC

**Diagnóstico:** Verificar recursos ainda associados:
```bash
# Verificar ENIs
aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=<VPC_ID>"

# Verificar instâncias
aws ec2 describe-instances --filters "Name=vpc-id,Values=<VPC_ID>" \
  "Name=instance-state-name,Values=running,stopped"
```

**Solução:** Terminar todas as instâncias e aguardar antes de deletar a VPC.
