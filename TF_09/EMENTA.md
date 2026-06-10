# EMENTA DO CURSO

## DADOS DE IDENTIFICAÇÃO

**Instituição:** Centro Universitário de Atibaia - UniFAAT  
**Curso:** Análise e Desenvolvimento de Sistemas  
**Disciplina:** Implementação de Sistemas  
**Código:** ADS-IMPL-2026.1  
**Carga Horária Total:** 80 horas  
**Período:** 2026.1  
**Professor:** Alexandre Tavares

## EMENTA

Estudo e aplicação prática de técnicas e ferramentas para implementação, implantação e manutenção de sistemas de software. Abordagem de ambientes locais e em nuvem. Virtualização e containerização de aplicações. Infraestrutura como código. Automação de processos de deploy. Serviços de computação em nuvem (AWS). Banco de dados gerenciados. Integração e entrega contínua (CI/CD). Estratégias de deployment. Monitoramento e observabilidade. Segurança e boas práticas em ambientes de produção.

## OBJETIVOS

### Objetivo Geral
Capacitar o aluno a implementar, implantar e gerenciar sistemas de software em ambientes locais e em nuvem, utilizando práticas modernas de DevOps, containerização e automação, com foco em escalabilidade, segurança e resiliência.

### Objetivos Específicos
- Compreender o ciclo de vida de implantação de software e diferenças entre ambientes on-premise e cloud
- Aplicar técnicas de virtualização e containerização utilizando Docker
- Configurar e gerenciar servidores web e proxies reversos
- Implementar infraestrutura em nuvem utilizando serviços AWS (EC2, RDS, S3, Lambda, ECS)
- Desenvolver pipelines de CI/CD para automação de deploy
- Aplicar estratégias de deployment (Blue/Green, Canary, Rolling)
- Implementar monitoramento e observabilidade de aplicações
- Aplicar práticas de segurança em ambientes de produção
- Gerenciar custos e otimizar recursos em nuvem

## CONTEÚDO PROGRAMÁTICO

### Módulo 1: Fundamentos e Ambiente Local (24h)
**Aula 01:** Introdução ao Ciclo de Vida de Implantação
- Diferença entre desenvolvimento e operação
- Conceitos de On-premise vs. Cloud
- Visão geral do curso e metodologia

**Aula 02:** Virtualização e Containers (Docker)
- Conceitos de virtualização e containerização
- Docker: instalação, imagens e containers
- Criando o primeiro Dockerfile
- Boas práticas de containerização

**Aula 03:** Orquestração Local e Persistência
- Docker Compose para multi-serviços
- Redes e comunicação entre containers
- Volumes e persistência de dados
- Aplicação + Banco de Dados

**Aula 04:** Servidores Web e Configuração de Ambiente
- Nginx como Proxy Reverso
- Configuração de Virtual Hosts
- Variáveis de ambiente (.env)
- HTTPS e certificados SSL

**Aula 05:** Automação de Build Local
- Scripts de automação
- Healthchecks e verificação de saúde
- Logs e debugging
- Otimização de builds

**Aula 06:** Preparação do Ambiente para Cloud
- Instalação e configuração do AWS CLI
- Ferramentas de conectividade
- Conceitos de IAM e segurança
- Preparação para migração

### Módulo 2: Avaliação Intermediária (8h)
**Aula 07:** Revisão Prática Individual
- Checkpoint: Deploy completo local com Docker
- Troubleshooting e resolução de problemas
- Preparação para prova

**Aula 07.1:** Prova Teórico-Prática 1
- Avaliação individual
- Deploy de aplicação multicamadas
- Ambiente local simulado

### Módulo 3: Migração e AWS Cloud (40h)
**Aula 08:** Introdução à AWS e Infraestrutura Global
- Regiões e Zonas de Disponibilidade
- Console AWS e navegação
- IAM: usuários, grupos e políticas
- Billing Alarms e controle de custos

