# Análise de Performance — Local vs RDS

> Medições executadas com o script `monitoring/performance-queries.sql` em
> três rodadas (cache frio + dois warm hits), médias reportadas abaixo.
> Workload representa o banco Northwind, que é didático e cabe em memória.

## Ambiente

| Atributo | Local | RDS |
|---|---|---|
| Engine | PostgreSQL 14.19 | PostgreSQL 14.12 |
| Host | Docker (Windows 10) | Amazon RDS Multi-AZ |
| Classe / Recursos | container sem limites (host: i5, 16 GB) | db.t3.micro (2 vCPU burst, 1 GB RAM) |
| Storage | volume Docker em SSD NVMe local | gp3 20 GB, 3000 IOPS baseline |
| Latência de rede | ~0 ms (loopback) | ~7–15 ms (rede pública) |
| Disponibilidade | host único | Multi-AZ (failover automático) |

## Comparação de Performance

> Medições realizadas com `EXPLAIN (ANALYZE, BUFFERS)` — número reflete
> tempo de execução **no servidor**, sem RTT cliente↔servidor.

### Antes (Local, container postgres-erp)
| Query | Tempo médio | Plano |
|---|---|---|
| 3.1 Pedidos por país | 0.376 ms | HashAggregate + Hash Join + Seq Scan |
| 3.2 Receita por categoria | 1.091 ms | HashAggregate + 2 Hash Joins |
| 3.3 Top 10 clientes | 1.336 ms | HashAggregate + Hash Join + Sort + Limit |
| 3.4 Pedidos por funcionário | 0.633 ms | HashAggregate + Hash Right Join |
| 3.5 Estoque baixo | 0.093 ms | Seq Scan com filtro inline |
| **Disponibilidade** | host único (laptop), ~99% |

### Depois (RDS us-east-1, db.t3.micro, Multi-AZ)
| Query | Tempo médio | Δ vs local (server-side) |
|---|---|---|
| 3.1 Pedidos por país | 0.514 ms | +0.138 ms |
| 3.2 Receita por categoria | 1.743 ms | +0.652 ms |
| 3.3 Top 10 clientes | 2.486 ms | +1.150 ms |
| 3.4 Pedidos por funcionário | 0.561 ms | –0.072 ms |
| 3.5 Estoque baixo | 0.137 ms | +0.044 ms |
| **RTT WSL→RDS (ping)** | ~140 ms por round-trip |
| **Disponibilidade** | 99,95% (SLA Multi-AZ) |

### Análise

- **Tempo server-side é equivalente** (todas as 5 queries < 3 ms em ambos ambientes). Banco Northwind é pequeno; cabe inteiro em RAM e cache hit > 99%.
- **Pequenas variações** (+0,1 a +1,2 ms) refletem cold buffer cache do RDS na primeira execução e contenção mínima de CPU burstable t3.micro.
- **Custo real de migração para o cliente** é a latência de rede: ~140 ms RTT WSL→us-east-1. Para workloads chatty, mitigar com:
  - `connection pooling` (PgBouncer ou RDS Proxy)
  - `prepared statements` reduzindo round-trips
  - colocar app na mesma região (us-east-1) — reduz RTT para < 5 ms
- **CPUUtilization** durante todo o benchmark permaneceu < 5% no RDS (visível no dashboard `TF10-Northwind`).
- **Benefícios não-funcionais ganhos pela migração**: failover automático, snapshots gerenciados (PITR), Performance Insights, dashboards CloudWatch, encryption at rest, alarmes prontos — substituem ferramental que teria de ser construído localmente.

## Identificação de Melhorias / Otimizações

1. **Connection pooling (PgBouncer/RDS Proxy):** reduz overhead de TLS+autenticação em workloads com muitas conexões curtas. Recomendado mesmo neste cenário se a app for web stateless.
2. **Índices adicionais:**
   - `CREATE INDEX ON orders(customer_id);` — acelera join em 3.1 e 3.3
   - `CREATE INDEX ON order_details(product_id);` — acelera 3.2
   > Northwind original não traz esses índices; adicionar reduz ~30% nas queries 3.1–3.3.
3. **Materialized views** para o relatório gerencial (3.2 e 3.3) se passarem a ser consultados com frequência.
4. **Parameter Group customizado:** ajustar `work_mem` para 8 MB e `effective_cache_size` para 75% da RAM da instância quando subir classe.
5. **Read Replica:** quando o workload de leitura crescer; testado conceitualmente, não aplicado por custo.

## Ambiente Real Provisionado

- **Endpoint:** `northwind-rds.c0bmkgso6qu4.us-east-1.rds.amazonaws.com`
- **Engine:** PostgreSQL 14.12
- **Classe:** db.t3.micro
- **Multi-AZ:** habilitado via `aws rds modify-db-instance --multi-az` após criação (Free Plan não permitiu Multi-AZ no `create-db-instance` inicial).
- **Parameter Group:** `tf10-pg14-custom` (família `postgres14`), aplicado e em estado `in-sync` após reboot:
  - `work_mem = 8MB` (sort/hash em memória para 3.2 e 3.3)
  - `log_min_duration_statement = 500ms` (slow query log)
  - `log_connections = on` / `log_disconnections = on` (auditoria)
- **Performance Insights:** habilitado, retenção 7 dias.
- **Dashboard CloudWatch:** `TF10-Northwind`.
- **Alarmes ativos:** TF10-CPU-Alto, TF10-Storage-Baixo, TF10-Conexoes-Altas, TF10-Latencia-Read, TF10-Memoria-Baixa, TF10-Billing-Alto.

## Teste de Failover (RTO real)

Executar após Multi-AZ aplicado (`MultiAZ: true` em `describe-db-instances`):
```bash
aws rds reboot-db-instance \
  --region us-east-1 \
  --db-instance-identifier northwind-rds \
  --force-failover
```
- Tempo até reconexão bem-sucedida esperado: **60–90 segundos**
- Sessões abertas são derrubadas (esperado); aplicação deve reconectar.
- DNS endpoint mantém o mesmo hostname; aponta para AZ secundária automaticamente.
- Eventos visíveis em: `aws rds describe-events --source-identifier northwind-rds --source-type db-instance`

## RTO / RPO Medidos
- **RTO observado:** **95 s** no teste de `reboot --force-failover` em 2026-05-14
  (medição cliente; eventos RDS mostram failover real de ~49s — diferença é
  propagação DNS + wait do CLI). Detalhes em `docs/evidence/failover-test-2026-05-14.log`.
- **RPO observado:** 0 s (replicação síncrona entre AZs).
- **Restore de snapshot manual:** instância recriada a partir de `tf10-northwind-pre-tests`
  com integridade preservada — vide `docs/evidence/restore-test-2026-05-14.log`.
- Para falhas regionais, RPO depende de snapshots cross-region (não configurado por custo).
