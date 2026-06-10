# Performance Report

## Métricas Alvo vs Obtidas

| Métrica | Meta | S3 Direto | CloudFront |
|---|---|---|---|
| PageSpeed (mobile) | ≥ 90 | ~75 | ≥ 90 |
| PageSpeed (desktop) | ≥ 95 | ~85 | ≥ 95 |
| TTFB | < 200ms | ~450ms | < 80ms |
| LCP | < 2.5s | ~3.2s | < 1.5s |
| Cache Hit Rate | > 85% | — | > 90% |
| GTmetrix Grade | A | B | A |

> Preencher com valores reais após o deploy.

## Otimizações Implementadas

### Imagens
- Formato WebP para imagens do portfólio (redução ~30% vs JPEG)
- Atributo `loading="lazy"` em todas as imagens abaixo da dobra
- Redimensionamento automático via Lambda (evita servir imagens maiores que o necessário)

### CSS/JS
- Arquivo CSS único sem dependências externas (sem CDN de terceiros)
- JavaScript com `defer` (não bloqueia renderização)
- Sem frameworks pesados — vanilla JS puro (~5KB total)

### Cache Policies (CloudFront)

| Tipo de conteúdo | Cache-Control | CloudFront TTL |
|---|---|---|
| HTML | `no-cache` | 0s (sempre busca no S3) |
| CSS / JS | `max-age=31536000, immutable` | 1 ano |
| Imagens | `max-age=604800` | 7 dias |
| Documentos | `max-age=86400` | 1 dia |

### Compressão
- Gzip/Brotli habilitado no CloudFront para todos os tipos de texto
- Redução estimada de ~70% no tamanho de HTML/CSS/JS transferidos

## Comparação S3 Direto vs CloudFront

```
Sem CloudFront (S3 us-east-1):
  Usuário SP → S3 Virginia: ~180ms TTFB
  Sem compressão automática
  HTTP apenas (ou HTTPS via website endpoint sem certificado próprio)

Com CloudFront:
  Usuário SP → PoP São Paulo: ~15ms TTFB
  Brotli/Gzip automático
  HTTPS com certificado ACM gerenciado
  HTTP/2 e HTTP/3 habilitados
```

## Como Medir

```bash
# PageSpeed Insights
https://pagespeed.web.dev/?url=https://<cloudfront-domain>

# GTmetrix
https://gtmetrix.com

# TTFB via curl
curl -s -o /dev/null -w "%{time_starttransfer}" https://<cloudfront-domain>

# Cache Hit via headers
curl -I https://<cloudfront-domain> | grep -i "x-cache"
# X-Cache: Hit from cloudfront  → acerto de cache
# X-Cache: Miss from cloudfront → miss (primeira requisição)
```

## Recomendações Futuras

- Implementar CDN para fontes (atualmente usa `system-ui` — zero latência de fonte)
- Avaliar Critical CSS inline para acelerar FCP
- Configurar CloudFront Functions para headers de segurança mais granulares
