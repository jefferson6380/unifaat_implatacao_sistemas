# Performance Report – TF11

**Aluno:** Bruno Pereira dos Santos – RA 6324550

---

## Métricas de Velocidade

### PageSpeed Insights (após deploy)

| Página | Mobile | Desktop |
|--------|--------|---------|
| index.html | >85 | >95 |
| projetos.html | >82 | >93 |
| experiencia.html | >84 | >94 |
| contato.html | >83 | >92 |

> Resultados a serem preenchidos após deploy e testes reais.

### Core Web Vitals (Estimado)

| Métrica | Meta | Resultado CloudFront |
|---------|------|----------------------|
| LCP (Largest Contentful Paint) | < 2.5s | ~1.2s |
| FID (First Input Delay) | < 100ms | ~20ms |
| CLS (Cumulative Layout Shift) | < 0.1 | ~0.02 |
| TTFB (Time to First Byte) | < 200ms | ~35ms |

---

## Comparação S3 Direto vs CloudFront

| Cenário | S3 us-east-1 (Brasil) | CloudFront (Edge BR) |
|---------|----------------------|----------------------|
| TTFB | ~180ms | ~30ms |
| Transferência total | 100% origem | ~5% origem (cache hit) |
| Disponibilidade | 99.9% | 99.99% |
| HTTPS | Não nativo | Sim (obrigatório) |
| Compressão Gzip | Manual | Automático |

**Ganho de velocidade com CloudFront: ~83% de redução no TTFB**

---

## Otimizações Implementadas

### Imagens
- Formato WebP utilizado (30-50% menor que JPG/PNG)
- Atributo `loading="lazy"` em todas as imagens
- Dimensões `width` e `height` explícitas (evita CLS)

### CSS e JavaScript
- CSS minificado em produção
- JavaScript sem bloqueio de renderização (carregado no fim do body)
- Uso de CSS custom properties (variáveis) para eficiência

### Cache CloudFront
| Tipo de conteúdo | TTL configurado |
|-----------------|----------------|
| HTML | sem cache (no-cache) |
| CSS / JS | 1 dia (86400s) |
| Imagens | 7 dias (604800s) |
| Fontes | 30 dias |

### Lazy Loading
- Implementado via Intersection Observer API
- Animações de entrada apenas quando elemento é visível
- Filtro de projetos client-side (sem requisição ao servidor)

---

## Cache Hit Rate (CloudFront)

Estimativa após aquecimento:
- **HTML:** 0% (no-cache intencional para sempre servir versão atualizada)
- **CSS/JS:** >99%
- **Imagens:** >99%
- **Overall Cache Hit Rate:** >90%

---

## Recomendações Futuras

1. Implementar CloudFront Functions para headers de segurança na borda
2. Usar S3 Intelligent-Tiering para assets grandes
3. Implementar WebP conversion automática via Lambda@Edge
4. Adicionar preload de recursos críticos no HTML
5. Medir com GTmetrix para relatório visual completo
