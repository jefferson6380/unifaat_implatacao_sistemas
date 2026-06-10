# Security Analysis - TF09 Portfólio AWS

**Aluno:** Allison Henrique da Silva Oliveira | RA: 6324603

---

## 1. Medidas de Segurança Implementadas

### 1.1 Isolamento de Rede com VPC Customizada

A infraestrutura utiliza uma VPC dedicada (`10.0.0.0/16`) em vez da VPC padrão da AWS. Isso garante:
- Controle total sobre o espaço de endereçamento IP
- Isolamento completo de outras contas e recursos AWS
- Capacidade de definir regras de roteamento específicas

### 1.2 Segmentação com Subnets Públicas e Privadas

| Subnet | CIDR | Acesso à Internet | Uso |
|--------|------|-------------------|-----|
| Pública | `10.0.1.0/24` | Sim (via IGW) | Web Server / EC2 |
| Privada | `10.0.2.0/24` | Não | Database |

A subnet privada não possui rota para o Internet Gateway, impedindo acesso direto da internet ao banco de dados.

### 1.3 Security Groups com Princípio do Menor Privilégio

#### Security Group - Web Server
```
Inbound:
  TCP 22   ← SEU_IP/32      (SSH restrito ao administrador)
  TCP 80   ← 0.0.0.0/0      (HTTP público)
  TCP 443  ← 0.0.0.0/0      (HTTPS público)
  TCP 3000 ← 0.0.0.0/0      (API pública)

Outbound:
  All ← 0.0.0.0/0           (saída necessária para updates e dependências)
```

#### Security Group - Database
```
Inbound:
  TCP 5432 ← sg-webserver   (apenas o web server acessa o DB)

Outbound:
  All ← 10.0.0.0/16         (apenas tráfego interno à VPC)
```

**Justificativa:** O banco de dados só aceita conexões originadas do Security Group do web server, não de IPs específicos. Isso é mais seguro pois funciona mesmo se o IP da EC2 mudar.

### 1.4 SSH Key Management

- Key Pair RSA gerado via AWS CLI
- Chave privada `.pem` com permissão `chmod 400` (somente leitura pelo dono)
- Acesso SSH liberado **apenas para o IP público do administrador** (`/32`)
- Chave privada **nunca commitada** no repositório (`.gitignore`)

### 1.5 Logs Estruturados

- Backend registra todas as requisições em formato JSON
- Nginx registra acessos e erros
- Logs disponíveis via `docker-compose logs`

---

## 2. Justificativa das Regras de Security Groups

| Regra | Justificativa |
|-------|---------------|
| SSH apenas do IP admin | Evita ataques de força bruta SSH de qualquer IP |
| HTTP/HTTPS público | Necessário para acesso ao portfólio |
| DB apenas do SG web | Banco nunca exposto à internet |
| Egress DB restrito à VPC | Impede exfiltração de dados pelo banco |

---

## 3. Possíveis Melhorias

| Melhoria | Benefício | Complexidade |
|----------|-----------|--------------|
| Habilitar HTTPS com certificado SSL (Let's Encrypt) | Criptografia em trânsito | Média |
| Usar AWS Secrets Manager para credenciais | Elimina segredos em variáveis de ambiente | Média |
| Implementar AWS WAF na frente da EC2 | Proteção contra ataques web (SQLi, XSS) | Alta |
| Habilitar VPC Flow Logs | Auditoria de tráfego de rede | Baixa |
| Usar Bastion Host para SSH | Elimina exposição SSH direta | Alta |
| Habilitar AWS CloudTrail | Auditoria de chamadas de API AWS | Baixa |
| Implementar Auto Scaling Group | Alta disponibilidade | Alta |
| Mover DB para RDS na subnet privada | Gerenciamento e backups automáticos | Média |

---

## 4. Compliance com Boas Práticas

| Prática | Status | Observação |
|---------|--------|------------|
| Princípio do menor privilégio | ✅ | SGs com regras mínimas |
| Separação de redes | ✅ | Subnet pública/privada |
| SSH restrito | ✅ | Apenas IP do admin |
| Chave privada protegida | ✅ | chmod 400, no .gitignore |
| Sem credenciais no código | ✅ | Uso de .env.example |
| Logs habilitados | ✅ | JSON estruturado |
| HTTPS | ⚠️ | Recomendado para produção |
| Secrets Manager | ⚠️ | Melhoria futura |
| VPC Flow Logs | ⚠️ | Melhoria futura |

---

## 5. Análise de Riscos Residuais

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| IP do admin muda | Baixa | Médio | Atualizar regra SSH manualmente |
| Porta 3000 exposta | Média | Baixo | Mover API para trás do Nginx (porta 80) |
| SQLite sem backup | Média | Alto | Migrar para RDS com backup automático |
| HTTP sem criptografia | Alta | Médio | Implementar HTTPS com Let's Encrypt |
