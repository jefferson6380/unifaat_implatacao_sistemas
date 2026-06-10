# Troubleshooting Lab 9 - RDS e Banco de Dados

**Lab:** 009 - RDS e Banco de Dados  
**Foco:** Banco de dados gerenciado, conexões, backup

---

## 🚨 Problemas Mais Comuns

### 1. Não Consegue Conectar no RDS

#### **Sintoma:**
```bash
mysql -h endpoint.rds.amazonaws.com -u admin -p
# ERROR 2003: Can't connect to MySQL server
```

#### **Diagnóstico:**
```bash
# Verifica status da instância
aws rds describe-db-instances --db-instance-identifier minha-db

# Testa conectividade
telnet endpoint.rds.amazonaws.com 3306
```

#### **Soluções:**

**Problema: Security Group**
```bash
# Adiciona regra MySQL/PostgreSQL
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 3306 \
  --source-group sg-87654321
```

**Problema: Subnet Group**
```bash
# Verifica subnet group
aws rds describe-db-subnet-groups --db-subnet-group-name default

# Cria novo subnet group se necessário
aws rds create-db-subnet-group \
  --db-subnet-group-name meu-subnet-group \
  --db-subnet-group-description "Meu subnet group" \
  --subnet-ids subnet-12345678 subnet-87654321
```

### 2. Credenciais Incorretas

#### **Sintoma:**
- "Access denied for user"
- "authentication failed"

#### **Soluções:**
```bash
# Verifica master username
aws rds describe-db-instances --db-instance-identifier minha-db \
  --query 'DBInstances[0].MasterUsername'

# Reset da senha (causa downtime)
aws rds modify-db-instance \
  --db-instance-identifier minha-db \
  --master-user-password nova-senha \
  --apply-immediately
```

### 3. Instância RDS Lenta

#### **Sintoma:**
- Queries demoram muito
- Timeouts de conexão

#### **Diagnóstico:**
```bash
# Verifica métricas
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=minha-db \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 3600 \
  --statistics Average
```

#### **Soluções:**
```bash
# Upgrade da instância
aws rds modify-db-instance \
  --db-instance-identifier minha-db \
  --db-instance-class db.t3.medium \
  --apply-immediately

# Habilita Performance Insights
aws rds modify-db-instance \
  --db-instance-identifier minha-db \
  --enable-performance-insights
```

### 4. Backup/Restore Falha

#### **Sintoma:**
- Snapshot não é criado
- Restore falha

#### **Soluções:**
```bash
# Cria snapshot manual
aws rds create-db-snapshot \
  --db-instance-identifier minha-db \
  --db-snapshot-identifier minha-db-snapshot-$(date +%Y%m%d)

# Verifica status do snapshot
aws rds describe-db-snapshots --db-snapshot-identifier minha-db-snapshot-20240101

# Restaura de snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier nova-db \
  --db-snapshot-identifier minha-db-snapshot-20240101
```

### 5. Multi-AZ não Funciona

#### **Sintoma:**
- Failover não acontece
- Downtime durante manutenção

#### **Soluções:**
```bash
# Habilita Multi-AZ
aws rds modify-db-instance \
  --db-instance-identifier minha-db \
  --multi-az \
  --apply-immediately

# Força failover para testar
aws rds reboot-db-instance \
  --db-instance-identifier minha-db \
  --force-failover
```

### 6. Erro de Charset/Encoding

#### **Sintoma:**
- Caracteres especiais não salvam corretamente
- "Incorrect string value" error

#### **Soluções:**
```bash
# Verifica charset atual
mysql -h endpoint.rds.amazonaws.com -u admin -p -e "SHOW VARIABLES LIKE 'character_set%';"

# Cria DB parameter group com UTF-8
aws rds create-db-parameter-group \
  --db-parameter-group-name utf8-params \
  --db-parameter-group-family mysql8.0 \
  --description "UTF-8 parameters"

# Modifica parâmetros
aws rds modify-db-parameter-group \
  --db-parameter-group-name utf8-params \
  --parameters "ParameterName=character_set_server,ParameterValue=utf8mb4,ApplyMethod=immediate"
```

---

**Desenvolvido por:** Professor Alexandre Tavares - UniFAAT