**Aula 09:** Computação com EC2 e Segurança de Rede
- Provisionamento de instâncias Linux
- Security Groups e NACLs
- Chaves SSH e acesso remoto
- Deploy manual em EC2

**Aula 10:** Banco de Dados Gerenciado (RDS)
- Conceitos de banco de dados gerenciado
- Criação e configuração de RDS
- Migração de dados
- Backup e recuperação

**Aula 11:** Armazenamento e Static Hosting (S3)
- Amazon S3: buckets e objetos
- Hospedagem de sites estáticos
- CloudFront e CDN
- Políticas de acesso

**Aula 12:** DNS e Gerenciamento de Domínios (Route 53)
- Conceitos de DNS
- Route 53: zonas e registros
- Políticas de roteamento
- Integração com outros serviços AWS

**Aula 13:** Fundamentos de Serverless e AWS Lambda
- Arquitetura serverless
- AWS Lambda: funções e triggers
- API Gateway
- Casos de uso práticos

**Aula 14:** Estratégias de Deploy e Observabilidade
- Blue/Green Deployment
- Canary Releases
- Rolling Updates
- CloudWatch: logs, métricas e alarmes

**Aula 15:** Projeto Prático - Pipeline de CI/CD
- GitHub Actions: workflows e actions
- Pipeline completo: build, test, deploy
- Integração com AWS
- Automação end-to-end

### Módulo 4: Consolidação e Encerramento (8h)
**Aula 16:** Revisão Geral e Workshop de Migração
- Revisão de conceitos de Cloud
- Estratégias de migração (6 Rs)
- Otimização de custos
- Segurança e compliance
- Workshop prático de migração

**Aula 16.1:** Prova Final / Apresentação de Projeto
- Avaliação final teórico-prática
- Projeto integrador
- Apresentação de resultados

## METODOLOGIA

### Estratégias de Ensino
- **Aulas Expositivas:** Apresentação de conceitos teóricos e fundamentos
- **Laboratórios Práticos:** Atividades hands-on com 50% do tempo de cada aula
- **Projetos Integradores:** Desenvolvimento de projetos reais ao longo do curso
- **Estudos de Caso:** Análise de implementações reais do mercado
- **Trabalhos em Grupo:** Colaboração e desenvolvimento de soft skills

### Recursos Didáticos
- Laboratório de informática com acesso à internet
- Conta AWS (Free Tier) para cada aluno
- Repositório GitHub com materiais e exemplos
- Documentação técnica oficial
- Vídeos e tutoriais complementares

### Ambiente de Aprendizagem
- **Presencial:** Aulas no laboratório com acompanhamento do professor
- **Online:** Materiais disponíveis no repositório GitHub
- **Suporte:** Atendimento via GitHub Issues e horários de monitoria

## AVALIAÇÃO

### Critérios de Avaliação
A avaliação será composta por:

1. **Prova Intermediária (Aula 07.1)** - Peso 2,0
   - Avaliação teórico-prática individual
   - Deploy de aplicação multicamadas local

2. **Trabalhos Finais (TFs)** - Peso 3,0
   - TF01 a TF06: Projetos práticos de cada módulo
   - Avaliação contínua do progresso

3. **Prova Final (Aula 16.1)** - Peso 3,0
   - Avaliação teórico-prática individual
   - Projeto integrador completo na AWS

4. **Participação e Laboratórios** - Peso 2,0
   - Presença e participação nas aulas práticas
   - Entrega de laboratórios

### Cálculo da Média Final
```
Média Final = (PI × 2,0) + (TFs × 3,0) + (PF × 3,0) + (Part × 2,0)
                              10,0
```

**Aprovação:** Média Final ≥ 6,0 e frequência ≥ 75%

### Recuperação
Alunos com média entre 4,0 e 5,9 terão direito a prova de recuperação, que substituirá a menor nota entre PI e PF.

