# Análise de Segurança

## Resumo de Controles Implementados

| Controle | Status | Implementação |
|---------|--------|---------------|
| HTTPS obrigatório | ✅ | CloudFront redirect HTTP → HTTPS |
| Block Public Access | ✅ | S3 API: BlockPublicAcls + RestrictPublicBuckets |
| Origin Access Control | ✅ | CloudFront OAC (padrão atual, substitui OAI) |
| Security Headers | ✅ | CloudFront Response Headers Policy |
| Bucket Policy restritiva | ✅ | Allow apenas CloudFront Service Principal |
| CORS configurado | ✅ | Bucket de assets com CORS policy |
| Validação de entrada | ✅ | Frontend + Lambda (dupla validação) |
| Versionamento | ✅ | S3 versioning em ambos os buckets |
| Logs de acesso | ✅ | S3 access logs → bucket de logs |
| IAM mínimo privilégio | ✅ | Lambda roles específicas por função |
| TLS 1.2+ | ✅ | CloudFront Security Policy: TLSv1.2_2021 |

## Headers de Segurança (CloudFront Response Headers Policy)

### Strict-Transport-Security (HSTS)
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```
Força HTTPS por 2 anos. Após esse período, browsers recusam conexão HTTP.

### X-Content-Type-Options
```
X-Content-Type-Options: nosniff
```
Impede MIME type sniffing — browser respeita apenas o Content-Type declarado.

### X-Frame-Options
```
X-Frame-Options: DENY
```
Impede que o site seja carregado em iframes — proteção contra clickjacking.

### X-XSS-Protection
```
X-XSS-Protection: 1; mode=block
```
Ativa filtro XSS legado em navegadores mais antigos.

### Referrer-Policy
```
Referrer-Policy: strict-origin-when-cross-origin
```
Limita informações de referência enviadas a domínios externos.

## Política do Bucket S3 (Website)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontServicePrincipal",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudfront.amazonaws.com"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::portfolio-website-6324548/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::<ACCOUNT_ID>:distribution/<CF_ID>"
        }
      }
    }
  ]
}
```

**Por que OAC em vez de OAI?**
- OAC (Origin Access Control) é o padrão atual da AWS desde 2022
- Suporta SSE-KMS para buckets criptografados
- Suporta todos os métodos HTTP (OAI só suportava GET)
- Condição `AWS:SourceArn` é mais restritiva que OAI

## IAM Roles das Lambda Functions

### image-processor
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::portfolio-assets-6324548/*"
    },
    {
      "Effect": "Allow",
      "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
```

### contact-form
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem"],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/portfolio-contacts"
    },
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail"],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "ses:FromAddress": "luizfelipe.souza@althaia.com.br"
        }
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

## Validação de Entrada (Defesa em Profundidade)

Validação ocorre em **dois níveis**:

1. **Frontend (JavaScript)**:
   - Campos obrigatórios presentes
   - Formato de email via regex
   - Tamanho mínimo da mensagem
   - Tipo de arquivo para upload (somente imagens)
   - Tamanho máximo 5MB para upload

2. **Backend (Lambda Python)**:
   - Mesmas validações (não confia no frontend)
   - Limite de tamanho dos campos (100/200/5000 chars)
   - Regex de email no servidor

## Vulnerabilidades Mitigadas

| Vulnerabilidade | Mitigação |
|----------------|-----------|
| Acesso direto ao S3 | Block Public Access + Bucket Policy OAC |
| Clickjacking | X-Frame-Options: DENY |
| MIME sniffing | X-Content-Type-Options: nosniff |
| Downgrade HTTPS | HSTS com preload |
| XSS refletido | Headers + validação de entrada |
| Injection em DynamoDB | Uso de SDK (parameterizado por padrão) |
| Upload de malware | Validação de content-type + extensão |
| Força bruta API | API Gateway throttling (100 req/s) |
| Hotlinking de assets | Bucket policy com condição de Referer |
| Exposição de erros | Lambda retorna mensagens genéricas |

## Observações Importantes

**SES Sandbox**: Por padrão, o SES está em modo sandbox. Para enviar emails:
1. Verificar o email de origem: `aws ses verify-email-identity --email-address luizfelipe.souza@althaia.com.br`
2. Verificar o email de destino (enquanto em sandbox)
3. Para produção: solicitar saída do sandbox via console AWS

**CloudTrail**: Para auditoria completa, habilitar AWS CloudTrail na conta para registrar todas as chamadas de API.
