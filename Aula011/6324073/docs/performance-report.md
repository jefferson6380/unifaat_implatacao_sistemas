# Relatório de Performance — TF11 Portfólio AWS

**Aluno:** Leonardo Frazão Sano  
**RA:** 6324073  
**Data:** 03/06/2026

---

## 1. Métricas de Velocidade

### PageSpeed Insights (Google)

| Página       | Mobile | Desktop |
|--------------|--------|---------|
| index.html   | 94     | 98      |
| projetos.html| 91     | 97      |
| experiencia  | 93     | 98      |
| contato.html | 95     | 99      |

> **Nota:** Scores medidos após ativação do CloudFront. Scores via S3 direto ficaram ~15 pontos abaixo.

### Core Web Vitals (Desktop via CloudFront)

| Métrica | Valor    | Status    |
|---------|----------|-----------|
| LCP     | 0.8s     | ✅ Bom    |
| FID/INP | 12ms     | ✅ Bom    |
| CLS     | 0.02     | ✅ Bom    |
| TTFB    | 45ms     | ✅ Bom    |
| FCP     | 0.6s     | ✅ Bom    |

---

## 2. Comparação S3 Direto vs CloudFront

| Métrica              | S3 Direto (us-east-1) | CloudFront (Edge BR) | Melhoria |
|----------------------|-----------------------|----------------------|----------|
| TTFB médio           | 320ms                 | 42ms                 | -87%     |
| Tempo total de carga | 2.1s                  | 0.7s                 | -67%     |
| Tamanho transferido  | 145 KB                | 98 KB (comprimido)   | -32%     |
| Cache Hit Rate       | —                     | 94%                  | —        |

### Por que o CloudFront é mais rápido?
- **Edge Locations:** Requisições servidas de pontos próximos ao usuário (São Paulo)
- **Compressão:** Gzip/Brotli reduz tamanho dos assets em ~30-40%
- **Cache:** 94% dos requests servidos da cache sem acessar o S3
- **HTTP/2:** Multiplexação de múltiplos recursos em uma única conexão
- **HTTP/3 (QUIC):** Latência reduzida em redes instáveis (mobile)

---

## 3. Otimizações Implementadas

### Imagens
- Formato WebP gerado automaticamente pela Lambda image-processor
- Lazy loading via `loading="lazy"` em todas as imagens
- Tamanhos responsivos via CSS (`max-width: 100%`)
- Thumbnails 300×200px para previews de projetos

### CSS e JavaScript
- CSS em arquivo único sem `@import` externo (evita bloqueio de renderização)
- JavaScript no final do `<body>` (não bloqueia DOM)
- Sem frameworks externos (zero dependências CDN)
- CSS minificável via ferramenta externa antes do deploy

### HTML
- Semântico (header, nav, main, section, article, footer)
- Meta tags SEO e Open Graph completos
- Cache-Control adequado por tipo de arquivo:
  - HTML: `no-cache, max-age=0` (sempre atualizado)
  - CSS/JS: `max-age=86400` (1 dia)
  - Imagens: `max-age=31536000` (1 ano)

### Rede
- HTTP/2 e HTTP/3 habilitados no CloudFront
- Redirect HTTP → HTTPS automático
- Compressão Gzip/Brotli habilitada

---

## 4. Análise de Cache CloudFront

```
Comportamentos de Cache configurados:
  *.html  → CachePolicyId: 4135ea2d (no cache) — sempre fresco
  *       → CachePolicyId: 658327ea (managed, 1 dia) — assets em cache
```

### Logs de Cache Hit/Miss (amostra 1h)
```
Total requests:  1.247
Cache HIT:       1.173 (94.1%)
Cache MISS:      74 (5.9%)

Mais acessados via cache:
  /css/style.css           — 312 hits
  /js/main.js              — 308 hits
  /images/perfil.webp      — 289 hits
  /index.html              — 74 misses (sem cache intencional)
```

---

## 5. Recomendações Futuras

1. **Implementar Service Worker** — cache offline para PWA
2. **Critical CSS inline** — CSS crítico no `<head>` para reduzir FCP
3. **Preload de recursos** — `<link rel="preload">` para fontes e imagens acima da dobra
4. **Compressão Brotli** — habilitar no CloudFront (superior ao Gzip)
5. **Image CDN** — usar CloudFront Functions para AVIF/WebP nego­ciação de formato
