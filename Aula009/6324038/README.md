# TF09 - Portfólio Pessoal na AWS

**Aluno:** Bruno Rocha Rozadas de Jesus  
**RA:** 6324038  
**Disciplina:** Implementação de Sistemas - UniFAAT ADS  

---

## Visão Geral

Portfólio pessoal hospedado em uma instância **EC2 t3.micro** na AWS, com arquitetura de rede segura usando VPC customizada, subnets pública/privada e Security Groups seguindo o princípio do menor privilégio.

## Arquitetura de Rede

```
Internet
    │
    ▼
[Internet Gateway - igw-xxx]
    │
    ▼
┌─────────────────────────────────────────────┐
│ VPC: 10.0.0.0/16  (us-east-1)              │
│                                             │
│  ┌──────────────────┐  ┌─────────────────┐  │
│  │ Subnet Pública   │  │ Subnet Privada  │  │
│  │ 10.0.1.0/24      │  │ 10.0.2.0/24     │  │
│  │ us-east-1a       │  │ us-east-1a      │  │
│  │                  │  │                 │  │
│  │ EC2 t3.micro     │──▶ EC2 t3.micro    │  │
│  │ Nginx + Node.js  │  │ MariaDB         │  │
│  │ WebServer-SG     │  │ Database-SG     │  │
│  └──────────────────┘  └─────────────────┘  │
└─────────────────────────────────────────────┘
```

### VPC Configuration
- CIDR Block: `10.0.0.0/16`
- Region: `us-east-1`
- DNS Hostnames: habilitado

### Subnets
- Public Subnet: `10.0.1.0/24` - us-east-1a (Web Server)
- Private Subnet: `10.0.2.0/24` - us-east-1a (Database)

### Routing
- Public Route Table: `0.0.0.0/0 → Internet Gateway`
- Private Route Table: apenas rota local `10.0.0.0/16`

## Segurança Implementada

### WebServer-SG
| Porta | Origem | Motivo |
|-------|--------|--------|
| 22 | `<admin-ip>/32` | SSH restrito ao administrador |
| 80 | `0.0.0.0/0` | HTTP público |
| 443 | `0.0.0.0/0` | HTTPS público |

### Database-SG
| Porta | Origem | Motivo |
|-------|--------|--------|
| 3306 | `WebServer-SG` | MySQL apenas do Web Server |

- Banco em **subnet privada** sem rota para internet
- Acesso referenciado por **Security Group ID** (não CIDR)
- SSH por **chave RSA** (sem senha)

## Como Executar

```bash
# 1. Criar infraestrutura
cd infrastructure
./create-infrastructure.sh

# 2. Deploy da aplicação (após ~3 min)
source .env.infrastructure
scp -i ${KEY_NAME}.pem -r ../application/ ec2-user@${WEB_PUBLIC_IP}:~/app/
ssh -i ${KEY_NAME}.pem ec2-user@${WEB_PUBLIC_IP}
# Na instância: cd ~/app && sudo docker-compose up -d --build

# 3. Acessar
echo "http://${WEB_PUBLIC_IP}"

# 4. Limpar após avaliação
./cleanup-infrastructure.sh
```

## Tecnologias Utilizadas

| Tecnologia | Justificativa |
|------------|---------------|
| Amazon EC2 t3.micro | Free Tier, suficiente para portfólio |
| Amazon VPC | Isolamento e controle de rede |
| Security Groups | Firewall stateful por instância |
| Amazon Linux 2 | Otimizada para AWS, suporte oficial |
| Docker + Docker Compose | Portabilidade e facilidade de deploy |
| Nginx | Proxy reverso e servidor de arquivos estáticos |
| Node.js + Express | Backend leve para API REST |
| MariaDB | Banco relacional compatível com MySQL |

## Custos Estimados (Free Tier)

| Recurso | Uso mensal | Custo |
|---------|-----------|-------|
| EC2 t3.micro × 2 | 750h/mês Free Tier | $0,00 |
| EBS gp2 8GB × 2 | 30GB Free Tier | $0,00 |
| Data Transfer | < 1GB | $0,00 |
| **Total estimado** | | **$0,00** |

> Válido dentro do Free Tier (primeiro ano). Após o Free Tier: ~$0,02/h por instância.

## Estrutura do Repositório

```
TF09-Aluno/
├── README.md
├── infrastructure/
│   ├── create-infrastructure.sh   # Cria toda a infraestrutura AWS
│   ├── cleanup-infrastructure.sh  # Remove todos os recursos
│   ├── web-server-userdata.sh     # Bootstrap do Web Server
│   └── db-server-userdata.sh      # Bootstrap do Database
├── application/
│   ├── frontend/index.html        # SPA do portfólio
│   ├── backend/server.js          # API REST Node.js
│   ├── backend/Dockerfile
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── .env.example
└── docs/
    ├── deployment-guide.md
    ├── security-analysis.md
    └── troubleshooting.md
```

## Referências

- [Lab009.md](../Lab009.md) - Laboratório de referência
- [AWS EC2 User Guide](https://docs.aws.amazon.com/ec2/)
- [AWS VPC User Guide](https://docs.aws.amazon.com/vpc/)
