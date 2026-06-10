# Análise de Custos — TF11

**Aluno:** Natan Borges Leme  
**RA:** 6324696  
**Disciplina:** Implementação de Sistemas — UniFAAT

---

## 1. Serviços Utilizados e Custos

### 1.1 Amazon S3

| Item                          | Quantidade estimada | Preço unitário (us-east-1) | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| Storage (Standard)            | 500 MB             | $0.023/GB                   | $0.01     |
| PUT/COPY/POST/LIST requests   | 1.000 req/mês      | $0.005/1.000 req            | $0.005    |
| GET/SELECT requests           | 50.000 req/mês     | $0.0004/1.000 req           | $0.02     |
| Data transfer out             | 1 GB/mês           | $0.09/GB (após 100GB free)  | $0.09     |
| **Subtotal S3**               |                    |                             | **~$0.13**|

> **Free Tier S3:** 5 GB de storage, 20.000 GET e 2.000 PUT por mês — primeiros 12 meses grátis.  
> Com Free Tier: **$0.00**

### 1.2 Amazon CloudFront

| Item                          | Quantidade estimada | Preço (us-east-1)          | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| Data transfer out (HTTP/S)    | 5 GB/mês           | $0.0085/GB (após 1TB)       | $0.04     |
| HTTP/HTTPS requests           | 100.000 req/mês    | $0.0100/10.000 req (HTTPS)  | $0.10     |
| **Subtotal CloudFront**       |                    |                             | **~$0.14**|

> **Free Tier CloudFront:** 1 TB de transfer out e 10 milhões de requests por mês — primeiros 12 meses.  
> Com Free Tier: **$0.00**

### 1.3 AWS Lambda

| Item                          | Quantidade estimada | Preço                       | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| Invocações (formulário)       | 200/mês            | $0.20/1M req                | ~$0.00    |
| Duração (128MB, 1s avg)       | 200 × 1s = 200s    | $0.0000166667/GB-s          | ~$0.00    |
| Invocações (image-proc)       | 50/mês             | $0.20/1M req                | ~$0.00    |
| **Subtotal Lambda**           |                    |                             | **~$0.00**|

> **Free Tier Lambda:** 1 milhão de invocações e 400.000 GB-s por mês (permanente, não expira).  
> Com Free Tier: **$0.00**

### 1.4 Amazon API Gateway

| Item                          | Quantidade estimada | Preço (REST API)            | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| API calls                     | 250/mês            | $3.50/1M calls              | ~$0.00    |
| **Subtotal API Gateway**      |                    |                             | **~$0.00**|

> **Free Tier API Gateway:** 1 milhão de chamadas REST por mês (primeiros 12 meses).

### 1.5 Amazon DynamoDB

| Item                          | Quantidade estimada | Preço (On-Demand)           | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| Write Request Units           | 200 WRU/mês        | $1.25/1M WRU                | ~$0.00    |
| Read Request Units            | 500 RRU/mês        | $0.25/1M RRU                | ~$0.00    |
| Storage                       | < 1 MB             | $0.25/GB                    | ~$0.00    |
| **Subtotal DynamoDB**         |                    |                             | **~$0.00**|

> **Free Tier DynamoDB:** 25 GB de storage, 25 WCU e 25 RCU por mês (permanente).

### 1.6 Amazon SES (Simple Email Service)

| Item                          | Quantidade estimada | Preço                       | Custo/mês |
|-------------------------------|--------------------|-----------------------------|-----------|
| E-mails enviados              | 200/mês            | $0.10/1.000 e-mails         | ~$0.00    |
| **Subtotal SES**              |                    |                             | **~$0.00**|

> **Free Tier SES:** 3.000 e-mails/mês (quando enviados via Lambda/EC2).

---

## 2. Resumo de Custos

| Serviço        | Sem Free Tier | Com Free Tier |
|----------------|---------------|---------------|
| S3             | ~$0.13/mês    | $0.00         |
| CloudFront     | ~$0.14/mês    | $0.00         |
| Lambda         | ~$0.00/mês    | $0.00         |
| API Gateway    | ~$0.00/mês    | $0.00         |
| DynamoDB       | ~$0.00/mês    | $0.00         |
| SES            | ~$0.00/mês    | $0.00         |
| **TOTAL**      | **~$0.27/mês**| **$0.00**     |

---

## 3. Projeção Anual

| Cenário              | Custo/mês | Custo/ano    |
|----------------------|-----------|--------------|
| Com Free Tier (ano 1)| $0.00     | $0.00        |
| Após Free Tier (ano 2)| ~$0.27  | ~$3.24       |
| Crescimento moderado (10k visitas/mês) | ~$2.00 | ~$24.00 |

---

## 4. Estratégias de Otimização de Custos

### 4.1 Storage (S3)
- **Lifecycle policy** no bucket de assets: move objetos para S3 Standard-IA (30 dias) e Glacier (90 dias)
- Economia estimada: ~60% no custo de storage para arquivos antigos

### 4.2 CloudFront
- **PriceClass_100** selecionada (apenas Americas e Europe) em vez de PriceClass_All
- Cache TTL alto para assets estáticos reduz requisições à origem em ~95%

### 4.3 Lambda
- **Memory de 128MB** suficiente para o formulário de contato (menor custo)
- **Image processor com 512MB** para performance adequada com Sharp

### 4.4 Monitoramento de Custos
- **Billing Alert** configurado em $5 (aviso) e $10 (crítico)
- **Cost Explorer** revisado semanalmente
- **Budgets** com alerta automático por e-mail

---

## 5. Comparação com Hospedagem Tradicional

| Solução               | Custo/mês | Escalabilidade | SLA    |
|-----------------------|-----------|---------------|--------|
| Hosting compartilhado  | ~$5-15    | Limitada      | ~99.9% |
| VPS (1 CPU, 1GB RAM)  | ~$10-20   | Manual        | ~99.5% |
| **AWS S3 + CloudFront**| **~$0-3** | **Automática**| **99.99%** |

> A solução AWS é **mais barata**, **mais escalável** e com **SLA superior** à hospedagem tradicional.

---

## 6. Alerta de Limpeza

> ⚠️ **Após a avaliação**, execute `infrastructure/cleanup.sh` para deletar todos os recursos e garantir custo zero.

Checklist de limpeza:
- [ ] Delete distribuição CloudFront
- [ ] Esvaziar e deletar bucket website
- [ ] Esvaziar e deletar bucket assets
- [ ] Esvaziar e deletar bucket logs
- [ ] Delete funções Lambda
- [ ] Delete API Gateway
- [ ] Delete tabela DynamoDB
- [ ] Verificar Cost Explorer: $0 de custos futuros
