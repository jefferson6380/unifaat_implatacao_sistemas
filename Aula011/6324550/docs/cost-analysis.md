# Cost Analysis – TF11

**Aluno:** Bruno Pereira dos Santos – RA 6324550

---

## Breakdown de Custos por Serviço

### Amazon S3

| Item | Quantidade | Preço | Custo/mês |
|------|-----------|-------|----------|
| Armazenamento (Standard) | ~50 MB | $0.023/GB | ~$0.00 |
| Requisições GET | ~10.000 | $0.0004/1000 | ~$0.004 |
| Requisições PUT | ~100 | $0.005/1000 | ~$0.00 |
| Transferência (CloudFront) | Grátis | – | $0.00 |
| **Subtotal S3** | | | **~$0.01/mês** |

> Free Tier: 5GB storage, 20.000 GET, 2.000 PUT por mês (12 meses)

### Amazon CloudFront

| Item | Quantidade | Preço | Custo/mês |
|------|-----------|-------|----------|
| Transferência (Americas) | ~1 GB | $0.0085/GB | ~$0.009 |
| Requisições HTTPS | ~50.000 | $0.0100/10.000 | ~$0.05 |
| **Subtotal CloudFront** | | | **~$0.06/mês** |

> Free Tier: 1TB transferência, 10M requisições/mês (12 meses)

### AWS Lambda

| Item | Quantidade | Preço | Custo/mês |
|------|-----------|-------|----------|
| Invocações | ~500 | $0.20/1M | ~$0.00 |
| Duração (128MB) | ~500 × 0.5s | $0.0000166667/GB-s | ~$0.00 |
| **Subtotal Lambda** | | | **~$0.00/mês** |

> Free Tier: 1M invocações e 400.000 GB-s/mês (permanente)

### Amazon DynamoDB

| Item | Quantidade | Preço | Custo/mês |
|------|-----------|-------|----------|
| Escritas | ~500 WCU | $0.00065/WCU-h | ~$0.00 |
| Leituras | ~100 RCU | $0.00013/RCU-h | ~$0.00 |
| Armazenamento | ~1 MB | $0.25/GB | ~$0.00 |
| **Subtotal DynamoDB** | | | **~$0.00/mês** |

> Free Tier: 25 WCU, 25 RCU, 25 GB storage (permanente)

### Amazon SES

| Item | Quantidade | Preço | Custo/mês |
|------|-----------|-------|----------|
| Emails enviados | ~100 | $0.10/1000 | ~$0.01 |
| **Subtotal SES** | | | **~$0.01/mês** |

> Free Tier: 62.000 emails/mês se enviado de EC2/Lambda

---

## Resumo Total

| Cenário | Custo/mês |
|---------|----------|
| Dentro do Free Tier | **~$0.00** |
| Após Free Tier (baixo tráfego) | **~$1.50** |
| Após Free Tier (médio tráfego) | **~$3.00** |

---

## Estratégias de Otimização

1. **S3 Intelligent-Tiering** para assets raramente acessados
2. **CloudFront cache TTL** alto para imagens e CSS/JS (reduz requisições de origem)
3. **Lambda provisionada** apenas se necessário (evitar cold starts desnecessários)
4. **Lifecycle policies** para deletar versões antigas do S3 automaticamente
5. **Billing alert** configurado em $10 para evitar surpresas

---

## Comparação com Hospedagem Tradicional

| Solução | Custo/mês | Escalabilidade | SLA |
|---------|----------|---------------|-----|
| Servidor VPS (DigitalOcean $6) | ~$6 | Manual | 99.9% |
| Netlify Free | $0 | Limitado | 99.9% |
| AWS S3 + CloudFront | ~$1.50 | Ilimitada | 99.99% |
| Vercel Pro | $20 | Alta | 99.99% |

**Conclusão:** A solução AWS S3 + CloudFront oferece a melhor relação custo-benefício com escalabilidade global e SLA de 99.99%.

---

## Plano de Disaster Recovery

- Versionamento habilitado nos buckets S3 (RPO ~0)
- CloudFront serve cache mesmo se origem estiver indisponível (RTO ~0)
- Possibilidade de replicação cross-region com custo adicional de ~$0.015/GB
