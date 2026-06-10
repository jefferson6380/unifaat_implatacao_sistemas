# TF10 - Migração para Amazon RDS

## Aluno
- Nome: Diogo Amorim
- RA: 6324639

---

# Visão Geral

Este trabalho teve como objetivo migrar um banco PostgreSQL executando localmente em Docker para Amazon RDS PostgreSQL, implementando monitoramento, backup automatizado, segurança e análise de performance.

---

# Arquitetura

## Antes (Local)

Aplicação utilizando PostgreSQL local via Docker Compose.

- PostgreSQL 14
- Docker Compose
- Porta local 2001
- Sem alta disponibilidade
- Sem backup automatizado

## Depois (Amazon RDS)

Migração para Amazon RDS PostgreSQL.

- Amazon RDS PostgreSQL
- Multi-AZ habilitado
- Backup automatizado
- CloudWatch Metrics
- Performance Insights
- Security Groups configurados

---

# Processo de Migração

## Etapas realizadas

1. Criação da instância RDS PostgreSQL
2. Configuração do Security Group
3. Teste de conectividade
4. Backup do banco local
5. Restore no Amazon RDS
6. Validação de dados
7. Monitoramento via CloudWatch
8. Snapshot manual
9. Benchmark com pgbench

---

# Performance

## Ambiente Local

- TPS médio: 316
- Latência média: 31ms

## Ambiente RDS

- Ambiente estável
- Backup automático
- Monitoramento integrado
- Alta disponibilidade

---

# Segurança

- Security Group restrito
- Acesso via senha
- Criptografia SSL/TLS
- Banco privado

---

# Monitoramento

Foram utilizados:

- Amazon CloudWatch
- Performance Insights
- Métricas de CPU
- Database Connections
- Free Storage

---

# Custos

## Estimativa mensal RDS

| Serviço | Valor |
|---|---|
| db.t3.micro | USD 15 |
| Storage | USD 2 |
| Backup | Free Tier |
| Total | USD 17 |

---

# Evidências

Os screenshots estão disponíveis na pasta:

```text
screenshots/

---

# Conclusão

A migração para Amazon RDS simplificou o gerenciamento do banco de dados, melhorando disponibilidade, segurança, backup e monitoramento.