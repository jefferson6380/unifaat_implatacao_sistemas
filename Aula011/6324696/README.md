# Portfólio Profissional — Natan Borges Leme

**RA:** 6324696  
**Curso:** Análise e Desenvolvimento de Sistemas  
**Instituição:** UniFAAT — Faculdades Atibaia  
**Disciplina:** Implementação de Sistemas — TF11

---

## Visão Geral

Portfólio pessoal profissional desenvolvido como trabalho final (TF11) da disciplina de Implementação de Sistemas. O projeto demonstra a utilização de serviços AWS para hospedagem estática, distribuição de conteúdo via CDN, processamento serverless de imagens e persistência de dados.

---

## Arquitetura

```
Usuário
  │
  ▼
CloudFront (CDN Global)
  ├── HTTPS obrigatório
  ├── Cache policies otimizadas
  ├── Security headers (HSTS, CSP, X-Frame-Options...)
  └── Compressão Gzip/Brotli
        │
        ▼
S3 Bucket (Website Estático)
  ├── index.html
  ├── projetos.html
  ├── experiencia.html
  ├── contato.html
  ├── css/, js/, images/
  └── 404.html
        │
        ├── [Upload] ──► S3 Assets Bucket ──► Lambda (image-processor)
        │                                         └── WebP resize: thumb/medium/large
        │
        └── [Contato] ──► API Gateway ──► Lambda (contact-form)
                                              ├── DynamoDB (salva contato)
                                              └── SES (envia e-mail de notificação)
```

---

## Tecnologias Utilizadas

| Categoria     | Tecnologia               | Uso                                   |
|---------------|--------------------------|---------------------------------------|
| Frontend      | HTML5, CSS3, JavaScript ES6+ | Interface responsiva do portfólio |
| CDN           | Amazon CloudFront        | Distribuição global, HTTPS, cache     |
| Storage       | Amazon S3                | Hospedagem estática e assets          |
| Serverless    | AWS Lambda (Node.js 18)  | Processamento de imagens e formulário |
| API           | Amazon API Gateway       | Endpoint REST para o formulário       |
| Banco de dados| Amazon DynamoDB          | Armazenamento de contatos             |
| E-mail        | Amazon SES               | Notificações de novos contatos        |
| Monitoramento | Amazon CloudWatch        | Métricas, alertas e logs              |

---

## Estrutura do Projeto

```
6324696/
├── README.md
├── website/
│   ├── index.html          ← Página principal (hero, about, skills)
│   ├── projetos.html       ← Galeria de projetos + upload de imagens
│   ├── experiencia.html    ← Timeline acadêmica e profissional
│   ├── contato.html        ← Formulário de contato funcional
│   ├── 404.html            ← Página de erro customizada
│   ├── css/
│   │   └── style.css       ← Estilos responsivos (dark theme)
│   ├── js/
│   │   ├── main.js         ← Nav mobile, scroll, fade-in, lazy loading, filtros
│   │   ├── contact.js      ← Integração com API Gateway + validação
│   │   └── upload.js       ← Upload de imagens para S3 (URL pré-assinada)
│   └── images/
│       └── favicon.svg     ← Ícone do site
├── infrastructure/
│   ├── create-buckets.sh   ← Cria e configura os buckets S3
│   ├── configure-policies.sh ← Bucket policies e CORS
│   ├── setup-cloudfront.sh ← Cria distribuição CloudFront + faz upload
│   └── cleanup.sh          ← Remove TODOS os recursos após avaliação
├── lambda/
│   ├── contact-form/
│   │   ├── index.js        ← DynamoDB + SES
│   │   └── package.json
│   └── image-processor/
│       ├── index.js        ← Sharp: redimensiona e converte para WebP
│       └── package.json
└── docs/
    ├── architecture-diagram.svg ← Diagrama da arquitetura AWS
    ├── performance-report.md    ← Métricas S3 vs CloudFront
    ├── security-analysis.md     ← Políticas, headers, OWASP
    └── cost-analysis.md         ← Breakdown de custos por serviço
```

---

## Como Executar (Deploy na AWS)

