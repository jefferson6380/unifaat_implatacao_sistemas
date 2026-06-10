# Aula 007 - Revisão Prática Individual

## Objetivos da Aula
- Consolidar conhecimentos das aulas 1-6
- Identificar e resolver lacunas no aprendizado
- Praticar troubleshooting em ambiente controlado
- Preparar-se para a Prova Teórico-Prática 1 (Aula 7.1)

## Conteúdo da Revisão

### Metodologia
Esta aula segue uma abordagem **prática e individual**, onde cada aluno:
- Implementa um stack completo do zero
- Identifica e resolve problemas de forma autônoma
- Pratica troubleshooting com cenários simulados
- Realiza autoavaliação estruturada

### Competências Revisadas

#### 1. **Docker (Aula 2)**
- Criação de Dockerfile funcional
- Build de imagens personalizadas
- Execução de containers com parâmetros
- Implementação de healthchecks

#### 2. **Docker Compose (Aula 3)**
- Escrita de docker-compose.yml
- Configuração de múltiplos serviços
- Implementação de volumes e persistência
- Gerenciamento de redes entre containers

#### 3. **Nginx (Aula 4)**
- Configuração de proxy reverso
- Servir arquivos estáticos
- Uso de variáveis de ambiente
- Interpretação de logs

#### 4. **Automação (Aula 5)**
- Criação de scripts de deploy
- Implementação de testes automatizados
- Monitoramento de logs e métricas
- Debugging de problemas

#### 5. **AWS CLI (Aula 6)**
- Configuração de credenciais
- Comandos básicos do CLI
- Conceitos de IAM e segurança

## Estrutura da Aula (2 horas)

1. **Diagnóstico inicial** (15 min) - Autoavaliação de competências
2. **Implementação guiada** (90 min) - Stack completo com checkpoints
3. **Troubleshooting dirigido** (30 min) - Resolução de problemas simulados
4. **Síntese e dúvidas** (15 min) - Consolidação e esclarecimentos

## Projeto da Revisão

### Sistema de Tarefas (Todo App)
- **Frontend**: Interface web simples
- **Backend**: API REST em Node.js
- **Database**: PostgreSQL
- **Proxy**: Nginx
- **Monitoramento**: Healthchecks e logs

### Arquitetura Implementada
```
Frontend (Nginx) → API (Node.js) → Database (PostgreSQL)
```

## Recursos

- [TA007.md](TA007.md) - Conceitos teóricos da revisão
- [Lab007.md](Lab007.md) - Laboratório prático completo
- [TF07.md](TF07.md) - Autoavaliação e preparação
- [Lab007-Troubleshooting.md](Lab007-Troubleshooting.md) - Solução de problemas

## Preparação para Prova

### Competências Essenciais
- [ ] Stack completo funcionando (app + banco + proxy)
- [ ] Troubleshooting eficiente com logs
- [ ] Conectividade entre containers
- [ ] Configuração de proxy reverso
- [ ] Healthchecks implementados

### Comandos Essenciais
```bash
# Gestão do stack
docker-compose up -d --build
docker-compose ps
docker-compose logs service-name
docker-compose exec service command

# Troubleshooting
curl -I http://localhost:port/endpoint
docker-compose exec app ping db
docker stats --no-stream
```

## Próxima Aula
**Aula 007.1 - Prova Teórico-Prática 1**
- Cenário similar mas diferente
- Tempo: 2 horas + 15 min demonstração
- Avaliação individual obrigatória

---

**🎯 Meta:** Consolidar conhecimentos e ganhar confiança para a prova!