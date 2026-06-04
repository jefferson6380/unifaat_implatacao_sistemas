# Lab011-Troubleshooting - Solução de Problemas S3 e CloudFront

## Problemas Comuns e Soluções

### 1. Problemas de Configuração do S3

#### Problema: Website não carrega (403 Forbidden)
**Sintomas:**
- Erro 403 ao acessar o website
- Mensagem "Access Denied"

**Diagnóstico:**
```bash
# Verificar configuração de website
aws s3api get-bucket-website --bucket BUCKET_NAME

# Verificar política do bucket
aws s3api get-bucket-policy --bucket BUCKET_NAME

# Verificar block public access
aws s3api get-public-access-block --bucket BUCKET_NAME
```

**Soluções:**
1. **Verificar static website hosting:**
   ```bash
   aws s3 website s3://BUCKET_NAME --index-document index.html --error-document error.html
   ```

2. **Configurar política pública:**
   ```bash
   cat > bucket-policy.json << EOF
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::BUCKET_NAME/*"
       }
     ]
   }
   EOF
   
   aws s3api put-bucket-policy --bucket BUCKET_NAME --policy file://bucket-policy.json
   ```

3. **Desabilitar block public access:**
   ```bash
   aws s3api put-public-access-block \
       --bucket BUCKET_NAME \
       --public-access-block-configuration \
       "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
   ```

#### Problema: Página de erro não funciona
**Sintomas:**
- Erro XML genérico em vez da página customizada
- 404 não redireciona para error.html

**Solução:**
```bash
# Verificar se error.html existe
aws s3 ls s3://BUCKET_NAME/error.html

# Reconfigurar website com error document
aws s3 website s3://BUCKET_NAME --index-document index.html --error-document error.html

# Testar página de erro
curl -I http://BUCKET_NAME.s3-website-us-east-1.amazonaws.com/pagina-inexistente
```

#### Problema: Upload de arquivos falha
**Sintomas:**
- Erro de permissão ao fazer upload
- "Access Denied" no upload

**Diagnóstico:**
```bash
# Verificar ACL do bucket
aws s3api get-bucket-acl --bucket BUCKET_NAME

# Testar upload via CLI
echo "teste" > test.txt
aws s3 cp test.txt s3://BUCKET_NAME/test.txt
```

**Soluções:**
1. **Verificar permissões IAM:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:PutObject",
           "s3:PutObjectAcl"
         ],
         "Resource": "arn:aws:s3:::BUCKET_NAME/*"
       }
     ]
   }
   ```

2. **Configurar CORS (se upload via browser):**
   ```bash
   cat > cors-config.json << EOF
   {
     "CORSRules": [
       {
         "AllowedHeaders": ["*"],
         "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
         "AllowedOrigins": ["*"],
         "MaxAgeSeconds": 3000
       }
     ]
   }
   EOF
   
   aws s3api put-bucket-cors --bucket BUCKET_NAME --cors-configuration file://cors-config.json
   ```

### 2. Problemas do CloudFront

#### Problema: CloudFront não serve conteúdo atualizado
**Sintomas:**
- Mudanças no S3 não aparecem no CloudFront
- Cache antigo sendo servido

**Diagnóstico:**
```bash
# Verificar configuração de cache
aws cloudfront get-distribution --id DISTRIBUTION_ID \
    --query 'Distribution.DistributionConfig.DefaultCacheBehavior'

# Verificar última modificação
aws cloudfront get-distribution --id DISTRIBUTION_ID \
    --query 'Distribution.LastModifiedTime'
```

**Soluções:**
1. **Invalidar cache:**
   ```bash
   aws cloudfront create-invalidation \
       --distribution-id DISTRIBUTION_ID \
       --paths "/*"
   ```

2. **Verificar TTL settings:**
   ```bash
   # Configurar TTL menor para desenvolvimento
   aws cloudfront get-distribution-config --id DISTRIBUTION_ID > temp-config.json
   # Editar DefaultTTL para valor menor (ex: 300 segundos)
   # Aplicar configuração atualizada
   ```

#### Problema: HTTPS não funciona
**Sintomas:**
- Certificado SSL inválido
- Erro de segurança no browser

**Diagnóstico:**
```bash
# Verificar configuração SSL
aws cloudfront get-distribution --id DISTRIBUTION_ID \
    --query 'Distribution.DistributionConfig.ViewerCertificate'

# Testar HTTPS
curl -I https://CLOUDFRONT_DOMAIN
```

**Soluções:**
1. **Verificar configuração de protocolo:**
   ```bash
   # Deve estar configurado como "redirect-to-https"
   aws cloudfront get-distribution --id DISTRIBUTION_ID \
       --query 'Distribution.DistributionConfig.DefaultCacheBehavior.ViewerProtocolPolicy'
   ```

2. **Aguardar propagação:**
   - CloudFront pode demorar até 24 horas para propagar mudanças
   - Verificar status: `aws cloudfront get-distribution --id DISTRIBUTION_ID --query 'Distribution.Status'`

#### Problema: CloudFront retorna erro 502/504
**Sintomas:**
- Bad Gateway ou Gateway Timeout
- Erro intermitente

**Diagnóstico:**
```bash
# Verificar origem
aws cloudfront get-distribution --id DISTRIBUTION_ID \
    --query 'Distribution.DistributionConfig.Origins'

