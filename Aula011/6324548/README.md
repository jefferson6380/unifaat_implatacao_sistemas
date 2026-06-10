# Portfólio Profissional — Luiz Felipe Souza

**RA**: 6324548 | **Disciplina**: Implementação de Sistemas | **UniFAAT**

## Visão Geral

Portfólio pessoal profissional hospedado na AWS, utilizando Amazon S3 para hospedagem estática e CloudFront como CDN global. Inclui formulário de contato serverless (Lambda + API Gateway + DynamoDB + SES) e pipeline automático de processamento de imagens.

## Arquitetura

```
Usuário → CloudFront (CDN) → S3 (Website Estático)
                                ↓
                         S3 Assets Bucket → Lambda (image-processor)
                                ↓
Formulário → API Gateway → Lambda (contact-form) → DynamoDB + SES
```

Diagrama detalhado: [docs/architecture-diagram.md](docs/architecture-diagram.md)

## Tecnologias Utilizadas

| Serviço | Uso |
|---------|-----|
| Amazon S3 | Hospedagem estática + armazenamento de assets |
| CloudFront | CDN global, HTTPS, cache, security headers |
| AWS Lambda | Processamento de imagens + formulário de contato |
| API Gateway | REST API para o formulário |
| DynamoDB | Armazenamento de mensagens de contato |
| Amazon SES | Notificação por email |
| CloudWatch | Monitoramento e alarmes de custo |

## URLs do Projeto

- **Website (CloudFront)**: `https://<cloudfront-domain>.cloudfront.net`
- **Bucket S3**: `s3://portfolio-website-6324548`
- **API de Contato**: `https://<api-id>.execute-api.us-east-1.amazonaws.com/prod/contact`

> Preencher após o deploy com `setup-cloudfront.sh`

## Estrutura do Projeto

```
TF11-LuizFelipeSouza/
├── README.md
├── website/
│   ├── index.html          # Página principal com hero e sobre
│   ├── projetos.html       # Galeria de projetos + upload de imagem
│   ├── experiencia.html    # Timeline acadêmica/profissional
│   ├── contato.html        # Formulário funcional (API Gateway)
│   ├── 404.html            # Página de erro customizada
│   ├── css/style.css       # Estilos responsivos (Grid + Flexbox)
│   └── js/main.js          # Lazy loading, formulário, upload
├── infrastructure/
│   ├── create-buckets.sh   # Cria e configura buckets S3
│   ├── setup-cloudfront.sh # Cria distribuição CloudFront
│   ├── configure-policies.sh # Bucket policies + security headers
│   └── cleanup.sh          # Remove todos os recursos AWS
├── lambda/
│   ├── image-processor/index.py  # Resize + WebP via S3 trigger
│   └── contact-form/index.py     # Validação + DynamoDB + SES
└── docs/
    ├── architecture-diagram.md   # Diagrama ASCII da arquitetura
    ├── performance-report.md     # Métricas e comparações
    ├── security-analysis.md      # Políticas e headers de segurança
    └── cost-analysis.md          # Breakdown de custos
```

## Como Executar

### Pré-requisitos

```bash
# AWS CLI instalado e configurado
aws --version
aws configure  # Access Key, Secret Key, region: us-east-1
```

### Deploy Passo a Passo

```bash
cd TF11-LuizFelipeSouza/infrastructure/

# 1. Criar e configurar buckets S3
export RA=6324548
bash create-buckets.sh

# 2. Configurar políticas de acesso
bash configure-policies.sh

# 3. Criar distribuição CloudFront (~15 min para propagar)
bash setup-cloudfront.sh
# Anote o CF_DISTRIBUTION_ID e CF_DOMAIN exibidos

# 4. Re-executar políticas com o CloudFront ID
CF_DISTRIBUTION_ID=<id_do_passo_3> bash configure-policies.sh

# 5. Acessar o site
# https://<CF_DOMAIN>
```

### Deploy das Lambda Functions

```bash
# image-processor
cd lambda/image-processor/
zip -r function.zip index.py

aws lambda create-function \
  --function-name portfolio-image-processor-6324548 \
  --runtime python3.12 \
  --handler index.lambda_handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<ACCOUNT_ID>:role/lambda-s3-role \
  --timeout 30 \
  --memory-size 512

# contact-form
cd ../contact-form/
zip -r function.zip index.py

aws lambda create-function \
  --function-name portfolio-contact-form-6324548 \
  --runtime python3.12 \
  --handler index.lambda_handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<ACCOUNT_ID>:role/lambda-dynamo-ses-role \
  --timeout 10 \
  --environment "Variables={DYNAMO_TABLE=portfolio-contacts,FROM_EMAIL=luizfelipe.souza@althaia.com.br,TO_EMAIL=luizfelipe.souza@althaia.com.br}"
```

### Limpeza (após avaliação)

**Warning:** Esta ação remove TODOS os recursos e é irreversível.

```bash
CF_DISTRIBUTION_ID=<id> bash cleanup.sh
```

## Performance

Ver relatório completo: [docs/performance-report.md](docs/performance-report.md)

| Métrica | Sem CDN | Com CloudFront |
|---------|---------|----------------|
| TTFB | ~200ms | ~20ms |
| PageSpeed | ~80 | >90 |
| HTTPS | ❌ | ✅ |
| Compressão | ❌ | ✅ Gzip |

## Segurança

Ver análise completa: [docs/security-analysis.md](docs/security-analysis.md)

- HTTPS obrigatório em todas as páginas (CloudFront)
- Bucket S3 sem acesso público (acesso apenas via OAC)
- Security Headers: HSTS, X-Frame-Options, X-Content-Type-Options
- IAM com princípio do menor privilégio
- Validação de entrada em dois níveis (frontend + Lambda)

## Custos

Ver análise completa: [docs/cost-analysis.md](docs/cost-analysis.md)

- Estimativa: **~$0,00 no Free Tier** / **~$2/mês** após Free Tier
- Billing Alert configurado em $10
- Lifecycle policies para redução de custos de storage

## Funcionalidades

- **4 páginas** responsivas (mobile-first)
- **Formulário de contato** integrado com API Gateway + Lambda + DynamoDB + SES
- **Upload de imagens** com processamento automático para WebP
- **Galeria de projetos** com 6 projetos documentados
- **Timeline** de experiência acadêmica e profissional
- **Página 404** customizada configurada no CloudFront
- **Modo escuro** por padrão (design moderno)
