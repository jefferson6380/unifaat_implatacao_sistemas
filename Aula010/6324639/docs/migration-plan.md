# Plano de Migração

## Objetivo

Migrar o banco PostgreSQL local executando em Docker para Amazon RDS PostgreSQL.

---

# Estratégia

Foi utilizada estratégia com downtime controlado.

Etapas:

1. Backup do banco local
2. Criação do RDS
3. Restore do banco no RDS
4. Validação
5. Testes de performance

---

# Riscos

| Risco | Mitigação |
|---|---|
| Falha de conexão | Ajuste de Security Groups |
| Timeout | Liberação de porta 5432 |
| Perda de dados | Snapshot manual |
| Lentidão | Monitoramento CloudWatch |

---

# Rollback

Em caso de falha:

1. Manter ambiente Docker ativo
2. Restaurar backup local
3. Reverter conexões da aplicação

---

# Checklist

- [x] Instância RDS criada
- [x] Conectividade validada
- [x] Backup realizado
- [x] Restore executado
- [x] CloudWatch configurado
- [x] Snapshot manual criado