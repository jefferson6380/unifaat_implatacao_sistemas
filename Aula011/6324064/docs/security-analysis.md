# Security Analysis - TF11

## Escopo
Analise das camadas de seguranca aplicadas ao portfolio S3 + CloudFront.

## Controles aplicados
1. HTTPS forcado no CloudFront
- ViewerProtocolPolicy = redirect-to-https
- Evita trafego HTTP em acesso publico

2. Bucket policies e isolamento de dados
- Website bucket com leitura publica apenas em objetos
- Assets bucket com bloqueio publico habilitado

3. Criptografia em repouso
- SSE-S3 (AES256) em website e assets

4. CORS controlado
- CORS aplicado no bucket de assets
- Metodos permitidos: GET, PUT e POST

5. Logs e monitoramento
- Logs S3 habilitados para website e assets
- Logging CloudFront habilitado em bucket dedicado
- Alarmes CloudWatch para billing, 4xx e cache hit rate

## Recomendações adicionais
- Trocar endpoint de website S3 por REST endpoint com OAC em producao
- Aplicar WAF no CloudFront
- Ativar CloudTrail data events para buckets criticos
- Integrar alarmes com SNS para notificacao ativa

## Headers de seguranca
Foi selecionada a managed response headers policy do CloudFront (`SecurityHeadersPolicy`).
Headers esperados:
- Strict-Transport-Security
- X-Content-Type-Options
- X-Frame-Options
- Referrer-Policy

## Checklist de validacao
- [x] Confirmar HTTPS em todas as rotas
- [x] Confirmar bloqueio publico no bucket de assets
- [x] Habilitar logs de acesso S3 e CloudFront
- [x] Criar alarmes e dashboard no CloudWatch
- [ ] Restringir CORS para dominio definitivo (quando houver dominio proprio)
- [ ] Revisar IAM final das Lambdas apos desbloqueio de iam:PassRole
