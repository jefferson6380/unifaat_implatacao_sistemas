# Troubleshooting Lab 6 - EC2 e Security Groups

**Lab:** 006 - EC2 e Security Groups  
**Foco:** Instâncias EC2, SSH, grupos de segurança

---

## 🚨 Problemas Mais Comuns

### 1. Não Consegue Conectar via SSH

#### **Sintoma:**
```bash
ssh -i key.pem ec2-user@ip-publico
# Connection timed out
# Permission denied (publickey)
```

#### **Diagnóstico:**
```bash
# Verifica se instância está rodando
aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# Testa conectividade
ping ip-publico
telnet ip-publico 22
```

#### **Soluções:**

**Problema: Permissões da chave**
```bash
chmod 400 key.pem
ssh -i key.pem ec2-user@ip-publico
```

**Problema: Security Group**
```bash
# Verifica regras do Security Group
aws ec2 describe-security-groups --group-ids sg-12345678

# Adiciona regra SSH
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

**Problema: Usuário incorreto**
```bash
# Amazon Linux: ec2-user
# Ubuntu: ubuntu
# CentOS: centos
ssh -i key.pem ubuntu@ip-publico
```

### 2. Instância não Inicia

#### **Sintoma:**
- Status "pending" por muito tempo
- Status "terminated" inesperadamente

#### **Diagnóstico:**
```bash
# Verifica status detalhado
aws ec2 describe-instance-status --instance-ids i-1234567890abcdef0

# Verifica logs de sistema
aws ec2 get-console-output --instance-id i-1234567890abcdef0
```

#### **Soluções:**
```bash
# Verifica limites da conta
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A

# Tenta região diferente
aws ec2 run-instances --region us-west-2 ...
```

### 3. Aplicação não Acessível

#### **Sintoma:**
- SSH funciona mas aplicação web não carrega
- "Connection refused" na porta 80/443

#### **Soluções:**
```bash
# Adiciona regra HTTP ao Security Group
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Verifica se aplicação está rodando na instância
ssh -i key.pem ec2-user@ip-publico
sudo systemctl status nginx
sudo netstat -tulpn | grep :80
```

### 4. Instância Lenta ou Travando

#### **Sintoma:**
- SSH demora para conectar
- Comandos demoram para executar

#### **Diagnóstico:**
```bash
# Verifica métricas no CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

#### **Soluções:**
```bash
# Upgrade do tipo de instância
aws ec2 modify-instance-attribute \
  --instance-id i-1234567890abcdef0 \
  --instance-type t3.medium

# Adiciona swap se necessário
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### 5. Key Pair Perdida

#### **Sintoma:**
- Não consegue mais acessar instância
- Arquivo .pem foi deletado

#### **Soluções:**
```bash
# Cria nova key pair
aws ec2 create-key-pair --key-name nova-key --query 'KeyMaterial' --output text > nova-key.pem
chmod 400 nova-key.pem

# Para instância existente: precisa criar nova instância
# Ou usar Session Manager se configurado
aws ssm start-session --target i-1234567890abcdef0
```

---

**Desenvolvido por:** Professor Alexandre Tavares - UniFAAT