# Cost Analysis

## Premissas

| Parâmetro | Valor |
|---|---|
| Visitas/mês | 5.000 |
| Pageviews/mês | 10.000 |
| Tamanho médio da página | 500 KB |
| Dados transferidos/mês | ~5 GB |
| Imagens enviadas/mês | 50 (média 500 KB cada) |
| Mensagens de contato/mês | 20 |

## Breakdown por Serviço

### Amazon S3

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| Armazenamento (1 GB) | 1 GB × $0.023 | $0.02 |
| PUT/COPY requests (1.000) | 1.000 × $0.000005 | $0.01 |
| GET requests (50.000) | 50.000 × $0.0000004 | $0.02 |
| **Subtotal S3** | | **~$0.05** |

### Amazon CloudFront

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| Dados transferidos (5 GB) | 5 GB × $0.0085 (América do Sul) | $0.04 |
| HTTPS requests (100.000) | 100.000 × $0.0000010 | $0.10 |
| **Subtotal CloudFront** | | **~$0.14** |

> Free tier: 1 TB de transferência e 10M requisições/mês por 12 meses.

### AWS Lambda

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| Invocações (70/mês) | Free tier: 1M grátis | $0.00 |
| Duração (128 MB · 500ms) | Free tier: 400.000 GB-s grátis | $0.00 |
| **Subtotal Lambda** | | **$0.00** |

### API Gateway

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| 70 chamadas/mês | Free tier: 1M grátis por 12 meses | $0.00 |
| **Subtotal API Gateway** | | **$0.00** |

### DynamoDB

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| On-demand (20 writes) | Free tier: 25 WCU permanente | $0.00 |
| Armazenamento (<1 MB) | Free tier: 25 GB permanente | $0.00 |
| **Subtotal DynamoDB** | | **$0.00** |

### Amazon SES

| Componente | Cálculo | Custo/mês (USD) |
|---|---|---|
| 20 emails/mês | Free tier: 62.000/mês via Lambda | $0.00 |
| **Subtotal SES** | | **$0.00** |

## Resumo Total

| Serviço | Custo/mês |
|---|---|
| S3 | $0.05 |
| CloudFront | $0.14* |
| Lambda | $0.00 |
| API Gateway | $0.00 |
| DynamoDB | $0.00 |
| SES | $0.00 |
| **TOTAL** | **~$0.19/mês** |
| **TOTAL anual** | **~$2.28/ano** |

*Cobrado apenas após expiração do free tier (12 meses).

## Comparação com Hospedagem Tradicional

| Opção | Custo/mês | Escalabilidade | Manutenção |
|---|---|---|---|
| AWS S3 + CloudFront | ~$0.19 | Infinita | Zero |
| Servidor VPS (básico) | ~$5.00 | Manual | Alta |
| Netlify/Vercel (gratuito) | $0 | Limitada | Baixa |
| Hospedagem compartilhada | ~$3–10 | Limitada | Média |

## Estratégias de Otimização

1. **Free tier** cobre praticamente 100% do uso neste cenário por 12 meses
2. **Compressão Gzip** reduz ~70% dos dados transferidos (reduz custo CloudFront)
3. **Cache longo** para CSS/JS imutáveis reduz requisições ao S3
4. **CloudFront Price Class** configurado para "All" — considerar `PriceClass_100` (EUA + Europa) para reduzir custo se audiência for apenas brasileira

## Alertas de Custo

Configurar alarme CloudWatch para USD 5,00/mês:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "portfolio-cost-alert" \
  --alarm-description "Alerta custo portfólio > $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 5.0 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:<account>:billing-alerts
```
