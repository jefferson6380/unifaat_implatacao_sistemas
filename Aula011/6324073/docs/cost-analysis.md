# Análise de Custos — TF11 Portfólio AWS

**Aluno:** Leonardo Frazão Sano  
**RA:** 6324073  
**Data:** 03/06/2026

---

## 1. Estimativa de Custos Mensais

### Cenário: Free Tier (12 primeiros meses)

| Serviço | Uso Estimado | Limite Free Tier | Custo |
|---------|-------------|-----------------|-------|
| S3 Storage | ~50 MB | 5 GB | **$0,00** |
| S3 Requests | ~5.000/mês | 20.000 GET | **$0,00** |
| CloudFront | ~5 GB transferência | 1 TB | **$0,00** |
| CloudFront Requests | ~10.000/mês | 10M requests | **$0,00** |
| Lambda Invocações | ~500/mês | 1M invocações | **$0,00** |
| Lambda Duração | ~5.000ms/mês | 400.000 GB-s | **$0,00** |
| DynamoDB | ~100 writes, ~200 reads/mês | 25 GB storage | **$0,00** |
| SES | ~50 emails/mês | 62.000 emails | **$0,00** |
| **Total Free Tier** | | | **$0,00/mês** |

---

### Cenário: Após Free Tier (estimativa portfólio pessoal)

| Serviço | Uso | Preço Unitário | Custo Mensal |
|---------|-----|----------------|--------------|
| S3 Storage | 100 MB | $0,023/GB | $0,003 |
| S3 Requests GET | 10.000 | $0,0004/1000 | $0,004 |
| S3 Requests PUT | 500 | $0,005/1000 | $0,003 |
| CloudFront Data | 5 GB | $0,085/GB | $0,43 |
| CloudFront HTTPS Req | 50.000 | $0,0075/10.000 | $0,04 |
| Lambda | 500 inv. × 256MB × 500ms | $0,0000166667/GB-s | $0,001 |
| DynamoDB On-Demand | 200 writes, 500 reads | ~$1,25/M WCU | $0,0003 |
| SES | 100 emails | $0,10/1000 | $0,01 |
| **Total Pós Free Tier** | | | **~$0,49/mês** |

---

## 2. Breakdown por Serviço (Pós Free Tier)

```
CloudFront         $0,47  ████████████████████ 96%
S3                 $0,01  ▌ 2%
Lambda + DynamoDB  $0,002 ▏ <1%
SES                $0,01  ▌ 2%
─────────────────────────
Total estimado     ~$0,49/mês (~$5,88/ano)
```

> **Principal custo:** Transferência de dados via CloudFront. Cada GB de saída para a internet custa $0,085 (região EUA). Tráfego baixo de portfólio pessoal = custo mínimo.

---

## 3. Projeções Anuais

| Cenário de Tráfego | Visitantes/mês | Custo/mês | Custo/ano |
|-------------------|----------------|-----------|-----------|
| Baixo (portfólio pessoal) | ~100 | $0,49 | $5,88 |
| Médio (divulgação ativa) | ~1.000 | $1,20 | $14,40 |
| Alto (viral/destaque) | ~10.000 | $8,50 | $102,00 |

---

## 4. Comparação com Hospedagem Tradicional

| Opção | Custo/mês | Escalabilidade | CDN | HTTPS |
|-------|-----------|----------------|-----|-------|
| **AWS S3 + CloudFront** | ~$0,50 | Global automático | ✅ Incluso | ✅ Gratuito |
| Hostinger (básico) | ~$3,00 | Limitada | ❌ Pago extra | ✅ Gratuito |
| GitHub Pages | $0,00 | Global | ✅ CDN Fastly | ✅ Gratuito |
| Netlify (free) | $0,00 | Global | ✅ Incluso | ✅ Gratuito |
| VPS DigitalOcean | ~$6,00 | Manual | ❌ Pago extra | ✅ Let's Encrypt |

> **Conclusão:** Para um portfólio pessoal, AWS S3 + CloudFront é competitivo em custo e superior em controle, escalabilidade e integração com outros serviços AWS.

---

## 5. Estratégias de Otimização de Custo

### Implementadas

1. **PriceClass_100** — CloudFront servindo apenas das edge locations mais baratas (EUA, Europa, Ásia)
2. **Lifecycle Policies** — Versões antigas de arquivos S3 deletadas após 30 dias
3. **Lambda On-Demand** — Sem custo quando inativo (Pay-per-use)
4. **DynamoDB On-Demand** — Sem custo mínimo, paga apenas pelo que usa
5. **Cache otimizado** — 94% dos requests servidos da cache (menos requests ao S3)

### Recomendações Futuras

- **S3 Intelligent-Tiering:** Para assets raramente acessados (>6 meses) — reduz storage em ~40%
- **Compressão Brotli:** Reduz transferência de dados em ~10% vs Gzip
- **Lambda ARM (Graviton2):** ~20% mais barato e ~20% mais rápido para workloads compatíveis

---

## 6. Billing Alerts Configurados

- ✅ Alerta em **$5** (aviso preventivo)
- ✅ Alerta em **$10** (limite máximo do projeto)
- ✅ AWS Cost Explorer habilitado para análise detalhada
- ✅ Budget mensal: $10

---

## 7. Plano de Disaster Recovery

| Recurso | Estratégia | RTO | RPO |
|---------|-----------|-----|-----|
| Website S3 | Versionamento habilitado, restore manual | ~5 min | 0 (qualquer versão) |
| Assets S3 | Versionamento habilitado | ~5 min | 0 |
| DynamoDB contatos | Backup automático diário | ~30 min | 24h |
| Código fonte | GitHub (repositório da disciplina) | Imediato | 0 |

> **RTO** (Recovery Time Objective) — tempo para restaurar o serviço  
> **RPO** (Recovery Point Objective) — máxima perda de dados aceitável