## BIBLIOGRAFIA

### Bibliografia Básica

1. **KIM, Gene; DEBOIS, Patrick; WILLIS, John; HUMBLE, Jez.** *The DevOps Handbook: How to Create World-Class Agility, Reliability, and Security in Technology Organizations.* IT Revolution Press, 2016.

2. **WITTIG, Andreas; WITTIG, Michael.** *Amazon Web Services in Action.* 3rd Edition. Manning Publications, 2023.

3. **POULTON, Nigel.** *Docker Deep Dive.* Independently Published, 2023.

### Bibliografia Complementar

1. **MORRIS, Kief.** *Infrastructure as Code: Managing Servers in the Cloud.* 2nd Edition. O'Reilly Media, 2020.

2. **FORSGREN, Nicole; HUMBLE, Jez; KIM, Gene.** *Accelerate: The Science of Lean Software and DevOps.* IT Revolution Press, 2018.

3. **BEYER, Betsy; JONES, Chris; PETOFF, Jennifer; MURPHY, Niall Richard.** *Site Reliability Engineering: How Google Runs Production Systems.* O'Reilly Media, 2016.

4. **RICHARDSON, Chris.** *Microservices Patterns: With Examples in Java.* Manning Publications, 2018.

5. **BURNS, Brendan; BEDA, Joe; HIGHTOWER, Kelsey.** *Kubernetes: Up and Running.* 3rd Edition. O'Reilly Media, 2022.

### Recursos Online

- **AWS Documentation:** https://docs.aws.amazon.com/
- **Docker Documentation:** https://docs.docker.com/
- **GitHub Actions Documentation:** https://docs.github.com/actions
- **AWS Training and Certification:** https://aws.amazon.com/training/
- **AWS Well-Architected Framework:** https://aws.amazon.com/architecture/well-architected/

## COMPETÊNCIAS E HABILIDADES DESENVOLVIDAS

### Competências Técnicas
- Implementação e deploy de aplicações em ambientes locais e cloud
- Containerização e orquestração de aplicações
- Automação de infraestrutura e processos
- Configuração e gerenciamento de serviços AWS
- Desenvolvimento de pipelines CI/CD
- Monitoramento e troubleshooting de sistemas
- Aplicação de práticas de segurança

### Competências Comportamentais
- Trabalho em equipe e colaboração
- Resolução de problemas complexos
- Comunicação técnica efetiva
- Aprendizado contínuo e adaptabilidade
- Pensamento crítico e analítico
- Gestão de tempo e prioridades

## PRÉ-REQUISITOS

- Conhecimentos básicos de programação (Python, Node.js ou Java)
- Fundamentos de redes de computadores
- Conhecimentos básicos de Linux/Unix
- Lógica de programação
- Banco de dados relacionais

## OBSERVAÇÕES IMPORTANTES

### Gestão de Custos AWS
- Todos os alunos devem criar conta AWS e utilizar o Free Tier
- Configuração obrigatória de Billing Alarms
- Limpeza de recursos ao final de cada laboratório
- Monitoramento constante de custos
- Responsabilidade individual sobre gastos

### Ferramentas Necessárias
- Computador com mínimo 8GB RAM
- Sistema operacional: Linux, macOS ou Windows 10/11
- Docker Desktop instalado
- Git instalado
- Editor de código (VS Code recomendado)
- Conta GitHub ativa

### Política de Integridade Acadêmica
- Trabalhos devem ser originais
- Colaboração é incentivada, mas plágio é proibido
- Código-fonte deve ser versionado no GitHub
- Citação de fontes é obrigatória

---

**Data de Elaboração:** Janeiro/2026  
**Vigência:** 2026.1  
**Aprovação:** Colegiado do Curso de ADS - UniFAAT

<div align="center">

*Esta ementa pode sofrer ajustes durante o semestre conforme necessidades pedagógicas*

</div>
