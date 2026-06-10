# Performance Analysis

## Query Crítica Analisada

JOIN entre orders, order_details e products com LIMIT 50.

## Antes (Local - Docker PostgreSQL 14)

- Planning Time: 15.641 ms
- Execution Time: 1.658 ms
- Estratégia: Nested Loop + Merge Join + Index Scan
- Tamanho do banco: 9.497 kB

## Depois (RDS PostgreSQL 18 - db.t3.micro)

- A mesma query estrutural foi executada com sucesso após a migração
- 14 tabelas disponíveis
- 830 registros em orders, 77 em products, 2155 em order_details

## Análise

O banco local roda em container com acesso direto à memória da máquina host, o que favorece latências baixas. O RDS adiciona latência de rede (~1-5ms) mas oferece disponibilidade gerenciada, backups automáticos e escalabilidade sem intervenção manual.

## Recomendações

- Para produção, habilitar Performance Insights no RDS
- Considerar Read Replica para queries de leitura intensiva
- Monitorar IOPS via CloudWatch