# Testar origem diretamente
curl -I http://BUCKET_NAME.s3-website-us-east-1.amazonaws.com
```

**Soluções:**
1. **Verificar configuração da origem:**
   - Usar endpoint de website (s3-website-region.amazonaws.com)
   - Não usar endpoint de API (s3.region.amazonaws.com)

2. **Verificar custom origin config:**
   ```json
   {
     "HTTPPort": 80,
     "HTTPSPort": 443,
     "OriginProtocolPolicy": "http-only"
   }
   ```

### 3. Problemas de Performance

#### Problema: Site carrega lentamente
**Sintomas:**
- PageSpeed Score baixo
- Tempo de carregamento alto

**Diagnóstico:**
```bash
# Testar velocidade
time curl -s https://CLOUDFRONT_DOMAIN > /dev/null

# Verificar tamanho dos arquivos
aws s3 ls s3://BUCKET_NAME --recursive --human-readable
```

**Soluções:**
1. **Otimizar imagens:**
   ```bash
   # Converter para WebP
   cwebp input.jpg -q 80 -o output.webp
   
   # Redimensionar
   convert input.jpg -resize 800x600 output.jpg
   ```

2. **Minificar CSS/JS:**
   ```bash
   # CSS
   cleancss -o style.min.css style.css
   
   # JavaScript
   uglifyjs script.js -o script.min.js
   ```

3. **Habilitar compressão no CloudFront:**
   ```bash
   # Verificar se compressão está habilitada
   aws cloudfront get-distribution --id DISTRIBUTION_ID \
       --query 'Distribution.DistributionConfig.DefaultCacheBehavior.Compress'
   ```

#### Problema: Cache hit ratio baixo
**Sintomas:**
- Muitas requisições chegando ao S3
- Custos altos de transferência

**Diagnóstico:**
```bash
# Verificar métricas do CloudFront
aws cloudwatch get-metric-statistics \
    --namespace AWS/CloudFront \
    --metric-name CacheHitRate \
    --dimensions Name=DistributionId,Value=DISTRIBUTION_ID \
    --statistics Average \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 3600
```

**Soluções:**
1. **Configurar headers de cache:**
   ```html
   <!-- Adicionar meta tags -->
   <meta http-equiv="Cache-Control" content="public, max-age=31536000">
   ```

2. **Configurar TTL adequado:**
   - Arquivos estáticos: TTL alto (1 ano)
   - HTML: TTL baixo (1 hora)
   - API responses: TTL muito baixo (5 minutos)

### 4. Problemas de Segurança

#### Problema: Bucket exposto publicamente
**Sintomas:**
- Aviso de segurança no console AWS
- Arquivos acessíveis sem permissão

**Diagnóstico:**
```bash
# Verificar configuração de acesso público
aws s3api get-public-access-block --bucket BUCKET_NAME

# Verificar política do bucket
aws s3api get-bucket-policy --bucket BUCKET_NAME
```

**Soluções:**
1. **Restringir acesso apenas ao necessário:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "PublicReadGetObject",
         "Effect": "Allow",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::BUCKET_NAME/public/*"
       }
     ]
   }
   ```

2. **Usar CloudFront Origin Access Identity:**
   ```bash
   # Criar OAI
   aws cloudfront create-cloud-front-origin-access-identity \
       --cloud-front-origin-access-identity-config \
       CallerReference=$(date +%s),Comment="OAI for BUCKET_NAME"
   ```

#### Problema: Headers de segurança ausentes
**Sintomas:**
- Falhas em testes de segurança
- Vulnerabilidades reportadas

**Solução:**
```javascript
// Adicionar via Lambda@Edge ou no HTML
<meta http-equiv="Content-Security-Policy" content="default-src 'self'">
<meta http-equiv="X-Frame-Options" content="DENY">
<meta http-equiv="X-Content-Type-Options" content="nosniff">
<meta http-equiv="Referrer-Policy" content="strict-origin-when-cross-origin">
```

### 5. Problemas de Custos

#### Problema: Custos inesperados
**Sintomas:**
- Conta AWS maior que esperado
- Uso além do Free Tier

**Diagnóstico:**
```bash
# Verificar uso do S3
aws s3api list-objects-v2 --bucket BUCKET_NAME --query 'length(Contents)'

# Verificar métricas de transferência
aws cloudwatch get-metric-statistics \
    --namespace AWS/S3 \
    --metric-name BucketSizeBytes \
    --dimensions Name=BucketName,Value=BUCKET_NAME Name=StorageType,Value=StandardStorage \
    --statistics Average \
    --start-time $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 86400
```

**Soluções:**
1. **Configurar lifecycle policies:**
   ```json
   {
     "Rules": [
       {
         "ID": "DeleteOldVersions",
         "Status": "Enabled",
         "NoncurrentVersionExpiration": {
           "NoncurrentDays": 30
         }
       }
     ]
   }
   ```

