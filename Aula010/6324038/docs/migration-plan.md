# Plano de Migração - Northwind Docker → Amazon RDS

## Análise do Estado Atual

### Schema do Banco
- Engine: PostgreSQL 14 (Docker)
- Banco: `northwind`
- Número de tabelas: 13 (customers, orders, order_details, products, employees, suppliers, categories, shippers, regions, territories, employee_territories, us_states, customer_demographics)
- Tamanho total: ~5 MB (banco de demonstração)
- Porta local: 2001 (mapeada do container)

### Performance Baseline (Docker local)
- Tempo médio de resposta: ~2 ms (localhost)
- Conexões simultâneas: até 100 (padrão PostgreSQL)
- IOPS médio: limitado pelo disco local

### Queries Críticas Identificadas
1. `SELECT` com JOIN entre `orders`, `order_details` e `products` (relatórios de vendas)
2. `SELECT` com filtro por `customer_id` em `orders`
3. Agregações por `category_name` para dashboards
4. Consultas de `employees` com `territories`
5. Listagem de `products` com `suppliers` e `categories`

## Planejamento da Migração

### Engine Escolhida: PostgreSQL 14
**Justificativa:** O banco local já usa PostgreSQL 14, garantindo compatibilidade total do schema e dados sem necessidade de conversão. Evita riscos de incompatibilidade de tipos de dados e funções.

### Configuração RDS
- Classe de instância: `db.t3.micro` (Free Tier elegível)
- Storage: 20 GB gp2
- Multi-AZ: Não (ambiente acadêmico, custo reduzido)
- Backup retention: 7 dias
- Publicly accessible: Sim (apenas durante migração, restringir depois)

## Análise de Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|-------|--------------|---------|-----------|
| Falha na conectividade | Média | Alto | Testar Security Group antes da migração |
| Perda de dados | Baixa | Crítico | Dump completo antes de qualquer operação |
| Incompatibilidade de versão | Baixa | Médio | Mesma versão PostgreSQL 14 |
| Timeout durante import | Baixa | Médio | Banco pequeno (~5MB), risco mínimo |

## Cronograma

| Etapa | Duração Estimada |
|-------|-----------------|
| Criar infraestrutura RDS | 15 min |
| Dump do banco local | 1 min |
| Import no RDS | 2 min |
| Validação de dados | 5 min |
| Configurar monitoramento | 10 min |
| **Total** | **~33 min** |

## Plano de Rollback

1. O banco Docker original permanece intacto durante toda a migração
2. Em caso de falha no RDS, basta apontar a aplicação de volta para `localhost:2001`
3. O dump `northwind_dump.sql` permite recriar o RDS a qualquer momento

## Checklist de Validação Pós-Migração

- [ ] Contagem de registros igual em todas as 13 tabelas
- [ ] Constraints (PK, FK, UNIQUE) presentes no RDS
- [ ] Query de relatório de vendas retorna mesmo resultado
- [ ] Backup automático configurado e ativo
- [ ] Alarmes CloudWatch criados