### Pré-requisitos
- AWS CLI instalado e configurado (`aws configure`)
- Conta AWS com acesso a S3, CloudFront, Lambda, API Gateway, DynamoDB, SES
- Node.js 18+ (para instalar dependências Lambda)
- Billing Alert configurado (recomendado: $5 e $10)

### Passo 1 — Criar Buckets S3
```bash
chmod +x infrastructure/*.sh
./infrastructure/create-buckets.sh
```

### Passo 2 — Configurar Políticas
```bash
./infrastructure/configure-policies.sh
```

### Passo 3 — Deploy do CloudFront
```bash
./infrastructure/setup-cloudfront.sh
# Aguarde ~15 minutos para propagação global
```

### Passo 4 — Deploy das Lambdas

**contact-form:**
```bash
cd lambda/contact-form
npm install
zip -r contact-form.zip .
aws lambda create-function \
  --function-name portfolio-contact-form \
  --runtime nodejs18.x \
  --handler index.handler \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-portfolio-role \
  --zip-file fileb://contact-form.zip \
  --environment Variables="{TABLE_NAME=portfolio-contacts,SES_FROM=lemenatan@gmail.com,NOTIFY_EMAIL=lemenatan@gmail.com}"
```

**image-processor:**
```bash
cd lambda/image-processor
npm install
zip -r image-processor.zip .
aws lambda create-function \
  --function-name portfolio-image-processor \
  --runtime nodejs18.x \
  --handler index.handler \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-portfolio-role \
  --zip-file fileb://image-processor.zip \
  --timeout 30 \
  --memory-size 512 \
  --environment Variables="{DEST_BUCKET=natan-portifolio-assets-6324696}"
```

### Passo 5 — Atualizar URLs nos arquivos JS

Após criar o API Gateway, substitua em `website/js/contact.js`:
```js
const API_ENDPOINT = 'https://SEU-ID.execute-api.us-east-1.amazonaws.com/prod/contact';
```

Após configurar o endpoint de upload, substitua em `website/js/upload.js`:
```js
const UPLOAD_URL = 'https://SEU-ID.execute-api.us-east-1.amazonaws.com/prod/upload';
```

Faça novo upload do JS atualizado:
```bash
aws s3 cp website/js/contact.js s3://natan-portifolio-website-6324696/js/contact.js
aws s3 cp website/js/upload.js  s3://natan-portifolio-website-6324696/js/upload.js
aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/js/*"
```

---

## URLs do Projeto

| Recurso           | URL                                                     |
|-------------------|---------------------------------------------------------|
| Website (CloudFront) | `https://d1vcy90z47avke.cloudfront.net`                |
| Website (S3 direto)  | `http://natan-portifolio-website-6324696.s3-website-us-east-1.amazonaws.com` |
| API Contact Form     | `https://uz0yosc5ub.execute-api.us-east-1.amazonaws.com/prod/contact` |

---

## Performance

- **PageSpeed (Mobile):** 95+ ✅  
- **PageSpeed (Desktop):** 98+ ✅  
- **TTFB via CloudFront:** ~45ms ✅  
- **Cache Hit Ratio:** ~95% ✅  
- Detalhes completos em [`docs/performance-report.md`](docs/performance-report.md)

---

## Segurança

- HTTPS obrigatório com TLSv1.2_2021
- Security headers: HSTS, CSP, X-Frame-Options, X-Content-Type-Options
- Bucket policies restritivas (menor privilégio)
- Proteção anti-spam no formulário (honeypot + rate limiting)
- Detalhes completos em [`docs/security-analysis.md`](docs/security-analysis.md)

---

## Custos

- **Com Free Tier:** $0.00/mês
- **Após Free Tier:** ~$0.27/mês
- Detalhes completos em [`docs/cost-analysis.md`](docs/cost-analysis.md)

---

## Limpeza (após avaliação)

```bash
./infrastructure/cleanup.sh
```

> ⚠️ Execute após a avaliação para evitar custos residuais.

---

## Autor

**Natan Borges Leme** — RA 6324696  
Análise e Desenvolvimento de Sistemas — UniFAAT  
TF11 — Implementação de Sistemas
