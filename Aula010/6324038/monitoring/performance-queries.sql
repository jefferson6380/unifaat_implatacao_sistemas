-- performance-queries.sql
-- Queries para análise de performance do banco Northwind no RDS

-- 1. Top 5 queries mais lentas (requer pg_stat_statements)
SELECT
  query,
  calls,
  ROUND(total_exec_time::numeric, 2) AS total_ms,
  ROUND(mean_exec_time::numeric, 2)  AS avg_ms,
  ROUND(stddev_exec_time::numeric, 2) AS stddev_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 5;

-- 2. Tamanho de cada tabela
SELECT
  relname AS tabela,
  pg_size_pretty(pg_total_relation_size(relid)) AS tamanho_total,
  pg_size_pretty(pg_relation_size(relid)) AS tamanho_dados,
  pg_size_pretty(pg_indexes_size(relid)) AS tamanho_indices
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- 3. Conexões ativas
SELECT
  state,
  COUNT(*) AS total,
  MAX(EXTRACT(EPOCH FROM (now() - query_start))) AS max_duracao_seg
FROM pg_stat_activity
WHERE datname = 'northwind'
GROUP BY state;

-- 4. Índices não utilizados (candidatos a remoção)
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan AS vezes_usado
FROM pg_stat_user_indexes
WHERE idx_scan = 0
ORDER BY tablename;

-- 5. Benchmark: query de relatório de vendas por categoria
EXPLAIN ANALYZE
SELECT
  c.category_name,
  COUNT(od.order_id) AS total_pedidos,
  ROUND(SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric, 2) AS receita
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY receita DESC;
