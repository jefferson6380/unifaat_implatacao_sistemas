# Troubleshooting Lab 8 - S3 e CloudFront

**Lab:** 008 - S3 e CloudFront  
**Foco:** Armazenamento, CDN, hospedagem estática

---

## 🚨 Problemas Mais Comuns

### 1. Bucket S3 não Acessível

#### **Sintoma:**
- "Access Denied" ao acessar bucket
- "NoSuchBucket" error

#### **Diagnóstico:**
```bash
# Verifica se bucket existe
aws s3 ls s3://meu-bucket

# Verifica região do bucket
aws s3api get-bucket-location --bucket meu-bucket
```

#### **Soluções:**
```bash
# Corrige região
aws s3 ls s3://meu-bucket --region us-east-1

# Verifica permissões do bucket
aws s3api get-bucket-policy --bucket meu-bucket
```

### 2. Website Estático não Funciona

#### **Sintoma:**
- "404 Not Found" ao acessar site
- Página não carrega

#### **Soluções:**
```bash
# Habilita website hosting
aws s3 website s3://meu-bucket --index-document index.html --error-document error.html

# Verifica configuração
aws s3api get-bucket-website --bucket meu-bucket

# Torna bucket público
aws s3api put-bucket-policy --bucket meu-bucket --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::meu-bucket/*"
  }]
}'
```

### 3. CloudFront não Atualiza

#### **Sintoma:**
- Mudanças no S3 não aparecem no CloudFront
- Cache desatualizado

#### **Soluções:**
```bash
# Cria invalidação
aws cloudfront create-invalidation \
  --distribution-id E1234567890ABC \
  --paths "/*"

# Verifica status da invalidação
aws cloudfront list-invalidations --distribution-id E1234567890ABC
```

### 4. Erro de CORS

#### **Sintoma:**
- "CORS policy" error no navegador
- API calls falham

#### **Soluções:**
```bash
# Configura CORS no bucket
aws s3api put-bucket-cors --bucket meu-bucket --cors-configuration '{
  "CORSRules": [{
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "POST", "PUT", "DELETE"],
    "AllowedOrigins": ["*"],
    "MaxAgeSeconds": 3000
  }]
}'
```

### 5. Upload Falha

#### **Sintoma:**
- "Access Denied" no upload
- Arquivo não aparece no bucket

#### **Soluções:**
```bash
# Verifica permissões
aws s3api head-object --bucket meu-bucket --key arquivo.txt

# Upload com permissões corretas
aws s3 cp arquivo.txt s3://meu-bucket/ --acl public-read

# Verifica tamanho do arquivo (limite 5GB para single upload)
ls -lh arquivo.txt
```

---

**Desenvolvido por:** Professor Alexandre Tavares - UniFAAT