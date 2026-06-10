# Security Analysis - TF09 Portfólio AWS

## 1. Arquitetura de Segurança

```
Internet
    │
    ▼
[Internet Gateway]
    │
    ▼
┌─────────────────────────────────────────────┐
│ VPC 10.0.0.0/16                             │
│                                             │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │ Subnet Pública   │  │ Subnet Privada  │  │
│  │ 10.0.1.0/24      │  │ 10.0.2.0/24     │  │
│  │                  │  │                 │  │
│  │ [Web Server]     │──▶ [Database]      │  │
│  │ WebServer-SG     │  │ Database-SG     │  │
│  └──────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────┘
```

## 2. Security Groups

### WebServer-SG (Inbound)

| Porta | Protocolo | Origem | Justificativa |
|-------|-----------|--------|---------------|
| 22 | TCP | `<seu-ip>/32` | SSH restrito ao administrador — menor privilégio |
| 80 | TCP | `0.0.0.0/0` | HTTP público para a aplicação web |
| 443 | TCP | `0.0.0.0/0` | HTTPS público (preparado para certificado TLS) |

**Outbound:** All traffic `0.0.0.0/0` — necessário para updates e conexão com o banco.

### Database-SG (Inbound)

| Porta | Protocolo | Origem | Justificativa |
|-------|-----------|--------|---------------|
| 3306 | TCP | `WebServer-SG` | MySQL acessível **apenas** pelo Web Server — isolamento total |

**Outbound:** All traffic `0.0.0.0/0` — necessário para updates via NAT (se configurado).

## 3. Princípio do Menor Privilégio

- **SSH** liberado apenas para o IP do administrador (`/32`), não para `0.0.0.0/0`
- **Banco de dados** sem IP público, em subnet privada, sem rota para internet
- **Acesso ao banco** referenciado por Security Group ID (não por CIDR), garantindo que apenas instâncias com o WebServer-SG possam conectar
- **Porta 3000** (Node.js) não exposta diretamente — tráfego passa pelo Nginx na porta 80

## 4. Isolamento de Rede

- O banco de dados está na **subnet privada** sem Internet Gateway associado
- Não há rota `0.0.0.0/0` na route table privada
- Acesso externo direto ao banco é **impossível** pela arquitetura de rede

## 5. Gerenciamento de Chaves SSH

- Key Pair gerado via AWS CLI e salvo localmente com `chmod 400`
- Chave privada **nunca** commitada no repositório (`.gitignore`)
- Acesso SSH ao banco feito via **SSH tunneling** pelo Web Server (bastion implícito)

## 6. Possíveis Melhorias Futuras

| Melhoria | Benefício |
|----------|-----------|
| AWS Systems Manager Session Manager | Elimina necessidade de porta 22 aberta |
| NAT Gateway para subnet privada | Permite updates no banco sem expor à internet |
| HTTPS com ACM + Load Balancer | Criptografia em trânsito |
| VPC Flow Logs | Auditoria de tráfego de rede |
| AWS Secrets Manager | Gerenciamento seguro de credenciais do banco |
| Network ACLs | Camada adicional de controle por subnet |

## 7. Compliance com Boas Práticas AWS

- ✅ Separação de camadas (web/banco) em subnets distintas
- ✅ Princípio do menor privilégio nos Security Groups
- ✅ Banco de dados sem acesso público direto
- ✅ Autenticação por chave (sem senha) para SSH
- ✅ Tags em todos os recursos para rastreabilidade
- ✅ Script de cleanup para evitar custos residuais
