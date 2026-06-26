# Cost Analysis - TF11

## Premissas
Regiao base: us-east-1  
Cenario: portfolio com baixo volume (laboratorio)

## Estimativa mensal (apos Free Tier)
| Servico | Consumo estimado | Custo aprox. |
|---|---|---:|
| S3 Website Bucket | 1 GB + 20k requests GET | USD 0.50 |
| S3 Assets Bucket | 2 GB + 10k requests PUT/GET | USD 0.70 |
| CloudFront | 20 GB transferencia + 200k requests | USD 1.00 |
| Lambda Contact | 20k invocacoes | USD 0.10 |
| API Gateway | 20k requests | USD 0.25 |
| DynamoDB (on-demand) | baixo volume | USD 0.20 |
| **Total** |  | **USD 2.75/mes** |

## Estrategias de otimizacao
- PriceClass_100 no CloudFront para reduzir custo de edge global
- WebP + cache longo em assets imutaveis
- Lifecycle no bucket de assets para STANDARD_IA apos 30 dias
- Limpeza automatica de recursos apos avaliacao

## Controle de custos
- Criar billing alert em USD 10
- Revisar Cost Explorer semanalmente
- Validar recursos ociosos apos testes

## Risco de custo residual
Maior risco: manter CloudFront e buckets ativos sem necessidade apos o prazo de avaliacao.

Mitigacao:
- Executar `infrastructure/cleanup.sh`
- Confirmar remocao de distribuicao e buckets
- Validar fatura no ciclo seguinte
