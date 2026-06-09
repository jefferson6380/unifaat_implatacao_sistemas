# Performance Report - TF11

## Objetivo
Registrar as otimizacoes de frontend/CDN e os resultados medidos no ambiente real da AWS.

## Otimizacoes implementadas
- CSS e JS minificados (style.min.css e app.min.js)
- Imagens WebP com lazy loading
- Compressao no CloudFront
- Cache policy gerenciada (CachingOptimized)
- Distribuicao CloudFront com HTTPS obrigatorio

## Metodologia
Medições de tempo bruto com 5 amostras por endpoint, usando o mesmo host de origem do deploy:

- S3 Website endpoint (sem CDN)
- CloudFront endpoint (com CDN)

Arquivo fonte das medições: docs/evidencias/07-performance-check.txt

## Resultado medido
| Ambiente | Amostras (ms) | Media (ms) |
|---|---|---:|
| S3 direto | 388.61; 335.55; 314.13; 317.18; 326.69 | 336.43 |
| CloudFront | 425.27; 374.97; 385.14; 373.52; 370.63 | 385.91 |

## Analise
- Neste recorte curto, CloudFront ficou acima do endpoint S3.
- Isso pode ocorrer em janela de aquecimento de cache e por overhead TLS inicial.
- Para comparacao justa de CDN, recomenda-se repetir com maior volume e janela maior, separando cold e warm cache.

## Evidencias tecnicas existentes
- docs/evidencias/03-cloudfront-distribution.json
- docs/evidencias/06-cache-hit-rate.json
- docs/evidencias/07-performance-check.txt

## Evidencias visuais ainda recomendadas pelo enunciado
- PageSpeed Insights (S3 e CloudFront)
- GTmetrix
