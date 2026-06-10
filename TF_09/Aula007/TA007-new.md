# TA007 - Prova Teórico-Prática 1

**Disciplina:** Implementação de Sistemas  
**Curso:** Análise e Desenvolvimento de Sistemas - UniFAAT  
**Tipo:** Trabalho Antecedente  

## 1. Conceitos Fundamentais

### O que é uma Avaliação Teórico-Prática?

Uma **avaliação teórico-prática** combina conhecimento conceitual com aplicação prática, testando tanto a compreensão dos fundamentos quanto a capacidade de implementar soluções reais. É como um "exame de habilitação" - você precisa conhecer as regras E saber dirigir.

#### Componentes da Avaliação:

##### 1. **Parte Teórica (30%)**
- Conceitos fundamentais
- Diferenças entre tecnologias
- Boas práticas
- Resolução de problemas conceituais

##### 2. **Parte Prática (70%)**
- Implementação de stack completo
- Configuração de serviços
- Troubleshooting em tempo real
- Demonstração funcionando

### Metodologia de Avaliação Prática

#### Cenário Baseado em Problemas Reais
A avaliação simula situações que você encontrará no mercado de trabalho:
- Deploy de aplicação multicamadas
- Configuração de proxy reverso
- Implementação de persistência de dados
- Automação de processos

#### Critérios de Avaliação:

##### **Funcionalidade (40%)**
- Sistema completo funcionando
- Todos os componentes integrados
- Aplicação acessível via navegador
- Dados persistindo corretamente

##### **Qualidade Técnica (30%)**
- Código bem estruturado
- Configurações corretas
- Boas práticas aplicadas
- Documentação adequada

##### **Resolução de Problemas (30%)**
- Capacidade de debuggar erros
- Interpretação de logs
- Adaptação a mudanças
- Troubleshooting eficiente

### Stack Tecnológico Esperado

#### Arquitetura Multicamadas:
```
Frontend (Nginx) → Backend (App) → Database (MySQL/PostgreSQL)
```

#### Tecnologias Envolvidas:
- **Containerização**: Docker e Dockerfile
- **Orquestração**: Docker Compose
- **Proxy Reverso**: Nginx
- **Persistência**: Volumes e banco de dados
- **Automação**: Scripts e healthchecks
- **Configuração**: Variáveis de ambiente

### Competências Avaliadas

#### 1. **Containerização (Aula 2)**
- Criar Dockerfile funcional
- Build de imagens personalizadas
- Configuração de healthchecks
- Gerenciamento de dependências

#### 2. **Orquestração (Aula 3)**
- Docker Compose multi-serviços
- Configuração de redes
- Volumes para persistência
- Dependências entre serviços

#### 3. **Proxy Reverso (Aula 4)**
- Configuração do Nginx
- Proxy_pass para backend
- Servir arquivos estáticos
- Logs e monitoramento

#### 4. **Automação (Aula 5)**
- Scripts de deploy
- Healthchecks implementados
- Testes automatizados
- Monitoramento básico

#### 5. **Troubleshooting (Transversal)**
- Interpretação de logs
- Diagnóstico de problemas
- Conectividade entre serviços
- Performance e recursos

### Estratégias de Preparação

#### **Antes da Prova:**
1. **Pratique o Lab 006** até dominar completamente
2. **Revise conceitos teóricos** dos TAs 001-006
3. **Memorize comandos essenciais** do Docker
4. **Teste troubleshooting** com problemas simulados
5. **Organize documentação** de referência

#### **Durante a Prova:**
1. **Leia todas as instruções** antes de começar
2. **Gerencie o tempo** adequadamente
3. **Documente seus passos** conforme avança
4. **Teste incrementalmente** cada componente
5. **Mantenha calma** em caso de problemas

#### **Comandos Essenciais:**
```bash
# Docker básico
docker build -t nome-imagem .
docker run -p porta:porta nome-imagem
docker ps
docker logs container-name

# Docker Compose
docker-compose up -d
docker-compose ps
docker-compose logs
docker-compose exec service command
docker-compose down -v

# Troubleshooting
curl -I http://localhost:porta
telnet host porta
ping host
netstat -tlnp
```

