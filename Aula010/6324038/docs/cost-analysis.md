# Análise de Custos - Northwind Docker vs RDS

## Custo Local (Docker) - Mensal Estimado

| Item | Custo Estimado |
|------|---------------|
| Hardware (amortização servidor) | $30,00 |
| Energia elétrica (servidor 24/7) | $15,00 |
| Manutenção / patches manuais | $20,00 (tempo técnico) |
| Backup manual (storage externo) | $5,00 |
| **Total mensal** | **$70,00** |

> Não inclui custo de downtime por falha de hardware ou falta de backup.

---

## Custo RDS (AWS) - Mensal Real

Região: `us-east-1` | Instância: `db.t3.micro` | Storage: 20 GB gp2

| Item | Custo |
|------|-------|
| Instância db.t3.micro (750h Free Tier) | $0,00* |
| Storage 20 GB gp2 (100 GB Free Tier) | $0,00* |
| Backup automático (igual ao storage) | $0,00* |
| Data transfer (saída < 1 GB Free Tier) | $0,00* |
| **Total mensal (Free Tier)** | **$0,00** |
| **Total mensal (pós Free Tier)** | **~$15,33** |

*Elegível ao AWS Free Tier por 12 meses.

### Detalhamento pós Free Tier
- db.t3.micro: $0,017/hora × 730h = **$12,41/mês**
- Storage gp2 20GB: $0,115/GB × 20 = **$2,30/mês**
- Backup (20GB): **$0,095/GB × 20 = $1,90/mês** (se exceder storage)
- **Total: ~$15,33/mês**

---

## TCO - Total Cost of Ownership (12 meses)

| Cenário | Custo Total |
|---------|------------|
| Docker local | $840,00 |
| RDS (Free Tier 12 meses) | $0,00 |
| RDS (pós Free Tier) | $183,96/ano |

## ROI e Recomendações

- **Economia no Free Tier:** $840,00 em 12 meses
- **Economia pós Free Tier:** $656,04/ano vs local
- **Break-even:** Imediato — RDS é mais barato desde o primeiro mês pós Free Tier

### Estratégias de Otimização de Custos
1. Usar **Reserved Instance** (1 ano) para reduzir custo em ~40%: ~$9,20/mês
2. Manter **db.t3.micro** enquanto o banco for pequeno (< 1000 conexões/dia)
3. Configurar **backup retention = 7 dias** (mínimo necessário)
4. Deletar snapshots manuais após validação
5. Monitorar com **AWS Cost Explorer** e configurar billing alert em $10
