# Análise de Performance

# Ambiente Local

Teste realizado com pgbench.

## Resultados

- TPS: 316
- Latência média: 31ms
- 10 clientes simultâneos
- 1000 transações

---

# Ambiente Amazon RDS

## Benefícios observados

- Alta disponibilidade
- Backup automático
- Monitoramento integrado
- Performance Insights

---

# Comparação

| Métrica | Local | RDS |
|---|---|---|
| Backup | Manual | Automático |
| Monitoramento | Limitado | CloudWatch |
| Alta disponibilidade | Não | Sim |
| Escalabilidade | Limitada | Alta |

---

# Conclusão

O RDS apresentou melhor gerenciamento operacional e maior confiabilidade para ambiente produtivo.