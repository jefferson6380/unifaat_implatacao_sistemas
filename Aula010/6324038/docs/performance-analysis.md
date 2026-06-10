# Análise de Performance - Northwind Docker vs RDS

## Metodologia

Queries executadas 10 vezes consecutivas com `EXPLAIN ANALYZE` em cada ambiente.  
Ferramenta: `psql` com `\timing on`.

---

## Antes (Docker Local - PostgreSQL 14)

### Query 1: Relatório de vendas por categoria
```sql
SELECT c.category_name, COUNT(od.order_id), SUM(od.unit_price * od.quantity)
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name;
```
- Tempo médio: ~1.8 ms
- Throughput: ~555 queries/sec
- Disponibilidade: 99% (depende do Docker estar rodando)

### Query 2: Pedidos por cliente
```sql
SELECT * FROM orders WHERE customer_id = 'ALFKI';
```
- Tempo médio: ~0.5 ms
- Throughput: ~2000 queries/sec

### Limitações do ambiente local
- Sem backup automático
- Sem failover
- Performance limitada ao hardware local
- Sem monitoramento integrado

---

## Depois (Amazon RDS PostgreSQL 14 - db.t3.micro)

### Query 1: Relatório de vendas por categoria
- Tempo médio: ~3.2 ms (latência de rede ~1.5ms adicionada)
- Throughput: ~312 queries/sec
- Disponibilidade: 99.95% (SLA AWS RDS)

### Query 2: Pedidos por cliente
- Tempo médio: ~2.1 ms
- Throughput: ~476 queries/sec

---

## Análise Comparativa

| Métrica | Docker Local | RDS db.t3.micro | Diferença |
|---------|-------------|-----------------|-----------|
| Latência média | ~1.8 ms | ~3.2 ms | +1.4 ms (rede) |
| Disponibilidade | ~99% | 99.95% | +0.95% |
| Backup automático | ❌ | ✅ 7 dias | - |
| Failover | ❌ | ✅ (Multi-AZ opt.) | - |
| Monitoramento | ❌ | ✅ CloudWatch | - |
| Escalabilidade | Manual | Automática | - |

## Conclusão

A latência adicional de ~1.4 ms é causada pela rede (localhost vs endpoint remoto) e é aceitável para aplicações web onde o tempo de resposta HTTP já é de dezenas de ms. Os ganhos em disponibilidade, backup e monitoramento superam amplamente essa diferença.

## Recomendações de Otimização

1. **Connection pooling** com PgBouncer para reduzir overhead de conexões
2. **Índice em `orders.customer_id`** para acelerar filtros por cliente
3. **Read Replica** se houver crescimento de queries de leitura (relatórios)
4. **Parameter Group** customizado: aumentar `work_mem` para queries de agregação
