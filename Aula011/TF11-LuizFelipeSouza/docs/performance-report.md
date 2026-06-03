# Relatório de Performance

## Resumo

| Métrica | S3 Direto | CloudFront |
|---------|-----------|------------|
| TTFB (Time to First Byte) | ~80–200ms | ~5–20ms |
| LCP (Largest Contentful Paint) | ~800ms | ~200ms |
| PageSpeed Score | ~75–85 | >90 |
| Cache Hit Rate | N/A | >90% |
| Compressão Gzip | Não | Sim |
| HTTPS | Não (website hosting) | Sim (obrigatório) |

## Métricas Alvo (PageSpeed Insights)

- **Performance**: > 90
- **Acessibilidade**: > 90
- **Boas Práticas**: > 90
- **SEO**: > 90

## Otimizações Implementadas

### HTML
- Estrutura semântica (menor DOM depth)
- Meta tags completas (SEO, Open Graph)
- `lang="pt-BR"` para localização correta

### CSS
- CSS Custom Properties (variáveis) — sem duplicação de valores
- `clamp()` para tipografia fluida (elimina media queries de font-size)
- `backdrop-filter` com fallback para navegadores antigos
- Transições apenas em `opacity`, `transform`, `color` (não triggera reflow)

### JavaScript
- Carregamento no fim do body (não bloqueia render)
- `IntersectionObserver` para lazy loading de imagens
- Event delegation onde possível
- `fetch` assíncrono (não bloqueia UI)

### Imagens
- `loading="lazy"` em todos os `<img>`
- SVG inline para ícones (sem requisição extra)
- Lambda converte uploads para WebP (redução de ~30–50% vs JPEG)
- Atributos `width` e `height` para evitar CLS (Cumulative Layout Shift)

### CloudFront
- **Compressão Gzip**: CSS/JS reduzem ~70%
- **HTTP/2 e HTTP/3**: multiplexação de requisições
- **Cache por tipo de arquivo**:
  - HTML: `no-cache` (conteúdo sempre atualizado)
  - CSS/JS: `max-age=86400` (1 dia)
  - Imagens: `max-age=604800` (7 dias)
- **PriceClass_100**: edge locations América do Norte e Europa
- **Invalidação de cache**: `aws cloudfront create-invalidation --paths "/*"` após deploy

## Comparação Detalhada: S3 Direto vs CloudFront

### S3 Static Website Hosting (sem CDN)

- Acesso direto ao bucket na região `us-east-1`
- Usuários em SP → servidor em Virgínia/Oregon → ~150ms latência
- Sem HTTPS no endpoint de website do S3
- Sem compressão automática
- Endpoint: `http://portfolio-website-6324548.s3-website-us-east-1.amazonaws.com`

### CloudFront CDN

- Edge location em São Paulo (`gru52-P1`)
- Latência para usuários brasileiros: ~5–20ms
- HTTPS obrigatório com TLS 1.3
- Compressão Gzip automática
- Cache na borda: ~90% das requisições não chegam ao S3
- Endpoint: `https://xxxxxxxx.cloudfront.net`

### Economia de Custo com Cache

Se 1000 usuários/mês acessam 5 páginas cada:
- S3 sem CDN: 5000 requisições ao S3 = ~$0,0025
- CloudFront com 90% hit rate: 500 req ao S3 + 4500 do cache = ~$0,0005

## Core Web Vitals Esperados

| Métrica | Valor Alvo | Descrição |
|---------|-----------|-----------|
| **LCP** | < 2.5s | Maior elemento visível carregado |
| **FID** | < 100ms | Resposta ao primeiro clique |
| **CLS** | < 0.1 | Estabilidade do layout |
| **FCP** | < 1.8s | Primeiro conteúdo visível |
| **TTFB** | < 800ms | Tempo até primeiro byte |

## Como Verificar

```bash
# PageSpeed Insights (Google)
# https://pagespeed.web.dev/

# GTmetrix
# https://gtmetrix.com/

# Cache hit/miss — CloudWatch
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name CacheHitRate \
  --dimensions Name=DistributionId,Value=<ID> \
  --start-time 2026-06-01T00:00:00Z \
  --end-time 2026-06-03T23:59:59Z \
  --period 86400 \
  --statistics Average

# Ver logs de acesso
aws s3 ls s3://portfolio-website-6324548-logs/website-access-logs/ | tail -20
```
