# Análise de Segurança — TF11 Portfólio AWS

**Aluno:** Leonardo Frazão Sano  
**RA:** 6324073  
**Data:** 03/06/2026

---

## 1. Políticas de Bucket S3

### Bucket Website (`portfolio-lfs-website-6324073`)

**Política aplicada:** Leitura pública apenas para `s3:GetObject`

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::portfolio-lfs-website-6324073/*"
  }]
}
```

**Justificativa:** Website público — leitura necessária. Escrita e exclusão bloqueadas para todos os usuários externos.

### Bucket Assets (`portfolio-lfs-assets-6324073`)

- Leitura pública: apenas para arquivos já processados (`processed/*`)
- Escrita: somente via presigned URL gerada pela Lambda (autenticada)
- Escrita direta pelo público: **bloqueada**

---

## 2. Headers de Segurança (CloudFront Response Headers Policy)

| Header | Valor | Proteção |
|--------|-------|---------|
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Força HTTPS por 2 anos |
| `X-Content-Type-Options` | `nosniff` | Previne MIME sniffing |
| `X-Frame-Options` | `DENY` | Previne clickjacking |
| `X-XSS-Protection` | `1; mode=block` | Proteção XSS (legado) |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Controla Referer |
| `Content-Security-Policy` | Ver abaixo | Previne XSS/injeção |

### Content Security Policy

```
default-src 'self';
script-src 'self' 'unsafe-inline';
style-src 'self' 'unsafe-inline';
img-src 'self' data: https:;
connect-src 'self' https://*.execute-api.us-east-1.amazonaws.com;
font-src 'self';
```

---

## 3. HTTPS

- **CloudFront:** Certificado SSL/TLS gerenciado pela AWS (ACM)
- **Redirect HTTP → HTTPS:** Habilitado na distribuição CloudFront
- **Protocolo mínimo:** TLSv1.2_2021
- **S3 direto:** Bloqueado via CloudFront (acesso direto ao bucket endpoint não recomendado)

---

## 4. Princípio do Menor Privilégio

### IAM Role da Lambda

- Somente permissões necessárias: logs, S3 (bucket específico), DynamoDB (tabela específica), SES
- Sem `*` em recursos — todas as ARNs são específicas
- Sem permissões de IAM dentro das Lambdas

### Presigned URLs para Upload

- URLs de upload expiram em **15 minutos**
- Geradas pela Lambda apenas para tipos de arquivo permitidos (JPEG, PNG, WebP)
- Tamanho máximo validado no cliente (5MB) e pode ser restringido via `Content-Length-Range` na presigned URL

---

## 5. Validação de Entrada

### Formulário de Contato (Lambda)

| Campo     | Validação |
|-----------|-----------|
| Nome      | Mínimo 2 caracteres, strip |
| E-mail    | Regex RFC-5322 simplificado |
| Assunto   | Não vazio |
| Mensagem  | Mínimo 20 caracteres |
| HTML output | Escapeado (`escapeHtml`) antes de enviar via SES |

### Upload de Imagens

- Tipo MIME validado: `image/jpeg`, `image/png`, `image/webp`
- Tamanho máximo: 5MB (validado no cliente)
- Arquivos processados e renomeados pela Lambda (sem execução de código de arquivo)

---

## 6. Proteção contra Hotlinking

- Configurado via CloudFront: apenas requests com `Referer` do domínio do portfólio são aceitos para servir imagens de projetos
- Assets públicos (CSS, JS) sem restrição de Referer

---

## 7. Monitoramento de Segurança

- **CloudTrail:** Habilitado — todas as chamadas de API AWS são registradas
- **S3 Access Logs:** Logs de acesso ao bucket salvo em bucket separado com lifecycle de 90 dias
- **CloudWatch Alarms:** Alerta de billing se custos ultrapassarem $10/mês

---

## 8. Vulnerabilidades Identificadas e Mitigadas

| Risco | Mitigação |
|-------|-----------|
| XSS via formulário | Escapeamento HTML na Lambda antes de inserir no SES |
| Injeção em DynamoDB | AWS SDK usa atributos tipados (sem SQL injection possível em DynamoDB) |
| Upload de arquivos maliciosos | Validação de MIME type + processamento via Sharp (não executa arquivo) |
| Acesso não autorizado ao S3 | Bucket policy restritiva + IAM Role com menor privilégio |
| Exposição de credenciais | Variáveis de ambiente na Lambda (não hardcoded) |
| DDoS | CloudFront com WAF opcional disponível |

---

## 9. Compliance

- ✅ HTTPS em todas as páginas
- ✅ Headers de segurança configurados
- ✅ Princípio do menor privilégio
- ✅ Logs de acesso habilitados
- ✅ Versionamento habilitado (recuperação de dados)
- ✅ Sem credenciais hardcoded no código
