# Troubleshooting Lab 5 - AWS CLI e IAM

**Lab:** 005 - AWS CLI e IAM  
**Foco:** Configuração AWS, credenciais, permissões
## Problemas Mais Comuns

### 1. AWS CLI não Configurado

#### **Sintoma:**
```bash
aws s3 ls
# Unable to locate credentials
```

#### **Soluções:**
```bash
# Configura credenciais
aws configure
# AWS Access Key ID: [sua-key]
# AWS Secret Access Key: [sua-secret]
# Default region: us-east-1
# Default output format: json

# Verifica configuração
aws configure list
cat ~/.aws/credentials
```

### 2. Permissões Insuficientes

#### **Sintoma:**
- "AccessDenied" em comandos AWS
- "User is not authorized to perform"

#### **Diagnóstico:**
```bash
# Verifica identidade atual
aws sts get-caller-identity

# Testa permissões específicas
aws iam get-user
aws s3 ls
```

#### **Soluções:**
```bash
# No Console AWS:
# 1. IAM → Users → seu-usuario
# 2. Attach policies → AdministratorAccess (para labs)
# 3. Ou crie policy específica com permissões necessárias
```

### 3. Região Incorreta

#### **Sintoma:**
- Recursos não aparecem
- "InvalidRegion" errors

#### **Soluções:**
```bash
# Verifica região atual
aws configure get region

# Define região
aws configure set region us-east-1

# Ou usa flag --region
aws s3 ls --region us-east-1
```

### 4. Credenciais Expiradas

#### **Sintoma:**
- "TokenRefreshRequired"
- "The security token included in the request is expired"

#### **Soluções:**
```bash
# Gera novas credenciais no Console AWS
# IAM → Users → Security credentials → Create access key

# Atualiza configuração
aws configure
```

### 5. MFA Requerido

#### **Sintoma:**
- "MultiFactorAuthentication required"

#### **Soluções:**
```bash
# Obtém token de sessão com MFA
aws sts get-session-token --serial-number arn:aws:iam::ACCOUNT:mfa/USER --token-code 123456

# Usa credenciais temporárias
export AWS_ACCESS_KEY_ID=temp-key
export AWS_SECRET_ACCESS_KEY=temp-secret
export AWS_SESSION_TOKEN=temp-token
```

### Container sempre unhealthy

**Problema:** Healthcheck sempre falha  
**Solução:** Verificar se comando funciona manualmente

```bash
# Testar comando dentro do container
docker exec web-app curl -f http://localhost
```

### Dependência não funciona

**Problema:** Web inicia mesmo com DB unhealthy  
**Solução:** Verificar sintaxe do depends_on

```yaml
# ✅ CORRETO
depends_on:
  db:
    condition: service_healthy

# ❌ ERRADO
depends_on:
  - db:
      condition: service_healthy
```

### Grace period muito curto

**Problema:** Container marcado como unhealthy muito cedo  
**Solução:** Aumentar start_period

```yaml
healthcheck:
  start_period: 120s  # Aumentar para aplicações lentas
```

> [!NOTE]
> **Desenvolvido por:** Professor Alexandre Tavares - UniFAAT  
> **Versão:** 1.0 - Semestre 2026.1  
> **Última atualização:** Janeiro 2025