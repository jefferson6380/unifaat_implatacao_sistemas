# Portfólio Profissional — Leonardo Frazão Sano

**RA:** 6324073  
**Curso:** Análise e Desenvolvimento de Sistemas — UniFAAT  
**Disciplina:** Implementação de Sistemas  
**Trabalho:** TF11 — Sistema de Portfólio com S3 e CloudFront

---

## Visão Geral

Portfólio pessoal profissional hospedado na AWS utilizando S3 para website estático e CloudFront como CDN global. O projeto demonstra domínio de armazenamento em nuvem, distribuição de conteúdo, funções serverless e boas práticas de segurança e performance.

---

## Arquitetura

```
Usuário
  │
  ▼
CloudFront (CDN Global + HTTPS + Gzip)
  │
  ├──→ S3 Website Bucket (HTML, CSS, JS)
  │
  └──→ S3 Assets Bucket (imagens WebP processadas)
             │
             ▼
         Lambda: image-processor
         (Sharp · resize · WebP)

Formulário de Contato:
  Usuário → API Gateway → Lambda: contact-form
                               │
                               ├──→ DynamoDB (armazenar mensagem)
                               └──→ SES (notificação por e-mail)
```

---

## Tecnologias Utilizadas

| Camada | Tecnologia |
|--------|-----------|
| Frontend | HTML5, CSS3 (Grid/Flexbox), JavaScript ES6+ |
| Hospedagem | Amazon S3 (Static Website Hosting) |
| CDN | Amazon CloudFront |
| Processamento | AWS Lambda (Node.js 20.x) |
| API | Amazon API Gateway (REST) |
| Banco de Dados | Amazon DynamoDB |
| E-mail | Amazon SES |
| Imagens | Sharp (resize + WebP) |
| Segurança | IAM, HTTPS, Security Headers, CSP |
| Monitoramento | CloudWatch, S3 Access Logs, Billing Alerts |

---

## URLs do Projeto

| Recurso | URL |
|---------|-----|
| Website (CloudFront) | `https://d186fgjidbmv2l.cloudfront.net` |
| Website (S3 direto) | `http://portfolio-lfs-website-6324073.s3-website-us-east-1.amazonaws.com` |
| Assets Bucket | `s3://portfolio-lfs-assets-6324073` |
| API Gateway | `https://okadj41b1e.execute-api.us-east-1.amazonaws.com/prod` |

---

## Estrutura do Projeto

```
TF11-LeonardoFrazaoSano/
├── README.md
├── website/
│   ├── index.html          # Página principal e apresentação
│   ├── projetos.html       # Galeria de projetos + upload de imagens
│   ├── experiencia.html    # Timeline acadêmica e profissional
│   ├── contato.html        # Formulário de contato (API Gateway)
│   ├── 404.html            # Página de erro customizada
│   ├── css/
│   │   └── style.css       # Estilos responsivos (CSS custom properties)
│   ├── js/
│   │   ├── main.js         # Navegação, animações, formulário de contato
│   │   └── upload.js       # Upload de imagens para S3 (presigned URL)
│   └── images/             # Imagens otimizadas do portfólio
├── infrastructure/
│   ├── create-buckets.sh   # Cria e configura os buckets S3
│   ├── setup-cloudfront.sh # Cria distribuição CloudFront
│   ├── configure-policies.sh # IAM, DynamoDB, logs e alertas
│   └── cleanup.sh          # Remove todos os recursos AWS
├── lambda/
│   ├── image-processor/    # Redimensiona imagens e gera WebP
│   │   ├── index.js
│   │   └── package.json
│   └── contact-form/       # Salva contato no DynamoDB e envia e-mail
│       ├── index.js
│       └── package.json
└── docs/
    ├── performance-report.md  # Métricas e comparações de velocidade
    ├── security-analysis.md   # Análise de segurança e headers
    └── cost-analysis.md       # Estimativa e análise de custos
```

---

## Como Executar (Deploy Passo a Passo)

### Pré-requisitos

- AWS CLI instalado e configurado (`aws configure`)
- Node.js 20.x instalado
- Conta AWS com permissões para S3, CloudFront, Lambda, API Gateway, DynamoDB, SES, IAM

### 1. Configurar buckets S3

```bash
cd infrastructure
chmod +x *.sh
./create-buckets.sh
```

Este script:
- Cria o bucket de website com static hosting habilitado
- Cria o bucket de assets com CORS configurado
- Aplica políticas de acesso público
- Habilita versionamento e lifecycle policies
- Faz upload de todos os arquivos do website

### 2. Configurar CloudFront

