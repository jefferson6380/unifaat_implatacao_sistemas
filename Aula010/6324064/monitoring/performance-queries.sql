-- TF10 - Queries para baseline e monitoramento de performance
-- Recomendado no RDS: habilitar pg_stat_statements no parameter group e reiniciar a instancia

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- 1) Top 5 queries mais executadas
SELECT
  query,
  calls,
  round(total_exec_time::numeric, 2) AS total_exec_time_ms,
  round(mean_exec_time::numeric, 2) AS mean_exec_time_ms,
  rows
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 5;

-- 2) Top 5 queries com maior tempo total
SELECT
  query,
  calls,
  round(total_exec_time::numeric, 2) AS total_exec_time_ms,
  round(mean_exec_time::numeric, 2) AS mean_exec_time_ms
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;

-- 3) Tabelas maiores (top 10)
SELECT
  relname AS table_name,
  pg_size_pretty(pg_total_relation_size(relid)) AS total_size,
  pg_total_relation_size(relid) AS total_size_bytes
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;

-- 4) Hit ratio de cache (quanto maior, melhor)
SELECT
  datname,
  blks_read,
  blks_hit,
  CASE
    WHEN (blks_read + blks_hit) = 0 THEN 0
    ELSE round((blks_hit::numeric / (blks_hit + blks_read)) * 100, 2)
  END AS cache_hit_ratio_percent
FROM pg_stat_database
WHERE datname = current_database();

-- 5) Sessoes ativas e estado das conexoes
SELECT
  state,
  count(*) AS connections
FROM pg_stat_activity
GROUP BY state
ORDER BY connections DESC;

-- 6) Queries ativas com maior duracao (possiveis gargalos)
SELECT
  pid,
  usename,
  state,
  now() - query_start AS duration,
  LEFT(query, 200) AS query_excerpt
FROM pg_stat_activity
WHERE state <> 'idle'
ORDER BY duration DESC
LIMIT 10;

-- 7) Vacuo e bloat estimado por dead tuples
SELECT
  relname AS table_name,
  n_live_tup,
  n_dead_tup,
  CASE
    WHEN n_live_tup = 0 THEN 0
    ELSE round((n_dead_tup::numeric / n_live_tup::numeric) * 100, 2)
  END AS dead_tuple_percent
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;

-- 8) Uso de indices x scans sequenciais
SELECT
  relname AS table_name,
  seq_scan,
  idx_scan,
  CASE
    WHEN (seq_scan + idx_scan) = 0 THEN 0
    ELSE round((idx_scan::numeric / (seq_scan + idx_scan)) * 100, 2)
  END AS index_usage_percent
FROM pg_stat_user_tables
ORDER BY seq_scan DESC
LIMIT 10;
