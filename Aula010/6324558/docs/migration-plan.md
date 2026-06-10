# Migration Plan

## 1. Análise do Estado Atual

### Schema do Banco

**Input:**
```bash
docker exec -it postgres-erp psql -U postgres -d northwind -c "\dt"
```

- Número de tabelas: 14
- Lista: categories, customer_customer_demo, customer_demographics, customers, employee_territories, employees, order_details, orders, products, region, shippers, suppliers, territories, us_states

### Tamanho Total do Banco

**Input:**
```bash
docker exec -it postgres-erp psql -U postgres -d northwind -c "SELECT pg_size_pretty(pg_database_size('northwind'));"
```

- Tamanho: 9.497 kB

### Performance Baseline

**Input:**
```bash
docker exec -it postgres-erp psql -U postgres -d northwind -c "EXPLAIN ANALYZE SELECT * FROM orders o JOIN order_details od ON o.order_id = od.order_id JOIN products p ON od.product_id = p.product_id LIMIT 50;"
```

- Planning Time: 15.641 ms
- Execution Time: 1.658 ms

## 2. Planejamento da Migração

| Item | Especificação | Justificativa |
|------|--------------|---------------|
| Engine | PostgreSQL 18 | Paridade com versão disponível no RDS Free Tier |
| Classe | db.t3.micro | Compatível com Free Tier e tamanho do banco (~9.5 MB) |
| Multi-AZ | Desabilitado | Fins acadêmicos, custo zero |
| Backup | 1 dia | Retenção mínima para cumprir requisito de backup automatizado |

## 3. Estratégia de Migração

- Abordagem: downtime aceito (ambiente acadêmico)
- Dump via pg_dump no banco local
- Restore via psql no RDS

## 4. Plano de Rollback

Em caso de falha, o banco local continua disponível via Docker sem alterações. Basta apontar a aplicação de volta para `localhost:2001`.

## 5. Checklist de Validação

- [x] 14 tabelas criadas no RDS
- [x] 830 registros em orders
- [x] 77 registros em products
- [x] Script validate-migration.sh executado com sucesso