# TF10 - Migração para Amazon RDS
**RA:** 6324038 | **Disciplina:** Implementação de Sistemas - UniFAAT ADS

## Visão Geral

Migração do banco de dados **Northwind** (PostgreSQL 14 em Docker local) para **Amazon RDS PostgreSQL**, implementando backup automatizado, monitoramento com CloudWatch e boas práticas de segurança.

## Arquitetura

### Antes (Docker Local)
```
[Aplicação] → [Docker: postgres:14-alpine] → porta 2001
              banco: northwind | user: postgres
```

### Depois (Amazon RDS)
```
[Aplicação] → [RDS: PostgreSQL 14 - db.t3.micro]
              VPC padrão | 2 subnets (us-east-1a, us-east-1b)
              Security Group: porta 5432 restrita
              Backup: 7 dias automático
              Monitoramento: CloudWatch
```

## Estrutura do Projeto

```
6324038/
├── README.md
├── migration/
│   ├── create-rds.sh        # Cria toda a infraestrutura RDS
│   ├── migrate-data.sh      # Exporta local e importa no RDS
│   ├── validate-migration.sh # Valida integridade dos dados
│   └── cleanup.sh           # Remove todos os recursos AWS
├── monitoring/
│   ├── cloudwatch-dashboard.json  # Dashboard com 6 métricas
│   ├── alerts-config.json         # 3 alarmes críticos
│   └── performance-queries.sql    # Queries de análise
└── docs/
    ├── migration-plan.md      # Planejamento e riscos
    ├── performance-analysis.md # Benchmarks antes/depois
    ├── cost-analysis.md        # TCO e ROI
    └── troubleshooting.md      # Erros comuns e soluções
```

## Como Executar a Migração

### Pré-requisitos
- AWS CLI configurado (`aws configure`)
- Docker rodando com o banco local (`docker-compose up -d`)
- `pg_dump` e `psql` instalados localmente
- Permissões IAM: `AmazonRDSFullAccess`, `AmazonEC2FullAccess`

### Passo a Passo

```bash
cd migration/

# 1. Criar infraestrutura RDS (~15 min)
chmod +x *.sh
./create-rds.sh

# 2. Migrar dados (~3 min)
./migrate-data.sh

# 3. Validar migração
./validate-migration.sh

# 4. Criar dashboard CloudWatch
aws cloudwatch put-dashboard \
  --dashboard-name Northwind-RDS \
  --dashboard-body file://../monitoring/cloudwatch-dashboard.json

# 5. Após avaliação, limpar recursos
./cleanup.sh
```

## Resultados Obtidos

| Métrica | Docker Local | RDS |
|---------|-------------|-----|
| Latência média | ~1.8 ms | ~3.2 ms (+rede) |
| Disponibilidade | ~99% | 99.95% |
| Backup automático | ❌ | ✅ 7 dias |
| Monitoramento | ❌ | ✅ CloudWatch |
| Custo mensal | ~$70 | $0 (Free Tier) |

## Custos e ROI

- **Free Tier (12 meses):** $0,00
- **Pós Free Tier:** ~$15,33/mês vs ~$70,00 local
- **Economia anual:** ~$656/ano após Free Tier
- **Recomendação:** Reserved Instance 1 ano reduz para ~$9,20/mês
