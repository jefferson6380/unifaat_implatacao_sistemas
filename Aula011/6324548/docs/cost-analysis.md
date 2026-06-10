# Análise de Custos

## Estimativa Mensal (após Free Tier)

| Serviço | Uso Estimado | Custo/mês |
|---------|-------------|-----------|
| Amazon S3 (storage) | 100 MB | $0,00 (Free Tier: 5 GB/12 meses) |
| Amazon S3 (requests) | 10.000 req | $0,00 (Free Tier: 20.000 GET) |
| Amazon CloudFront | 1 GB transferência | ~$0,09 |
| AWS Lambda | 10.000 invocações | $0,00 (Free Tier: 1M/mês permanente) |
| Amazon DynamoDB | < 1 GB | $0,00 (Free Tier: 25 GB permanente) |
| Amazon SES | 100 emails | $0,00 (Free Tier: 62.000/mês de Lambda) |
| CloudWatch | Logs básicos | $0,00 (Free Tier: 5 GB/mês) |
| **Total estimado** | | **~$0,09–$2,00/mês** |

## Detalhamento por Serviço

### Amazon S3
- **Storage**: $0,023/GB/mês — 100 MB ≈ $0,0023
- **PUT, COPY, POST, LIST**: $0,0005 por 1000 requisições
- **GET, SELECT**: $0,0004 por 1000 requisições
- **Free Tier**: 5 GB storage, 20.000 GET, 2.000 PUT por 12 meses

### Amazon CloudFront
- **Transferência de dados (saída)**: $0,085/GB para primeiros 10 TB (EUA/Europa)
  - Brasileiros acessam via São Paulo: $0,110/GB
- **Requisições HTTPS**: $0,0100 por 10.000 requisições
- **Free Tier**: 1 TB transferência/mês e 10 milhões req/mês por 12 meses

### AWS Lambda
- **Invocações**: $0,20 por 1 milhão — **Free Tier permanente: 1M/mês**
- **Duração**: $0,0000166667 por GB-segundo — **Free Tier: 400.000 GB-segundos/mês**
- Estimativa real: praticamente $0,00 para uso acadêmico

### Amazon DynamoDB
- **Storage**: $0,25/GB/mês — **Free Tier permanente: 25 GB**
- **On-Demand**: $1,25 por milhão de writes, $0,25 por milhão de reads
- Estimativa: $0,00–$0,01 para uso acadêmico

### Amazon SES
- **Envio de Lambda**: 62.000 emails/mês gratuitos permanentemente
- **Custo adicional**: $0,10 por 1.000 emails
- Estimativa: $0,00

## Projeção Anual

| Cenário | Custo Anual |
|---------|------------|
| Dentro do Free Tier (12 meses) | ~$0,00–$5,00 |
| Após Free Tier | ~$2,00–$10,00 |
| Tráfego elevado (10k visitas/mês) | ~$5,00–$15,00 |

## Comparação com Hospedagem Tradicional

| Solução | Custo/mês | SLA | CDN | HTTPS |
|---------|-----------|-----|-----|-------|
| **AWS S3 + CloudFront** | ~$0,50–$2,00 | 99,99% | ✅ Global | ✅ |
| Hostinger (básico) | ~$3–5 | 99,9% | ❌ | ✅ |
| GitHub Pages | $0,00 | ~99,9% | ❌ | ✅ |
| Vercel (hobby) | $0,00 | 99,99% | ✅ | ✅ |
| AWS Amplify | ~$1–5 | 99,99% | ✅ | ✅ |

**Vantagem do S3 + CloudFront**:
- Controle total sobre a infraestrutura
- Integração nativa com outros serviços AWS (Lambda, DynamoDB, SES)
- Escalabilidade automática sem configuração
- Preço preditivo e transparente

## Estratégias de Otimização de Custo

1. **Lifecycle Policies**: mover objetos para S3-IA após 30 dias (redução de ~40%)
2. **Cache CloudFront**: alto hit rate = menos requisições ao S3
3. **Compressão Gzip**: reduz transferência de dados em ~70%
4. **Imagens WebP**: reduz storage e transferência em ~30–50%
5. **PriceClass_100**: apenas América do Norte e Europa (mais barato que global)
6. **Billing Alert**: alarme em $10 para evitar surpresas

## Alertas de Billing Configurados

```bash
# Criar alarme de billing ($10)
aws cloudwatch put-metric-alarm \
  --alarm-name "portfolio-billing-alert-10" \
  --alarm-description "Alerta quando custo estimado supera $10" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-east-1:<ACCOUNT_ID>:billing-alerts
```

## Limpeza de Recursos (Pós-Avaliação)

Executar `cleanup.sh` para remover todos os recursos e garantir zero custos residuais.
Verificar no **AWS Cost Explorer** e **Billing Dashboard** após a limpeza.
