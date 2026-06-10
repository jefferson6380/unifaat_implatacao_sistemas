# Troubleshooting - TF10 Northwind RDS

## Erro: "could not connect to server: Connection refused"

**Causa:** Security Group não permite conexão na porta 5432.

**Solução:**
```bash
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp --port 5432 \
  --cidr "${MY_IP}/32"
```

---

## Erro: "FATAL: password authentication failed for user postgres"

**Causa:** Senha incorreta ou usuário não existe.

**Solução:**
```bash
aws rds modify-db-instance \
  --db-instance-identifier northwind-rds \
  --master-user-password "NovaSenh@2026!" \
  --apply-immediately
```

---

## Erro: "pg_dump: error: query failed: ERROR: permission denied"

**Causa:** Usuário local sem permissão de leitura em alguma tabela.

**Solução:** Usar superusuário `postgres` no dump:
```bash
PGPASSWORD=postgres pg_dump -h localhost -p 2001 -U postgres -d northwind --no-owner --no-acl -f dump.sql
```

---

## Erro: "DB Subnet Group doesn't meet AZ coverage requirement"

**Causa:** As subnets estão na mesma AZ.

**Solução:** Garantir que as duas subnets estejam em AZs diferentes (`us-east-1a` e `us-east-1b`).

---

## Erro: "InvalidParameterCombination: Cannot specify a publicly accessible DB instance in a VPC without an Internet Gateway"

**Causa:** A VPC não tem Internet Gateway associado.

**Solução:** Usar a VPC padrão (já tem IGW) ou adicionar IGW à VPC customizada.