```bash
./setup-cloudfront.sh
```

Este script:
- Cria distribuição CloudFront apontando para o bucket S3
- Configura redirect HTTP → HTTPS
- Habilita compressão Gzip/Brotli
- Configura cache policies por tipo de arquivo
- Configura security headers (HSTS, CSP, X-Frame-Options, etc.)

> A distribuição leva **10-15 minutos** para propagar globalmente.

### 3. Configurar políticas e monitoramento

```bash
./configure-policies.sh
```

Este script:
- Cria IAM Role para as Lambdas (princípio do menor privilégio)
- Cria tabela DynamoDB para armazenar contatos
- Habilita logs de acesso no S3
- Configura alerta de billing ($10)
- Configura lifecycle no bucket de assets

### 4. Deploy das Lambda Functions

```bash
# Lambda: processador de imagens
cd ../lambda/image-processor
npm install
zip -r function.zip .
aws lambda create-function \
  --function-name portfolio-image-processor-6324073 \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::ACCOUNT_ID:role/portfolio-lambda-role-6324073 \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 512

# Lambda: formulário de contato
cd ../contact-form
npm install
zip -r function.zip .
aws lambda create-function \
  --function-name portfolio-contact-form-6324073 \
  --runtime nodejs20.x \
  --handler index.handler \
  --role arn:aws:iam::ACCOUNT_ID:role/portfolio-lambda-role-6324073 \
  --zip-file fileb://function.zip \
  --timeout 15 \
  --memory-size 256 \
  --environment Variables="{TABLE_NAME=portfolio-contacts-6324073,FROM_EMAIL=leosano2006@gmail.com,TO_EMAIL=leosano2006@gmail.com}"
```

### 5. Configurar API Gateway

```bash
# Criar REST API
API_ID=$(aws apigateway create-rest-api \
  --name portfolio-lfs-api \
  --query 'id' --output text)

# ... (configurar recursos /contact e /upload-url, métodos POST, integração Lambda)
# Recomendado: usar o console AWS para esta etapa

echo "API ID: ${API_ID}"
```

### 6. Atualizar URLs no código

Após criar o API Gateway, atualizar em `website/js/main.js` e `website/js/upload.js`:

```javascript
const API_URL = 'https://SEU_API_ID.execute-api.us-east-1.amazonaws.com/prod';
```

Então re-fazer upload do website:
```bash
cd infrastructure
./create-buckets.sh  # ou: aws s3 sync ../website s3://portfolio-lfs-website-6324073
```

---

## Performance

| Métrica | S3 Direto | CloudFront | Melhoria |
|---------|-----------|------------|----------|
| TTFB | 320ms | 42ms | -87% |
| PageSpeed Mobile | ~78 | 94 | +16 pts |
| PageSpeed Desktop | ~83 | 98 | +15 pts |
| Cache Hit Rate | — | 94% | — |

Detalhes em: [`docs/performance-report.md`](docs/performance-report.md)

---

## Custos

| Período | Custo estimado |
|---------|---------------|
| 12 primeiros meses (Free Tier) | **$0,00/mês** |
| Após Free Tier (baixo tráfego) | **~$0,49/mês** |
| Após Free Tier (médio tráfego) | **~$1,20/mês** |

Detalhes em: [`docs/cost-analysis.md`](docs/cost-analysis.md)

---

## Segurança

- HTTPS obrigatório (redirect HTTP → HTTPS no CloudFront)
- Security Headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- Bucket policies restritivas (princípio do menor privilégio)
- Validação de entrada no backend (Lambda)
- Presigned URLs para upload (expiram em 15 minutos)

Detalhes em: [`docs/security-analysis.md`](docs/security-analysis.md)

---

## Limpeza dos Recursos

**Após a avaliação, execute para evitar cobranças:**

```bash
cd infrastructure
./cleanup.sh
```

Verifique no [console de billing](https://console.aws.amazon.com/billing) se todos os recursos foram removidos.

---

## Desafios e Soluções

| Desafio | Solução |
|---------|---------|
| CORS nas chamadas da Lambda via API Gateway | Cabeçalhos CORS adicionados diretamente na resposta da Lambda |
| Cache do CloudFront servindo HTML desatualizado | Cache policy `no-cache` específica para arquivos `.html` |
| Upload de imagens grandes com presigned URL | Validação de tamanho no cliente antes de solicitar URL |
| Custo de transferência CloudFront | PriceClass_100 limita às edge locations mais baratas |

---

*Desenvolvido por Leonardo Frazão Sano — RA 6324073 — UniFAAT 2026*
