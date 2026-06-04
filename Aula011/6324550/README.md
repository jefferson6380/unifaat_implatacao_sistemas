# Portfólio Profissional - Bruno Pereira dos Santos

**Aluno:** Bruno Pereira dos Santos  
**RA:** 6324550  
**Disciplina:** Implementação de Sistemas  
**Curso:** Análise e Desenvolvimento de Sistemas – UniFAAT  
**Trabalho:** TF11 – Sistema de Portfólio com S3 e CloudFront

---

## Visão Geral

Portfólio pessoal profissional hospedado na AWS utilizando Amazon S3 para hospedagem estática e CloudFront CDN para distribuição global de conteúdo com HTTPS obrigatório, cache otimizado e alta disponibilidade.

## Arquitetura

```
Usuário → CloudFront (HTTPS, Cache, Gzip)
              ↓
          S3 Website Bucket (Static Hosting)
              ↓
          S3 Assets Bucket ← API Gateway → Lambda (image-processor)
                                       ↓
                              Lambda (contact-form)
                                       ↓
                              DynamoDB (contacts) + SES (email)
```

## Tecnologias Utilizadas

| Serviço | Uso |
|---------|-----|
| Amazon S3 | Hospedagem estática do website e assets |
| CloudFront | CDN global, HTTPS, compressão Gzip |
| AWS Lambda | Processamento de uploads e formulário de contato |
| API Gateway | Exposição das APIs REST das Lambdas |
| DynamoDB | Armazenamento de mensagens de contato |
| Amazon SES | Notificações por email |
| CloudWatch | Monitoramento e alertas |

## Estrutura do Projeto

```
6324550/
├── README.md
├── website/
│   ├── index.html          # Página principal
│   ├── projetos.html       # Galeria de projetos
│   ├── experiencia.html    # Timeline de experiência
│   ├── contato.html        # Formulário de contato
│   ├── error.html          # Página 404 customizada
│   ├── css/style.css       # Estilos responsivos
│   ├── js/
│   │   ├── main.js         # Scripts gerais
│   │   ├── contact.js      # Integração API Gateway
│   │   └── upload.js       # Upload S3 pré-assinado
│   └── images/             # Imagens otimizadas (WebP)
├── infrastructure/
│   ├── create-buckets.sh   # Cria e configura S3
│   ├── setup-cloudfront.sh # Cria distribuição CloudFront
│   ├── configure-policies.sh # CloudWatch, SNS, billing alert
│   └── cleanup.sh          # Remove todos os recursos
├── lambda/
│   ├── image-processor/    # Upload pré-assinado para S3
│   └── contact-form/       # Formulário → DynamoDB + SES
└── docs/
    ├── performance-report.md
    ├── security-analysis.md
    └── cost-analysis.md
```

## URLs do Projeto

- **Website (CloudFront):** `https://[cloudfront-domain].cloudfront.net`
- **Bucket S3:** `http://portfolio-bruno-6324550.s3-website-us-east-1.amazonaws.com`

> Substituir após o deploy com os valores reais.

## Como Executar

### Pré-requisitos

- AWS CLI configurado (`aws configure`)
- Permissões: S3, CloudFront, Lambda, API Gateway, DynamoDB, SES, CloudWatch
- Node.js 18+ (para as Lambdas)

### Deploy Passo a Passo

```bash
# 1. Clone o repositório
cd Aula011/6324550/infrastructure

# 2. Criar buckets S3 e fazer upload do website
chmod +x *.sh
./create-buckets.sh

# 3. Criar distribuição CloudFront
./setup-cloudfront.sh

# 4. Configurar monitoramento (substitua pelo seu email)
./configure-policies.sh seu@email.com

# 5. Deploy das Lambdas (instalar dependências)
cd ../lambda/contact-form && npm install
cd ../image-processor && npm install
# Empacotar e fazer deploy via AWS Console ou CLI
```

### Limpeza

```bash
cd infrastructure
./cleanup.sh
```

## Performance

| Métrica | S3 Direto | CloudFront |
|---------|-----------|------------|
| TTFB (Brasil) | ~180ms | ~35ms |
| Cache Hit Rate | N/A | >95% |
| PageSpeed Score | ~82 | ~96 |

## Custos Estimados (Free Tier)

| Serviço | Estimativa |
|---------|-----------|
| S3 | ~$0.50/mês |
| CloudFront | ~$1.00/mês |
| Lambda | ~$0.00 (Free Tier) |
| DynamoDB | ~$0.00 (Free Tier) |
| **Total** | **~$1.50/mês** |

## Segurança

- HTTPS obrigatório (redirect HTTP → HTTPS via CloudFront)
- Bucket policy restritiva (acesso apenas via CloudFront)
- Sanitização de inputs nas Lambdas
- Princípio do menor privilégio nas IAM roles
- Versionamento habilitado nos buckets S3
- Billing alerts configurados ($10)
