# Análise do Estado Atual

## Schema do Banco

- Número de tabelas: 2
- Tamanho total: pequeno (<1MB)
- Queries mais frequentes:
  - SELECT * FROM pedidos
  - SELECT * FROM clientes
  - JOIN clientes + pedidos

## Performance Baseline

- Tempo médio: 0.1ms
- Conexões simultâneas: 1
- IOPS médio: baixo