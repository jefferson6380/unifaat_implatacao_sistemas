# Plano de Migracao - TF10

## Objetivo
Migrar um banco PostgreSQL local para Amazon RDS PostgreSQL, aplicando boas praticas de alta disponibilidade, backup automatizado, seguranca e monitoramento.

## Escopo
- Origem: PostgreSQL local em container Docker
- Destino: Amazon RDS PostgreSQL
- Estrategia: migracao planejada com janela de indisponibilidade curta

## Analise do Estado Atual

### Schema do Banco
- Numero de tabelas: 0
- Tamanho total: 0.0082 GB (8,206,015 bytes)
- Queries mais frequentes (capturadas no RDS com pg_stat_statements):
  - `SELECT $1` (7514 chamadas)
  - `BEGIN` (1844 chamadas)
  - `COMMIT` (1577 chamadas)
  - `SET statement_timeout=10000` (1569 chamadas)
  - `SELECT COUNT(*) FROM pg_class WHERE relname = $1 AND relkind = $2 AND relnamespace::regnamespace::text = $3` (1146 chamadas)

Consultas recomendadas para preenchimento:
```sql
SELECT count(*) AS total_tabelas
FROM information_schema.tables
WHERE table_schema = 'public';

SELECT pg_size_pretty(pg_database_size(current_database())) AS tamanho_total;

SELECT query, calls
FROM pg_stat_statements
ORDER BY calls DESC
LIMIT 5;
```

### Performance Baseline
- Tempo medio de resposta: 0.092 ms (local, benchmark `SELECT 1`)
- Conexoes simultaneas: 1 (baseline observado em `pg_stat_activity`)
- IOPS medio: 14.90 (local, media de 5 amostras de `Disk Transfers/sec`)

Coleta recomendada:
- `pgbench` para latencia e throughput
- CloudWatch/OS local para IOPS
- `pg_stat_activity` para conexoes

## Planejamento da Migracao

### Engine Escolhida: PostgreSQL
**Justificativa:**
- Compatibilidade total com o banco atual, evitando refatoracao de schema e queries.
- Menor risco tecnico e menor tempo de migracao.
- Recursos nativos de monitoramento e backup no RDS.

### Configuracao RDS
- Classe de instancia: db.t3.micro
- Storage: 20 GB gp3
- Multi-AZ: Nao (neste laboratorio) - Justificativa: controle de custo no escopo academico; em producao recomenda-se habilitar
- Backup retention: 7 dias

### Seguranca
- Security Group com menor privilegio (somente porta 5432 para IP/rede da aplicacao)
- RDS em sub-redes privadas
- Public access habilitado temporariamente no laboratorio para migracao a partir da maquina local, com CIDR `/32` do IP atual
- Credenciais via variaveis de ambiente

### Estrategia de Migracao
- Tipo: Janela curta de indisponibilidade
- Passos:
  1. Backup completo local
  2. Exportacao de schema
  3. Exportacao de dados
  4. Importacao no RDS
  5. Validacao de integridade
  6. Liberacao para uso

### Plano de Rollback
- Manter banco local inalterado ate validacao final
- Em caso de falha:
  1. Aplicacao volta para conexao local
  2. Restaurar ultimo dump validado
  3. Corrigir erro e repetir migracao

RTO estimado: 30 a 60 minutos
RPO estimado: ate o ultimo dump executado antes do corte

## Cronograma Detalhado
1. Dia 1: analise do estado atual e baseline
2. Dia 2: criacao da infraestrutura RDS e configuracao de seguranca
3. Dia 3: migracao e validacao de dados
4. Dia 4: monitoramento, benchmark e comparativo
5. Dia 5: analise de custos, limpeza e documentacao final

## Riscos e Mitigacoes
| Risco | Impacto | Mitigacao |
|---|---|---|
| Credenciais incorretas | Alto | Validar `.env` antes de rodar scripts |
| Bloqueio de rede (SG/Subnet) | Alto | Testar conectividade antes da migracao |
| Divergencia de dados | Alto | Rodar `validate-migration.sh` e revisar relatorio |
| Custo acima do esperado | Medio | Usar db.t3.micro e desligar recursos apos avaliacao |
| Queda durante migracao | Medio | Aplicar plano de rollback imediatamente |

## Checklist de Validacao
- [x] Instancia RDS criada e disponivel
- [x] Backup local gerado com sucesso
- [x] Schema migrado sem erros
- [x] Dados migrados sem erros
- [x] Contagem de linhas validada por tabela
- [x] Dashboard CloudWatch importado
- [ ] Alarmes configurados e testados
- [ ] Custo monitorado no Cost Explorer
- [ ] Limpeza final executada apos avaliacao
