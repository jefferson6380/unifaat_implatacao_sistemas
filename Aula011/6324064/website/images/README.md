# Images

Substitua os arquivos `project-01.webp`, `project-02.webp` e `project-03.webp` por imagens reais dos seus projetos.

Recomendacoes:
- resolucao aproximada: 1280x800
- formato: webp
- qualidade: 68 a 78
- tamanho alvo por imagem: ate 180 KB

Exemplo de conversao:
```bash
npx -y sharp-cli -i projeto-original.jpg -o project-01.webp resize 1280 800 --format webp --quality 72
```
