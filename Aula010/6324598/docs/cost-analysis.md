# Análise de Custos — Local vs Amazon RDS

> Valores em USD baseados na tabela RDS PostgreSQL us-east-1 (consultada
> em 2026-05). Conversão USD→BRL aproximada (5,50) apenas para o lado local.

## Custo Local (mensal estimado)

| Item | Cálculo | Valor (R$) |
|---|---|---|
| Hardware (amortização) | Notebook R$ 5000 / 36 meses dividido pela fração usada (10%) | ~14 |
| Energia | 50 W × 8 h/dia × 30 d × R$ 0,80/kWh | ~10 |
| Manutenção / suporte | 4 h/mês × R$ 50/h | ~200 |
| Backup (storage externo) | HD externo R$ 300 / 36 meses | ~8 |
| Licença Postgres | open source | 0 |
| **Total mensal** |  | **~R$ 232** |

Notas:
- Não considera *downtime cost* (host único, sem SLA).
- Manutenção é o componente dominante; a automação RDS é o ganho real.

## Custo RDS (mensal real, db.t3.micro Multi-AZ)

| Item | Cálculo | Valor (USD) |
|---|---|---|
| Instância db.t3.micro Multi-AZ | 730 h × 0,034 USD/h | 24,82 |
| Storage gp3 20 GB | 20 GB × 0,115 USD/mês | 2,30 |
| Backup automatizado | 20 GB inclusos | 0,00 |
| Backup adicional | 0 GB (mantido dentro do incluso) | 0,00 |
| Snapshots manuais | 1 GB × 0,095 USD | 0,10 |
| Performance Insights (7 dias) | gratuito | 0,00 |
| Data transfer in | gratuito | 0,00 |
| Data transfer out | ~1 GB × 0,09 USD | 0,09 |
| **Total mensal** |  | **~27,31 USD (~R$ 150)** |

### Free Tier (primeiros 12 meses)
- db.t2/t3.micro **Single-AZ**, 20 GB de storage e 20 GB de backup grátis.
- **Atenção:** Multi-AZ **não** é coberto pelo Free Tier. Para zerar custo, alternar para Single-AZ após a entrega.
- Cenário Free Tier (Single-AZ): **~USD 0/mês** dentro dos limites.

## Projeções para Diferentes Cenários

| Cenário | Instância | Multi-AZ | Storage | Custo/mês (USD) |
|---|---|---|---|---|
| TF10 (atual) | db.t3.micro | Sim | 20 GB gp3 | ~27 |
| Pós-Free Tier econômico | db.t3.micro | Não | 20 GB gp3 | ~12 |
| Workload pequeno em produção | db.t3.small | Sim | 50 GB gp3 | ~64 |
| Workload médio | db.t3.medium | Sim | 100 GB gp3 + 1 réplica | ~170 |
| 1 ano com Reserved Instance (no upfront, t3.small Multi-AZ) | ~35% de desconto | — | — | ~42 |

## Análise de TCO (3 anos)

| Componente | Local (3 anos) | RDS (3 anos, t3.micro Multi-AZ) |
|---|---|---|
| Compute + storage | ~R$ 8.350 | ~R$ 5.400 |
| Backup/DR setup | ~R$ 1.000 (HD, scripts manuais) | inclusos |
| Mão de obra de operação | ~R$ 7.200 (4 h/mês × 36 × R$ 50) | ~R$ 900 (0,5 h/mês) |
| Downtime estimado | difícil quantificar, mas presente | mínimo (Multi-AZ) |
| **TCO total** | **~R$ 16.500** | **~R$ 6.300** |

> Mesmo um banco didático tem TCO ~60% menor em RDS quando incluímos o tempo
> de operação. Para produção de verdade a vantagem cresce.

## ROI e Recomendações

- **ROI positivo em ~6 meses** se a equipe valoriza tempo de operação a partir de R$ 50/h.
- Para cargas didáticas/desenvolvimento: **Single-AZ Free Tier** (USD 0 enquanto durar).
- Para produção real: **Reserved Instance 1 ano** (–35%) + storage gp3 dimensionado.
- Habilitar **Cost Anomaly Detection** no AWS Budgets para flagrar uso fora do esperado.
- Manter alarme `TF10-Billing-Alto` em USD 10 ativo enquanto o ambiente existir.

## Estratégias de Economia Aplicadas

1. Instância **db.t3.micro** (menor classe disponível para PostgreSQL).
2. Storage **gp3** (mais barato que gp2 para mesmos IOPS baseline).
3. Backup retention em **7 dias** (mínimo razoável; cada dia adicional cobra storage extra).
4. **Performance Insights** apenas em retenção 7 dias (gratuito).
5. `cleanup.sh` remove instância, snapshots manuais e SG após avaliação para evitar custo residual.
6. **Billing alert** configurado em USD 10 para detectar surpresas cedo.
