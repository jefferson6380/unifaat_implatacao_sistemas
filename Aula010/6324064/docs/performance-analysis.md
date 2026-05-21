# Analise de Performance - TF10

## Metodologia
A comparacao foi realizada entre ambiente local (Docker PostgreSQL) e ambiente RDS PostgreSQL, usando as mesmas consultas de negocio e carga semelhante.

Ferramentas usadas:
- `pgbench` para latencia e throughput
- `pg_stat_statements` para queries mais custosas
- CloudWatch para metricas de infraestrutura

## Comparacao de Performance

### Antes (Local)
- Tempo medio de query: 0.092 ms
- Throughput: 54096.25 queries/sec
- Disponibilidade: 99.00% (estimativa sem redundancia de zona)

### Depois (RDS)
- Tempo medio de query: 135.153 ms
- Throughput: 36.99 queries/sec
- Disponibilidade: 99.90% (Single-AZ no laboratorio)

### Analise
No benchmark sintetico (`SELECT 1`) o ambiente local apresentou latencia muito menor por executar na mesma maquina, sem rede externa. O RDS apresentou latencia maior por envolver rota de internet, criptografia SSL e overhead de rede, reduzindo o throughput nesse tipo de teste micro.

Mesmo com pior desempenho bruto em teste sintetico, o RDS trouxe ganho de confiabilidade operacional: backup gerenciado e observabilidade centralizada (CloudWatch/Performance Insights). Para ambiente produtivo, recomenda-se evoluir de Single-AZ para Multi-AZ.

Pontos para analisar no preenchimento:
- Variacao de latencia media e p95
- Variacao de throughput em carga concorrente
- Estabilidade com aumento de conexoes
- Comportamento em failover Multi-AZ

## Indicadores Coletados
- CPUUtilization
- DatabaseConnections
- ReadIOPS / WriteIOPS
- ReadLatency / WriteLatency
- FreeStorageSpace
- FreeableMemory

## Consultas Criticas
As consultas abaixo devem ser executadas antes e depois para comparar comportamento:
1. Top 5 queries por chamadas
2. Top 5 queries por tempo total
3. Queries ativas mais demoradas
4. Hit ratio de cache
5. Uso de indice vs scan sequencial

As consultas estao em `monitoring/performance-queries.sql`.

## Gargalos Identificados
- Gargalo 1: bloqueio de rede no Security Group por IP dinamico da maquina local.
	- Evidencia: `Test-NetConnection` com `TcpTestSucceeded=False` antes da atualizacao da regra.
	- Acao: atualizacao da regra de entrada para o CIDR atual (`/32`).
	- Resultado: conectividade restabelecida para porta 5432.
- Gargalo 2: incompatibilidade de dump entre PostgreSQL 18 (origem) e RDS 16 (destino).
	- Evidencia: erro de `transaction_timeout` no import.
	- Acao: remocao automatica da linha `SET transaction_timeout` nos dumps antes do import.
	- Resultado: importacao concluida com sucesso.
- Gargalo 3: falha de autenticacao local.
	- Evidencia: `FATAL: autenticacao do tipo senha falhou para o usuario "postgres"`.
	- Acao: ajuste controlado da senha local para alinhar com a configuracao do `.env`.
	- Resultado: exportacao local estabilizada.

## Recomendacoes de Otimizacao
1. Revisar e criar indices para queries com maior custo total.
2. Ajustar pool de conexoes na aplicacao para evitar excesso de sessions.
3. Habilitar e acompanhar Performance Insights semanalmente.
4. Executar VACUUM/ANALYZE periodico (ou ajustar autovacuum via parameter group).
5. Revisar tipo de instancia caso CPU fique acima de 70% sustentado.

## Evidencias Obrigatorias
- Print do CloudWatch com metricas ativas
- Print do Performance Insights
- Log de benchmark local vs RDS
- Relatorio de validacao de dados

## Capturas Utilizadas
- `docs/evidencias/02-cloudwatch-dashboard.png`
- `docs/evidencias/03-performance-insights-top-sql.png`