2. **Limpar arquivos desnecessários:**
   ```bash
   # Listar arquivos grandes
   aws s3 ls s3://BUCKET_NAME --recursive --human-readable | sort -k1 -hr
   
   # Deletar arquivos antigos
   aws s3 rm s3://BUCKET_NAME/old-folder/ --recursive
   ```

3. **Configurar alertas de billing:**
   ```bash
   aws budgets create-budget \
       --account-id ACCOUNT_ID \
       --budget file://budget-config.json
   ```

## Scripts de Diagnóstico

### Script de Verificação Completa
```bash
#!/bin/bash
# s3-health-check.sh

BUCKET_NAME=$1
DISTRIBUTION_ID=$2

if [ -z "$BUCKET_NAME" ]; then
    echo "Uso: $0 <bucket-name> [distribution-id]"
    exit 1
fi

echo "=== S3 Health Check ==="
echo "Bucket: $BUCKET_NAME"

# Verificar se bucket existe
if aws s3 ls s3://$BUCKET_NAME > /dev/null 2>&1; then
    echo "✅ Bucket existe"
else
    echo "❌ Bucket não encontrado"
    exit 1
fi

# Verificar website hosting
if aws s3api get-bucket-website --bucket $BUCKET_NAME > /dev/null 2>&1; then
    echo "✅ Static website hosting habilitado"
else
    echo "❌ Static website hosting não configurado"
fi

# Verificar política pública
if aws s3api get-bucket-policy --bucket $BUCKET_NAME > /dev/null 2>&1; then
    echo "✅ Política do bucket configurada"
else
    echo "⚠️ Política do bucket não encontrada"
fi

# Verificar index.html
if aws s3 ls s3://$BUCKET_NAME/index.html > /dev/null 2>&1; then
    echo "✅ index.html encontrado"
else
    echo "❌ index.html não encontrado"
fi

# Testar acesso web
WEBSITE_URL="http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
if curl -s -I $WEBSITE_URL | grep -q "200 OK"; then
    echo "✅ Website acessível"
else
    echo "❌ Website não acessível"
fi

# Verificar CloudFront se fornecido
if [ ! -z "$DISTRIBUTION_ID" ]; then
    echo ""
    echo "=== CloudFront Health Check ==="
    
    STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
    echo "Status: $STATUS"
    
    if [ "$STATUS" = "Deployed" ]; then
        echo "✅ Distribuição ativa"
        
        DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
        echo "Domínio: $DOMAIN"
        
        if curl -s -I https://$DOMAIN | grep -q "200 OK"; then
            echo "✅ CloudFront acessível"
        else
            echo "❌ CloudFront não acessível"
        fi
    else
        echo "⚠️ Distribuição ainda não está ativa"
    fi
fi

echo ""
echo "=== Verificação concluída ==="
```

### Script de Limpeza de Emergência
```bash
#!/bin/bash
# emergency-cleanup.sh

BUCKET_NAME=$1

if [ -z "$BUCKET_NAME" ]; then
    echo "Uso: $0 <bucket-name>"
    exit 1
fi

echo "⚠️ ATENÇÃO: Este script irá deletar TODOS os arquivos do bucket $BUCKET_NAME"
read -p "Tem certeza? (digite 'yes' para confirmar): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operação cancelada"
    exit 0
fi

echo "Esvaziando bucket..."
aws s3 rm s3://$BUCKET_NAME --recursive

echo "Removendo versionamento..."
aws s3api list-object-versions --bucket $BUCKET_NAME --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while read key version; do
    aws s3api delete-object --bucket $BUCKET_NAME --key "$key" --version-id "$version"
done

echo "Deletando bucket..."
aws s3 rb s3://$BUCKET_NAME

echo "✅ Limpeza concluída"
```

## Recursos Úteis

### Comandos de Diagnóstico Rápido
```bash
# Verificar configuração completa do bucket
aws s3api get-bucket-location --bucket BUCKET_NAME
aws s3api get-bucket-versioning --bucket BUCKET_NAME
aws s3api get-bucket-lifecycle-configuration --bucket BUCKET_NAME

# Verificar métricas do CloudFront
aws cloudwatch list-metrics --namespace AWS/CloudFront

# Testar performance
curl -w "@curl-format.txt" -o /dev/null -s https://DOMAIN
```

### Arquivo curl-format.txt
```
     time_namelookup:  %{time_namelookup}\n
        time_connect:  %{time_connect}\n
     time_appconnect:  %{time_appconnect}\n
    time_pretransfer:  %{time_pretransfer}\n
       time_redirect:  %{time_redirect}\n
  time_starttransfer:  %{time_starttransfer}\n
                     ----------\n
          time_total:  %{time_total}\n
```

### Links de Referência
- [S3 Error Codes](https://docs.aws.amazon.com/AmazonS3/latest/API/ErrorResponses.html)
- [CloudFront Error Codes](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/troubleshooting-response-errors.html)
- [S3 Performance Guidelines](https://docs.aws.amazon.com/AmazonS3/latest/userguide/optimizing-performance.html)
- [CloudFront Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/best-practices.html)