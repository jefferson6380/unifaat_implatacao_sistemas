# Análise de Segurança — TF11

**Aluno:** Natan Borges Leme  
**RA:** 6324696  
**Disciplina:** Implementação de Sistemas — UniFAAT

---

## 1. Políticas de Bucket S3

### 1.1 Website Bucket
- **Acesso público de leitura** habilitado apenas para `s3:GetObject`
- Nenhuma operação de escrita (`s3:PutObject`, `s3:DeleteObject`) é permitida publicamente
- Todas as ações de escrita exigem autenticação IAM com permissões explícitas

### 1.2 Assets Bucket
- **Completamente privado** — Block Public Access = true em todos os quatro controles
- Acesso exclusivo via IAM Roles atribuídas às Lambdas
- URLs pré-assinadas com validade de 5 minutos para uploads do frontend

### 1.3 Princípio do Menor Privilégio (IAM)

| Role              | Permissões                                  |
|-------------------|---------------------------------------------|
| Lambda-ContactForm | `dynamodb:PutItem`, `ses:SendEmail`         |
| Lambda-ImageProc   | `s3:GetObject` (source), `s3:PutObject` (dest) |
| Deploy (CI/CD)     | `s3:PutObject`, `s3:DeleteObject` (website bucket apenas) |

---

## 2. HTTPS e Criptografia

- **HTTPS obrigatório** em todas as páginas — CloudFront redireciona HTTP → HTTPS
- Protocolo mínimo: **TLSv1.2_2021** (elimina TLS 1.0 e 1.1 vulneráveis)
- Certificado SSL/TLS gerenciado pelo CloudFront (AWS Certificate Manager)
- **HSTS** habilitado via Response Headers Policy:
  ```
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  ```

---

## 3. Security Headers (CloudFront Response Headers Policy)

| Header                          | Valor                                      | Proteção                        |
|---------------------------------|--------------------------------------------|---------------------------------|
| `Strict-Transport-Security`     | `max-age=63072000; includeSubDomains`      | Força HTTPS (HSTS)              |
| `X-Content-Type-Options`        | `nosniff`                                  | Previne MIME sniffing           |
| `X-Frame-Options`               | `DENY`                                     | Previne Clickjacking            |
| `X-XSS-Protection`              | `1; mode=block`                            | XSS (legado)                    |
| `Referrer-Policy`               | `strict-origin-when-cross-origin`          | Controla referrer header        |
| `Permissions-Policy`            | `camera=(), microphone=(), geolocation=()` | Restringe APIs do browser       |
| `Content-Security-Policy`       | Ver abaixo                                 | Previne XSS e injeção de código |

### Content-Security-Policy (CSP)

```
default-src 'self';
script-src 'self' 'nonce-{random}';
style-src 'self' https://fonts.googleapis.com;
font-src 'self' https://fonts.gstatic.com;
img-src 'self' data: https:;
connect-src 'self' https://REPLACE_API_GATEWAY_URL;
frame-ancestors 'none';
base-uri 'self';
form-action 'self';
```

---

## 4. Proteção Contra Ataques

### 4.1 Anti-Hotlinking
- Configurado via **Referer Condition** no CloudFront (restringe domínio de origem)
- Imagens de assets servidas apenas quando `Referer` bate com o domínio do portfólio

### 4.2 Anti-Spam no Formulário
- **Honeypot field** (`<input name="website" hidden>`): bots preenchem, humanos não
- Validação server-side no Lambda (nome, e-mail, tamanho da mensagem)
- Rate limiting via **API Gateway Usage Plan** (máx. 10 req/min por IP)

### 4.3 Upload de Arquivos
- Tipos MIME verificados no Lambda (`image/jpeg`, `image/png`, `image/webp`)
- Tamanho máximo de 5MB por arquivo
- URL pré-assinada com expiração de 5 minutos (evita abuse)
- Arquivos processados pelo Lambda antes de serem servidos publicamente

### 4.4 Injeção e XSS
- Sem uso de `innerHTML` no JavaScript do frontend
- `textContent` usado para toda inserção de conteúdo dinâmico
- Dados do formulário sanitizados no Lambda antes de persistir

---

## 5. Vulnerabilidades Identificadas e Mitigadas

| Vulnerabilidade         | Risco   | Mitigação                                        |
|------------------------|---------|--------------------------------------------------|
| OWASP A01 - Broken Access Control | Alto | IAM com menor privilégio, bucket privado      |
| OWASP A02 - Crypto Failures       | Alto | TLS 1.2+, HSTS, sem dados sensíveis em client |
| OWASP A03 - Injection             | Médio  | Validação server-side, sem SQL direto         |
| OWASP A05 - Misconfig             | Alto   | Bucket policies restritivas, headers de seg.  |
| OWASP A07 - Auth Failures         | Baixo  | Sem auth em páginas estáticas (read-only)     |
| OWASP A10 - SSRF                  | Baixo  | Lambda não faz fetch de URLs externas         |

---

## 6. Monitoramento de Segurança

- **CloudTrail** habilitado — logs de todas as chamadas de API AWS
- **CloudWatch Alarms** configurados para:
  - Erros 4xx/5xx acima de threshold
  - Tentativas de acesso negadas (Access Denied no S3)
  - Custo acima de $5/dia (possível ataque de custo)
- **S3 Access Logs** habilitados para auditoria de acessos ao bucket

---

## 7. Compliance com Boas Práticas AWS

- ✅ Nenhuma credencial AWS hardcoded no código
- ✅ Secrets gerenciados via variáveis de ambiente Lambda
- ✅ MFA habilitado na conta raiz da AWS
- ✅ Billing Alerts configurados ($5 e $10)
- ✅ Bucket versionamento habilitado para recuperação de dados
