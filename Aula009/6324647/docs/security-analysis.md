# Security Analysis

## Medidas de Segurança Implementadas

### 1. Isolamento de Rede com VPC

A aplicação roda em uma VPC customizada (10.0.0.0/16) com subnets separadas:

- **Subnet pública (10.0.1.0/24):** Apenas o web server, com acesso controlado via Security Group
- **Subnet privada (10.0.2.0/24):** Reservada para banco de dados, sem rota para a internet

Isso garante que o banco de dados nunca seja acessível diretamente da internet, mesmo que o Security Group seja mal configurado.

### 2. Security Groups - Princípio do Menor Privilégio

#### sg-webserver
| Regra | Justificativa |
|-------|---------------|
| SSH (22) apenas do IP do admin | Elimina ataques de força bruta SSH de IPs desconhecidos |
| HTTP (80) público | Necessário para servir a aplicação |
| HTTPS (443) público | Necessário para tráfego seguro |
| Sem outras portas abertas | Superfície de ataque mínima |

#### sg-database
| Regra | Justificativa |
|-------|---------------|
| PostgreSQL (5432) apenas de sg-webserver | Referência por SG, não por CIDR — mais seguro e dinâmico |
| Sem acesso SSH | Banco não precisa de acesso direto |
| Saída restrita à VPC | Impede exfiltração de dados para a internet |

### 3. Gerenciamento de Chaves SSH

- Key Pair gerado localmente e armazenado com `chmod 400` (somente leitura pelo dono)
- Chave privada **nunca** commitada no repositório (`.gitignore`)
- Acesso SSH restrito ao IP do administrador (`/32`)

### 4. Separação de Camadas

```
Internet → Security Group (HTTP/HTTPS) → EC2 (Web + API)
                                              ↓
                                    Security Group (DB port apenas de sg-web)
                                              ↓
                                    Subnet Privada (DB)
```

---

## Justificativa das Regras de Security Groups

**Por que não usar 0.0.0.0/0 para SSH?**  
Expor SSH publicamente resulta em milhares de tentativas de login por dia (bots). Restringir ao IP do administrador elimina esse vetor.

**Por que referenciar sg-webserver no sg-database em vez de usar CIDR?**  
Referência por Security Group é mais segura: se o IP da instância mudar, a regra continua válida. Com CIDR, seria necessário atualizar manualmente.

**Por que subnet privada para o banco?**  
Mesmo sem Security Group, a subnet privada não tem rota para a internet, adicionando uma camada extra de proteção (defesa em profundidade).

---

## Possíveis Melhorias

| Melhoria | Impacto | Complexidade |
|----------|---------|--------------|
| Habilitar HTTPS com certificado SSL (ACM + ALB) | Alto | Média |
| Usar AWS Secrets Manager para credenciais do DB | Alto | Baixa |
| Habilitar VPC Flow Logs para auditoria | Médio | Baixa |
| Adicionar WAF na frente do EC2 | Alto | Alta |
| Usar RDS em vez de SQLite/PostgreSQL local | Médio | Média |
| Implementar IMDSv2 na instância EC2 | Médio | Baixa |

---

## Compliance com Boas Práticas AWS

- ✅ CIS AWS Foundations: SSH restrito, sem 0.0.0.0/0 em portas sensíveis
- ✅ AWS Well-Architected Framework (Security Pillar): menor privilégio, separação de camadas
- ✅ OWASP: dados sensíveis não expostos, sem credenciais hardcoded
- ⚠️ HTTPS não implementado nesta versão (melhoria futura com ACM)
