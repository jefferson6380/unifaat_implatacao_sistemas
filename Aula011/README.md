# Aula 011 - Armazenamento e Static Hosting (S3)

## Objetivos da Aula
- Compreender o Amazon S3 e suas classes de armazenamento
- Implementar hospedagem de sites estáticos
- Configurar buckets S3 com políticas de segurança
- Integrar S3 com aplicações web
- Implementar CDN com CloudFront

## Conteúdo da Aula

### 1. **Amazon S3 (Simple Storage Service)**
- Conceitos fundamentais de object storage
- Classes de armazenamento e casos de uso
- Estrutura de buckets e objetos
- Versionamento e lifecycle policies

### 2. **Static Website Hosting**
- Configuração de hospedagem estática
- Domínios customizados
- Redirecionamentos e páginas de erro
- Integração com Route 53

### 3. **Segurança e Controle de Acesso**
- Bucket policies e ACLs
- IAM roles para acesso programático
- Criptografia de dados
- Logs de acesso e auditoria

### 4. **CloudFront CDN**
- Distribuição global de conteúdo
- Cache e performance
- Certificados SSL/TLS
- Invalidação de cache

### 5. **Integração com Aplicações**
- Upload de arquivos via aplicação
- Processamento de imagens
- Backup e arquivamento
- APIs do S3

## Recursos

- [TA011.md](TA011.md) - Conceitos teóricos
- [Lab011.md](Lab011.md) - Laboratório prático
- [TF11.md](TF11.md) - Trabalho final
- [Lab011-Troubleshooting.md](Lab011-Troubleshooting.md) - Solução de problemas

## Projeto da Aula

### Sistema de Portfólio com S3
- **Frontend**: Site estático hospedado no S3
- **Assets**: Imagens e arquivos no S3
- **CDN**: CloudFront para distribuição global
- **Backend**: API para upload de arquivos

### Arquitetura Implementada
```
CloudFront → S3 Static Website → API Gateway → Lambda → S3 Assets
```

## Próxima Aula
**Aula 012 - CI/CD - O Caminho da Automação**
- Integração e entrega contínua
- GitHub Actions
- Pipelines automatizados

---

**🎯 Meta:** Dominar armazenamento em nuvem e hospedagem estática!