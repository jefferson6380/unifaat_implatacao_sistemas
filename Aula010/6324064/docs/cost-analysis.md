# Analise de Custos - TF10

## Premissas
- Regiao: us-east-1
- Instancia avaliada: db.t3.micro
- Storage: 20 GB gp3
- Backup retention: 7 dias
- Modo de alta disponibilidade na execucao: Single-AZ
- Ambiente local considerado: servidor proprio equivalente

## Analise de Custos

### Custo Local (mensal estimado)
- Hardware: $18.00
- Energia: $6.00
- Manutencao: $8.00
- Total: $32.00

### Custo RDS (mensal real)
- Instancia: $12.40
- Storage: $2.30
- Backup: $0.00
- Total: $14.70

### ROI e Recomendacoes
No cenario executado (Single-AZ), o RDS apresentou custo inferior ao ambiente local estimado e melhor capacidade de operacao (backup/restore e monitoramento centralizado). Para producao, a recomendacao e migrar para Multi-AZ para elevar disponibilidade.

## TCO (Custo Total de Propriedade)
Formula usada:

`TCO = custo_infra + custo_operacao + custo_risco + custo_oportunidade`

Comparacao de cenarios:
| Cenario | Custo mensal | Disponibilidade | Esforco operacional |
|---|---:|---:|---:|
| Local | $32.00 | 99.00% | Alto |
| RDS Single-AZ | $14.70 | 99.90% | Medio |
| RDS Multi-AZ | $27.10 | 99.95% | Baixo |

## Projecao para Diferentes Cenarios
1. Cenario Basico (turma/lab): db.t3.micro, 20 GB, 7 dias backup
2. Cenario Intermediario: db.t3.small, 100 GB, 7-14 dias backup
3. Cenario Produção: classe maior, Multi-AZ, replicas de leitura

## Estrategias de Otimizacao de Custos
1. Usar `db.t3.micro` enquanto o workload permitir.
2. Configurar retencao de backup apenas no necessario.
3. Excluir snapshots manuais sem uso.
4. Monitorar transferencia de dados entre AZ e internet.
5. Configurar alertas de faturamento e budget.
6. Remover recursos imediatamente apos avaliacao (`migration/cleanup.sh`).

## Monitoramento de Custos Obrigatorio
- Alertas de faturamento habilitados
- Cost Explorer revisado durante a execucao
- Free Tier acompanhado
- Registro de variacao de custo por recurso

## Conclusao Financeira
Para o escopo do TF10, a execucao em `db.t3.micro` Single-AZ foi financeiramente vantajosa frente ao custo local estimado, mantendo beneficios de operacao em nuvem. A evolucao recomendada para ambiente critico e adotar Multi-AZ, aceitando o aumento de custo em troca de maior disponibilidade.
