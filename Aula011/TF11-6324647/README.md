# Portfólio Profissional — Gabriel Santiago

> **TF11 · Implementação de Sistemas · ADS UniFAAT**  
> Portfólio pessoal hospedado na AWS com S3 + CloudFront CDN

---

## Visão Geral

Website estático de portfólio profissional com hospedagem no Amazon S3, distribuição global via CloudFront, formulário de contato serverless (API Gateway + Lambda + DynamoDB + SES) e upload de imagens com redimensionamento automático.

## Arquitetura

```
Usuário
  │
  ▼
CloudFront (CDN global · HTTPS · Gzip · Cache)
  │
  ├──▶ S3 Website Bucket (index.html, CSS, JS, imagens)
  │
  └──▶ API Gateway
         ├──▶ Lambda: contact-form ──▶ DynamoDB + SES
         └──▶ Lambda: image-processor ──▶ S3 Assets Bucket
```

## URLs do Projeto

| Recurso | URL |
|---|---|
| Website (CloudFront) | `https://<id>.cloudfront.net` |
| S3 direto (teste) | `http://portfolio-gabriel-santiago-www.s3-website-us-east-1.amazonaws.com` |
| API contato | `https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/contact` |
| API upload | `https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/upload` |

## Estrutura do Projeto

```
TF11-6324647/
├── website/
│   ├── index.html          # Página principal + hero + destaques
│   ├── projetos.html       # Galeria + upload de imagens
│   ├── experiencia.html    # Timeline profissional e acadêmica
│   ├── contato.html        # Formulário integrado à API
│   ├── error.html          # Página de erro 404 customizada
│   ├── css/style.css       # Design system responsivo (CSS Grid/Flex)
│   ├── js/main.js          # Lazy loading, animações, nav ativa
│   ├── js/app.js           # Formulário + upload (integração API)
│   ├── images/             # Imagens otimizadas (WebP)
│   └── docs/               # CV e documentos para download
├── infrastructure/
│   ├── create-buckets.sh   # Cria e configura buckets S3
│   ├── setup-cloudfront.sh # Cria distribuição CloudFront + OAC
│   ├── configure-policies.sh # Deploy do site + CORS + invalidação
│   └── cleanup.sh          # Remove todos os recursos AWS
├── lambda/
│   ├── image-processor/    # Redimensiona imagens via S3 trigger
│   └── contact-form/       # Recebe form → DynamoDB + SES
└── docs/
    ├── performance-report.md
    ├── security-analysis.md
    └── cost-analysis.md
```

## Como Executar

### Pré-requisitos
- AWS CLI configurado (`aws configure`)
- Python 3.11+ (para os Lambdas)
- Permissões IAM: S3, CloudFront, Lambda, API Gateway, DynamoDB, SES

### Passo a Passo

```bash
# 1. Criar buckets S3
cd infrastructure
chmod +x *.sh
./create-buckets.sh

# 2. Criar distribuição CloudFront
./setup-cloudfront.sh

# 3. Deploy do website e configurar políticas
export DISTRIBUTION_ID="<id-retornado-no-passo-2>"
./configure-policies.sh

# 4. Deploy dos Lambdas (via console ou SAM)
cd ../lambda/contact-form
zip -r function.zip handler.py
aws lambda create-function \
  --function-name portfolio-contact-form \
  --runtime python3.11 \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<account>:role/lambda-portfolio-role \
  --environment Variables="{
    DYNAMODB_TABLE=portfolio-contacts,
    FROM_EMAIL=noreply@seudominio.com,
    TO_EMAIL=gabriel@seudominio.com
  }"
```

### Variáveis de Ambiente dos Lambdas

| Lambda | Variável | Descrição |
|---|---|---|
| contact-form | `DYNAMODB_TABLE` | Nome da tabela DynamoDB |
| contact-form | `FROM_EMAIL` | Email verificado no SES |
| contact-form | `TO_EMAIL` | Email de destino das notificações |
| image-processor | `BUCKET_ASSETS` | Nome do bucket de assets |
| image-processor | `MAX_WIDTH` | Largura máxima da imagem (padrão: 1200) |

## Tecnologias Utilizadas

| Serviço | Uso |
|---|---|
| Amazon S3 | Hospedagem estática + armazenamento de assets |
| CloudFront | CDN global, HTTPS, compressão, cache |
| Lambda (Python 3.11) | Formulário de contato e processamento de imagens |
| API Gateway | Endpoints REST para o frontend |
| DynamoDB | Armazenamento de mensagens de contato |
| SES | Notificações por email |
| CloudWatch | Métricas, logs e alarmes |

## Performance

Veja [docs/performance-report.md](docs/performance-report.md) para métricas detalhadas.

- PageSpeed Insights: **≥ 90** (meta)
- Cache hit rate CloudFront: **> 85%** (meta)
- TTFB via CloudFront: **< 100ms** (meta)

## Segurança

Veja [docs/security-analysis.md](docs/security-analysis.md).

- Acesso ao S3 apenas via CloudFront OAC (sem acesso público direto)
- HTTPS obrigatório em todas as rotas
- Headers de segurança via CloudFront Response Headers Policy
- Versionamento e lifecycle policies nos buckets

## Custos Estimados

Veja [docs/cost-analysis.md](docs/cost-analysis.md).

Estimativa mensal para portfólio pessoal (~10.000 requisições/mês): **< USD 1,00**

---

*Desenvolvido para o TF11 de Implementação de Sistemas — ADS UniFAAT — Prof. Alexandre Tavares*
