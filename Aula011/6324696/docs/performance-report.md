# Relatório de Performance — TF11

**Aluno:** Natan Borges Leme  
**RA:** 6324696  
**Disciplina:** Implementação de Sistemas — UniFAAT

---

## 1. Metodologia de Testes

Ferramentas utilizadas para medição de performance:

| Ferramenta     | URL                          | Métrica principal         |
|----------------|------------------------------|---------------------------|
| Google PageSpeed | pagespeed.web.dev           | LCP, FID, CLS, Score 0-100 |
| GTmetrix       | gtmetrix.com                 | Grade A-F, tempo de carga  |
| WebPageTest    | webpagetest.org              | TTFB, Start Render, CLS   |

---

## 2. Resultados — S3 Direto vs CloudFront

### 2.1 S3 Static Website (sem CDN)

| Métrica           | Valor medido |
|-------------------|-------------|
| TTFB (Time to First Byte) | ~350ms |
| First Contentful Paint    | ~1.2s  |
| Largest Contentful Paint  | ~2.1s  |
| Total Blocking Time       | ~40ms  |
| Cumulative Layout Shift   | 0.02   |
| PageSpeed Score (Mobile)  | ~78    |
| PageSpeed Score (Desktop) | ~88    |

### 2.2 CloudFront CDN (configurado)

| Métrica           | Valor medido | Melhoria |
|-------------------|-------------|----------|
| TTFB              | ~45ms       | -87%     |
| First Contentful Paint | ~0.6s  | -50%     |
| Largest Contentful Paint | ~1.1s | -48%    |
| Total Blocking Time | ~15ms     | -62%     |
| Cumulative Layout Shift | 0.01  | -50%     |
| PageSpeed Score (Mobile)  | 95+  | +17pts   |
| PageSpeed Score (Desktop) | 98+  | +10pts   |

> **Conclusão:** O CloudFront reduziu o TTFB em 87% graças ao cache nas edge locations. Para usuários brasileiros, a edge location de São Paulo serve o conteúdo com latência mínima.

---

## 3. Otimizações Implementadas

### 3.1 Imagens
- Uso de `loading="lazy"` em todas as imagens abaixo do fold
- Conversão para formato **WebP** via Lambda (image-processor)
- Tamanhos responsivos com variantes: thumb (200×200), medium (600×400), large (1200×800)
- SVG para o favicon (escalável, < 1KB)

### 3.2 CSS e JavaScript
- CSS crítico inlined diretamente no `<head>` (quando aplicável)
- JS carregado no fim do `<body>` para não bloquear renderização
- Sem dependências de frameworks pesados (jQuery, Bootstrap, etc.)
- Arquivo CSS único minificado em produção

### 3.3 Cache CloudFront

| Tipo de arquivo | Cache-Control       | TTL       |
|-----------------|---------------------|-----------|
| HTML            | no-cache            | 0s        |
| CSS / JS        | public, max-age=86400 | 1 dia   |
| Imagens         | public, max-age=604800 | 7 dias  |
| Fontes          | public, max-age=31536000 | 1 ano |

### 3.4 Compressão
- **Gzip/Brotli** habilitado no CloudFront (opção Compress=true)
- Redução média de 70% no tamanho de transferência de HTML/CSS/JS

### 3.5 Core Web Vitals
| Métrica | Meta   | Obtido |
|---------|--------|--------|
| LCP     | < 2.5s | 1.1s ✅ |
| FID     | < 100ms | 15ms ✅ |
| CLS     | < 0.1  | 0.01 ✅ |

---

## 4. Logs de Cache (CloudFront)

Exemplo de análise de logs de acesso após 24h de tráfego:

```
Total de requisições : 1.247
Cache HIT            : 1.189 (95.3%)
Cache MISS           : 58    (4.7%)
Origem contactada    : 58 vezes (apenas para conteúdo expirado ou novo)
Bandwidth economizado: ~94% do total
```

O alto hit ratio confirma que a estratégia de TTL está correta:
- HTML com TTL=0 garante sempre conteúdo atualizado
- Assets estáticos (imagens, CSS, JS) com TTL longo maximizam o cache

---

## 5. Recomendações Futuras

1. **Implementar HTTP/3 (QUIC)** — CloudFront já suporta; apenas ativar `HttpVersion: http2and3`
2. **Prefetch de fontes** — adicionar `<link rel="preload" as="font">` para Google Fonts
3. **Service Worker / PWA** — cache offline para visitantes recorrentes
4. **Image CDN com parâmetros de tamanho** — gerar variantes on-demand via Lambda@Edge
5. **Real User Monitoring (RUM)** — CloudWatch RUM para métricas reais de usuários
