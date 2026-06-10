# TF09 - Portfólio Pessoal na AWS

**Aluno:** Gabriel Santiago de Andrade  
**RA:** 6324647  
**Disciplina:** Implementação de Sistemas - UniFAAT

---

## Visão Geral

Portfólio pessoal hospedado em infraestrutura AWS com EC2, VPC customizada, Security Groups e containerização via Docker. A aplicação expõe um frontend estático e uma API REST para gerenciar projetos e experiências.

---

## Arquitetura de Rede

### VPC Configuration
- **CIDR Block:** 10.0.0.0/16
- **Region:** us-east-1

### Subnets
| Tipo | CIDR | AZ |
|------|------|----|
| Public Subnet (Web) | 10.0.1.0/24 | us-east-1a |
| Private Subnet (DB) | 10.0.2.0/24 | us-east-1b |

### Routing
| Route Table | Destino | Alvo |
|-------------|---------|------|
| Public RT | 0.0.0.0/0 | Internet Gateway |
| Public RT | 10.0.0.0/16 | local |
| Private RT | 10.0.0.0/16 | local |

### Componentes
```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnet (10.0.1.0/24)
    │  EC2 t3.micro
    │  ├── Frontend (porta 80/443)
    │  └── Backend API (porta 3000)
    │
    ▼ (Security Group restrito)
Private Subnet (10.0.2.0/24)
    └── SQLite / PostgreSQL (porta 5432)
```

---

## Segurança Implementada

### Security Group - Web Server (sg-webserver)
| Tipo | Protocolo | Porta | Origem | Justificativa |
|------|-----------|-------|--------|---------------|
| Inbound | TCP | 22 | `<seu-ip-admin>/32` | SSH restrito ao IP do administrador |
| Inbound | TCP | 80 | 0.0.0.0/0 | HTTP público |
| Inbound | TCP | 443 | 0.0.0.0/0 | HTTPS público |
| Outbound | All | All | 0.0.0.0/0 | Saída irrestrita |

### Security Group - Database (sg-database)
| Tipo | Protocolo | Porta | Origem | Justificativa |
|------|-----------|-------|--------|---------------|
| Inbound | TCP | 5432 | sg-webserver | Apenas o web server acessa o banco |
| Outbound | All | All | 10.0.0.0/16 | Saída restrita à VPC |

### Boas Práticas Aplicadas
- Princípio do menor privilégio em todas as regras
- SSH restrito a IP específico (não 0.0.0.0/0)
- Banco de dados em subnet privada (sem acesso direto à internet)
- Security Group do DB referencia o SG do web server (não CIDR)
- Key Pair com permissão 400 na chave privada

---

## Como Executar

### Pré-requisitos
- AWS CLI configurado (`aws configure`)
- Docker e Docker Compose instalados
- Bash (Linux/macOS) ou WSL no Windows

### 1. Criar Infraestrutura
```bash
cd infrastructure/
chmod +x create-infrastructure.sh
./create-infrastructure.sh
```

### 2. Deploy da Aplicação
```bash
cd application/
cp .env.example .env
# Edite .env com os valores reais
docker-compose up -d
```

### 3. Verificar Health Check
```bash
curl http://34.200.221.230/api/health
```

### 4. Limpar Recursos
```bash
cd infrastructure/
chmod +x cleanup-infrastructure.sh
./cleanup-infrastructure.sh
```

---

## Tecnologias Utilizadas

| Tecnologia | Justificativa |
|------------|---------------|
| AWS EC2 t3.micro | Free Tier, suficiente para portfólio |
| AWS VPC | Isolamento de rede e controle de tráfego |
| Node.js + Express | Leve, rápido para APIs REST |
| SQLite | Sem custo adicional, adequado para portfólio |
| Docker Compose | Facilita deploy e reprodutibilidade |
| Nginx | Proxy reverso e servir arquivos estáticos |

---

## Custos Estimados

| Recurso | Tipo | Custo/mês |
|---------|------|-----------|
| EC2 | t3.micro (Free Tier 750h) | $0,00* |
| VPC | VPC, Subnets, Route Tables | $0,00 |
| Internet Gateway | Transferência de dados | ~$0,09/GB |
| EBS | 8 GB gp3 (Free Tier 30GB) | $0,00* |
| **Total estimado** | | **~$0,00 - $2,00/mês** |

*Dentro do Free Tier AWS (12 meses)

---

## Passos Executados

1. Criação da VPC `portfolio-vpc` com CIDR 10.0.0.0/16
2. Criação das subnets pública e privada em AZs distintas
3. Criação e associação do Internet Gateway
4. Configuração das Route Tables (pública com rota 0.0.0.0/0 → IGW)
5. Criação dos Security Groups com regras de menor privilégio
6. Geração do Key Pair e proteção da chave privada (`chmod 400`)
7. Lançamento da instância EC2 t3.micro na subnet pública
8. Deploy da aplicação via Docker Compose
9. Validação de health check e conectividade

---

## Screenshots

> Adicionar screenshots após execução:
> - `docs/screenshots/vpc-console.png`
> - `docs/screenshots/ec2-running.png`
> - `docs/screenshots/app-frontend.png`
> - `docs/screenshots/health-check.png`
