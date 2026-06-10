# Security Analysis – TF11

**Aluno:** Bruno Pereira dos Santos – RA 6324550

---

## 1. Políticas de Bucket S3

### Bucket Principal (Website)
- Acesso público de leitura habilitado apenas para `s3:GetObject`
- Block Public ACLs: desabilitado (necessário para static website)
- Versionamento: **habilitado** (permite rollback)
- Lifecycle policy: versões antigas deletadas após 30 dias

### Bucket de Assets
- CORS configurado apenas para métodos necessários (GET, PUT, POST)
- Upload via URLs pré-assinadas (nunca expõe credenciais ao cliente)
- Logs de acesso salvos em prefixo separado

---

## 2. HTTPS e Transporte

- CloudFront configurado com `ViewerProtocolPolicy: redirect-to-https`
- Qualquer acesso HTTP é redirecionado automaticamente para HTTPS
- TLS 1.2+ garantido pelo CloudFront
- HTTP/2 e HTTP/3 habilitados (melhor performance e segurança)

---

## 3. Headers de Segurança

Implementar via CloudFront Response Headers Policy:

```
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Referrer-Policy: strict-origin-when-cross-origin
Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'
```

---

## 4. Lambda e API Gateway

- Sanitização de inputs em todas as Lambdas (remoção de `<>`)
- Validação de tipos e tamanhos antes do processamento
- Variáveis sensíveis via AWS Secrets Manager / Environment Variables
- Erros genéricos retornados ao cliente (sem stack trace exposto)
- Timeout configurado (máx. 10s por execução)

### IAM Roles (Menor Privilégio)

| Lambda | Permissões |
|--------|-----------|
| image-processor | `s3:PutObject` no bucket de assets apenas |
| contact-form | `dynamodb:PutItem` na tabela específica + `ses:SendEmail` |

---

## 5. DynamoDB

- Tabela com chave de partição `id` (UUID v4 gerado no servidor)
- Campos sanitizados antes de inserção
- Acesso restrito apenas à Lambda com role específica
- Sem exposição de dados ao cliente além do ID de confirmação

---

## 6. Vulnerabilidades Identificadas e Mitigadas

| Vulnerabilidade | Mitigação |
|----------------|-----------|
| Bucket público exposto | Bucket policy com acesso mínimo necessário |
| Injeção de dados no DynamoDB | Sanitização e validação de inputs |
| Upload de arquivos maliciosos | Validação de MIME type e tamanho |
| Exposição de credenciais | URLs pré-assinadas com TTL de 5 min |
| Clickjacking | Header X-Frame-Options: DENY |
| XSS | CSP + sanitização de dados de exibição |

---

## 7. Compliance com Boas Práticas AWS

- [x] Princípio do menor privilégio nas IAM roles
- [x] Criptografia em trânsito (HTTPS obrigatório)
- [x] Logging habilitado (S3 access logs)
- [x] Billing alerts configurados
- [x] Versionamento de buckets habilitado
- [x] Sem credenciais hardcoded no código
- [ ] Criptografia em repouso no S3 (SSE-S3) – recomendado para assets
- [ ] WAF na distribuição CloudFront – recomendado para produção
