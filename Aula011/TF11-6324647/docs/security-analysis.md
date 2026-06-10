# Security Analysis

## Modelo de Ameaças

| Ameaça | Mitigação |
|---|---|
| Acesso direto ao S3 | OAC (Origin Access Control) — S3 só aceita requisições do CloudFront |
| HTTP em texto claro | CloudFront: `ViewerProtocolPolicy: redirect-to-https` |
| Hotlinking de assets | Referer policy + bucket policy restrita |
| Upload de arquivos maliciosos | Lambda valida `Content-Type` e tamanho antes de aceitar |
| Injeção via formulário | Sanitização no Lambda; dados armazenados como texto sem execução |
| Exposição de credenciais | Sem credenciais no código; Lambda usa IAM Role |

## Configuração dos Buckets

### Bloqueio de Acesso Público
```json
{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}
```
Nenhum arquivo é acessível diretamente via URL do S3.

### Bucket Policy (Princípio do menor privilégio)
```json
{
  "Effect": "Allow",
  "Principal": { "Service": "cloudfront.amazonaws.com" },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::portfolio-gabriel-santiago-www/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::<account>:distribution/<id>"
    }
  }
}
```
Apenas a distribuição CloudFront específica pode ler os objetos.

## Headers de Segurança (CloudFront Response Headers Policy)

| Header | Valor | Proteção |
|---|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Força HTTPS por 1 ano |
| `X-Content-Type-Options` | `nosniff` | Previne MIME sniffing |
| `X-Frame-Options` | `DENY` | Previne clickjacking |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Controla vazamento de URL |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Desabilita APIs desnecessárias |

## Segurança dos Lambdas

### IAM Role (contact-form)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:<account>:table/portfolio-contacts"
    },
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail"],
      "Resource": "*",
      "Condition": {
        "StringEquals": { "ses:FromAddress": "noreply@seudominio.com" }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

### IAM Role (image-processor)
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::portfolio-gabriel-santiago-assets/*"
}
```

## Versionamento e Backup

- Versionamento habilitado em ambos os buckets
- Lifecycle policy: versões não-correntes expiram em 30 dias
- Em caso de exclusão acidental: restaurar versão anterior via `aws s3api list-object-versions`

## Checklist de Conformidade

- [x] Sem credenciais hardcoded no código
- [x] HTTPS em todas as páginas
- [x] Acesso S3 restrito ao CloudFront
- [x] Bucket público bloqueado
- [x] Validação de input no Lambda
- [x] Logs de acesso habilitados
- [x] Versionamento habilitado
- [x] IAM com menor privilégio
