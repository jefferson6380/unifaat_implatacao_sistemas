# Diagrama de Arquitetura

## Visão Geral

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USUÁRIO FINAL                               │
│                    (Browser / Dispositivo)                          │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    AMAZON CLOUDFRONT (CDN)                          │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  • Distribuição global (edge locations)                     │   │
│  │  • HTTPS obrigatório (redirect HTTP → HTTPS)                │   │
│  │  • Compressão Gzip habilitada                               │   │
│  │  │  Cache Policy:                                           │   │
│  │  │    HTML  → no-cache (sempre busca origem)                │   │
│  │  │    CSS   → max-age=86400 (1 dia)                         │   │
│  │  │    JS    → max-age=86400 (1 dia)                         │   │
│  │  │    IMG   → max-age=604800 (7 dias)                       │   │
│  │  • Security Headers Policy (HSTS, X-Frame, CSP, etc.)      │   │
│  │  • Custom Error: 404 → /404.html                           │   │
│  └─────────────────────────────────────────────────────────────┘   │
└────────────┬───────────────────────────────────────────────────────┘
             │ OAC (Origin Access Control)
             ▼
┌────────────────────────────────────┐   ┌──────────────────────────┐
│   S3 BUCKET — WEBSITE ESTÁTICO     │   │  S3 BUCKET — ASSETS      │
│   portfolio-website-6324548        │   │  portfolio-assets-6324548│
│                                    │   │                          │
│  index.html                        │   │  images/                 │
│  projetos.html                     │   │  docs/                   │
│  experiencia.html                  │   │  processed/ (WebP)       │
│  contato.html                      │   │                          │
│  404.html                          │   │  • CORS habilitado       │
│  css/style.css                     │   │  • Versionamento ON      │
│  js/main.js                        │   │  • Lifecycle: S3-IA/30d  │
│                                    │   └──────────┬───────────────┘
│  • Block public access (via OAC)   │              │ S3 Event
│  • Versionamento ON                │              ▼
│  • Lifecycle: S3-IA após 30 dias   │   ┌──────────────────────────┐
│  • Access Logs → logs bucket       │   │  LAMBDA: image-processor │
└────────────────────────────────────┘   │                          │
                                         │  • Resize → 800px wide   │
                                         │  • Converter para WebP   │
                                         │  • Salva em processed/   │
                                         │  • Runtime: Python 3.12  │
                                         │  • Layer: Pillow         │
                                         └──────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                    FORMULÁRIO DE CONTATO                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │ HTTPS POST /contact
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   API GATEWAY (REST API)                            │
│  • Endpoint: POST /prod/contact                                     │
│  • CORS configurado                                                 │
│  • Throttling: 100 req/s                                            │
└────────────────────────────┬────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  LAMBDA: contact-form                               │
│  • Validação de dados (nome, email, assunto, mensagem)              │
│  • Runtime: Python 3.12                                             │
└────────────────┬────────────────────────────────┬───────────────────┘
                 │                                │
                 ▼                                ▼
┌───────────────────────────┐    ┌────────────────────────────────────┐
│  DYNAMODB                 │    │  AMAZON SES                        │
│  Tabela: portfolio-contacts│   │  Notificação por email             │
│  • Partition key: id (UUID)│   │  From: luizfelipe@althaia.com.br   │
│  • TTL: 1 ano             │    │  To: luizfelipe@althaia.com.br     │
│  • PAY_PER_REQUEST        │    │  HTML + texto plain                │
└───────────────────────────┘    └────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                  MONITORAMENTO (CloudWatch)                         │
│  • Métricas: S3 requests, CloudFront cache hit/miss                 │
│  • Lambda: invocações, erros, duração                               │
│  • Alarme de billing: $10                                           │
│  • Dashboard: visão consolidada                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Fluxo de Acesso ao Website

1. Usuário acessa `https://<cloudfront-domain>`
2. CloudFront verifica cache no edge location mais próximo
3. **Cache HIT** → resposta em ~5ms diretamente do edge
4. **Cache MISS** → CloudFront busca no S3 via OAC, armazena no cache, responde
5. S3 retorna arquivo com headers de segurança aplicados pela Response Headers Policy

## Fluxo de Upload de Imagem

1. Usuário seleciona imagem em `projetos.html`
2. JavaScript faz `POST /upload` para API Gateway
3. Lambda retorna presigned URL do S3
4. Frontend faz `PUT` diretamente para o S3 (sem passar pela Lambda)
5. S3 dispara evento para Lambda `image-processor`
6. Lambda processa: resize + WebP → salva em `processed/`

## Fluxo do Formulário de Contato

1. Usuário preenche `contato.html` e envia
2. JavaScript valida campos no frontend
3. `POST /contact` para API Gateway
4. Lambda valida novamente no backend (dupla validação)
5. Dados salvos no DynamoDB com UUID + timestamp
6. Email enviado via SES para o portfólio
7. Resposta de sucesso retorna para o frontend