### Tipos de Problemas Esperados

#### **Problemas de Configuração:**
- Portas conflitantes
- Variáveis de ambiente incorretas
- Configuração de rede
- Permissões de arquivo

#### **Problemas de Conectividade:**
- Containers não se comunicam
- Proxy reverso não funciona
- Banco de dados inacessível
- Healthchecks falhando

#### **Problemas de Persistência:**
- Dados não persistem
- Volumes mal configurados
- Banco não inicializa
- Migrations não executam

### Ambiente de Prova

#### **Recursos Disponíveis:**
- Máquina Linux com Docker instalado
- Acesso à internet para downloads
- Editor de texto (vim, nano, code)
- Documentação oficial (Docker, Nginx)

#### **Recursos NÃO Disponíveis:**
- Stack Overflow ou fóruns
- ChatGPT ou IAs
- Comunicação com colegas
- Código pronto de outros projetos

#### **Tempo Limite:**
- **2 horas** para implementação completa
- **15 minutos** para demonstração
- **5 minutos** para perguntas do professor

### Critérios de Sucesso

#### **Mínimo para Aprovação:**
- [ ] Stack básico funcionando (app + banco)
- [ ] Aplicação acessível via navegador
- [ ] Dados persistindo após restart
- [ ] Configuração básica do Nginx
- [ ] Demonstração funcional

#### **Para Nota Máxima:**
- [ ] Stack completo com proxy reverso
- [ ] Healthchecks implementados
- [ ] Logs estruturados e acessíveis
- [ ] Script de automação funcionando
- [ ] Troubleshooting eficiente
- [ ] Documentação clara
- [ ] Apresentação confiante

## 2. Questões de Múltipla Escolha

### Questão 1
Em uma avaliação prática de deploy, qual é o primeiro passo recomendado?

a) Começar imediatamente a escrever o docker-compose.yml
b) Ler todas as instruções e planejar a arquitetura
c) Fazer download de todas as imagens Docker
d) Configurar o banco de dados primeiro

**Gabarito: B**

**Justificativa:** O planejamento inicial é crucial em avaliações práticas. Ler todas as instruções permite entender o escopo completo, identificar dependências e criar uma estratégia de implementação eficiente, evitando retrabalho e otimizando o tempo disponível.

### Questão 2
Durante uma prova prática, seu container de aplicação não consegue conectar ao banco. Qual é a primeira verificação a fazer?

a) Reinstalar o Docker
b) Verificar se os containers estão na mesma rede
c) Reiniciar o computador
d) Reescrever todo o código da aplicação

**Gabarito: B**

**Justificativa:** Problemas de conectividade entre containers geralmente são relacionados à configuração de rede. Verificar se os containers estão na mesma rede Docker e se os nomes dos serviços estão corretos é o primeiro passo lógico no troubleshooting.

### Questão 3
Qual estratégia é mais eficiente durante uma avaliação prática com tempo limitado?

a) Implementar tudo de uma vez e testar no final
b) Implementar e testar cada componente incrementalmente
c) Focar apenas na parte que vale mais pontos
d) Copiar código de projetos anteriores

**Gabarito: B**

**Justificativa:** A abordagem incremental permite identificar e corrigir problemas rapidamente, evitando que erros se acumulem. Testar cada componente conforme implementa garante que a base esteja sólida antes de adicionar complexidade, maximizando as chances de sucesso.

## 3. Fontes Utilizadas

1. **Bloom, Benjamin S.** "Taxonomy of Educational Objectives." Longmans, Green, 1956.

2. **Docker Inc.** "Docker Documentation." Disponível em: https://docs.docker.com/

3. **Nginx Inc.** "Nginx Documentation." Disponível em: https://nginx.org/en/docs/

4. **Wiggins, Grant; McTighe, Jay.** "Understanding by Design." ASCD, 2005.

5. **Anderson, Lorin W.** "A Taxonomy for Learning, Teaching, and Assessing." Pearson, 2000.

6. **Biggs, John; Tang, Catherine.** "Teaching for Quality Learning at University." McGraw-Hill, 2011.

---

**Desenvolvido por:** Prof. Alexandre Tavares - UniFAAT  
**Data:** 2026.1