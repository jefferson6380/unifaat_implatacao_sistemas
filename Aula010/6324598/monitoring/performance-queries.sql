-- =====================================================================
-- TF10 - Queries de baseline e diagnóstico de performance (Northwind)
-- Executar antes e depois da migração para comparação.
-- =====================================================================

-- 0. Versão e config base ---------------------------------------------
SELECT version();
SHOW max_connections;
SHOW shared_buffers;
SHOW work_mem;

-- 1. Tamanho do banco e por tabela ------------------------------------
SELECT pg_size_pretty(pg_database_size(current_database())) AS db_size;

SELECT
  relname AS tabela,
  pg_size_pretty(pg_total_relation_size(relid)) AS tamanho,
  n_live_tup AS linhas_aprox
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- 2. Conexões ativas --------------------------------------------------
SELECT count(*) AS conexoes_ativas,
       max(now() - state_change) AS conexao_mais_antiga
FROM pg_stat_activity
WHERE state IS NOT NULL;

-- 3. Queries críticas (top 5 do domínio Northwind) --------------------
-- 3.1 Pedidos por país (relatório gerencial)
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.country, COUNT(o.order_id) AS pedidos
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.country
ORDER BY pedidos DESC;

-- 3.2 Receita por categoria de produto
EXPLAIN (ANALYZE, BUFFERS)
SELECT cat.category_name,
       SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric(12,2) AS receita
FROM order_details od
JOIN products p ON p.product_id = od.product_id
JOIN categories cat ON cat.category_id = p.category_id
GROUP BY cat.category_name
ORDER BY receita DESC;

-- 3.3 Top 10 clientes por valor comprado
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.company_name,
       SUM(od.unit_price * od.quantity * (1 - od.discount))::numeric(12,2) AS total
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_details od ON od.order_id = o.order_id
GROUP BY c.customer_id, c.company_name
ORDER BY total DESC
LIMIT 10;

-- 3.4 Funcionários e número de pedidos atendidos
EXPLAIN (ANALYZE, BUFFERS)
SELECT e.employee_id, e.first_name || ' ' || e.last_name AS nome,
       COUNT(o.order_id) AS pedidos
FROM employees e
LEFT JOIN orders o ON o.employee_id = e.employee_id
GROUP BY e.employee_id, nome
ORDER BY pedidos DESC;

-- 3.5 Produtos com estoque baixo (reordering)
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, units_in_stock, reorder_level
FROM products
WHERE units_in_stock < reorder_level
ORDER BY units_in_stock;

-- 4. Índices existentes -----------------------------------------------
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 5. Estatísticas de uso de índice ------------------------------------
SELECT relname AS tabela, indexrelname AS indice,
       idx_scan AS scans, idx_tup_read AS lidos, idx_tup_fetch AS retornados
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;

-- 6. Cache hit ratio (alvo > 99%) -------------------------------------
SELECT
  sum(heap_blks_read) AS disco,
  sum(heap_blks_hit)  AS cache,
  round(100.0 * sum(heap_blks_hit) /
        NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0), 2) AS hit_ratio_pct
FROM pg_statio_user_tables;

-- 7. Locks ativos (para investigar contenção) -------------------------
SELECT pid, usename, pg_blocking_pids(pid) AS bloqueado_por,
       query, state
FROM pg_stat_activity
WHERE pg_blocking_pids(pid)::text <> '{}'
ORDER BY state_change;
