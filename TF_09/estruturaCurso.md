# Estrutura do Curso: Implementação de Software

Este curso é focado na jornada de transformação de uma aplicação local em um serviço resiliente e automatizado na nuvem. A carga horária é dividida em exposição técnica, laboratórios práticos (mão na massa) e projeto integrador.

## Módulo 1: Fundamentos e Ambiente Local 

*O foco aqui é garantir que o aluno entenda o que é um servidor e como empacotar sua aplicação de forma isolada.*

- **Aula 01: Introdução ao Ciclo de Vida de Implantação**
  - Diferença entre desenvolvimento e operação. Conceitos de On-premise vs. Cloud.
- **Aula 02: Virtualização e Containers (Docker)**
  - Por que não usamos mais apenas VMs? Criando o primeiro Dockerfile.
- **Aula 03: Orquestração Local e Persistência**
  - Docker Compose para multi-serviços (App + Banco de Dados). Redes e Volumes.
- **Aula 04: Servidores Web e Configuração de Ambiente**
  - Configurando Nginx como Proxy Reverso e variáveis de ambiente (.env).
- **Aula 05: Automação de Build Local**
  - Scripts de automação e verificação de saúde da aplicação (Healthchecks).
- **Aula 06: Preparação do Ambiente para Migrar para a Cloud**
  - Instalação e configuração do AWS CLI e ferramentas de conectividade.

## Módulo 2: Avaliação Intermediária 

- **Aula 07: Revisão Prática Individual**
  - Checkpoint: Garantir que todos os alunos conseguem rodar o stack completo localmente com Docker.
- **Aula 07.1: Prova Teórico-Prática 1**
  - Objetivo: Realizar o deploy de uma aplicação multicamadas em um ambiente local simulado.

## Módulo 3: Migração e AWS Cloud

*Entrada no ecossistema AWS, focando em escalabilidade, segurança e automação profissional.*

- **Aula 08: Introdução à AWS e Infraestrutura Global**
  - Regiões, Zonas de Disponibilidade e Console AWS. Primeiros passos com IAM (Segurança).
  - **Lab:** Configuração de Billing Alarms para controle de custos.
- **Aula 09: Computação com EC2 e Segurança de Rede**
  - Provisionamento de instâncias Linux, Security Groups e chaves SSH.
- **Aula 10: Banco de Dados Gerenciado (RDS) vs. Local**
  - Migrando o banco de dados do container local para o Amazon RDS.
- **Aula 11: Armazenamento e Static Hosting (S3)**
  - Hospedagem de Front-end e armazenamento de arquivos (Buckets).
- **Aula 12: CI/CD - O Caminho da Automação**
  - Conceitos de Integração e Entrega Contínua. Introdução ao GitHub Actions.
- **Aula 13:  Fundamentos de Serverless e AWS Lambda**
  - Implatando códicos em ambientes sem servidor (Serverless).
- **Aula 14: Estratégias de Deploy e Observabilidade**
  - Blue/Green, Canary e Rolling updates. Monitoramento com CloudWatch (Logs e Métricas).
- **Aula 15: Projeto Prático - Pipeline de CI/CD do Zero**
  - Construindo um pipeline completo no GitHub Actions que compila, testa e implanta a aplicação na AWS.


## Módulo 4: Consolidação e Encerramento 
- **Aula 16: Revisão Geral e Workshop de Migração**
  - Revisão dos conceitos de Cloud, custos (Billing) e segurança. Plantão de dúvidas para o projeto final.
- **Aula 16.1: Prova Final / Apresentação de Projeto**
  - Objetivo: Demonstrar a aplicação rodando na AWS, totalmente integrada e automatizada.

## Considerações Pedagógicas

1. **Pré-requisitos:** É fundamental que os alunos já tenham uma aplicação base (Python, Node ou Java) pronta para ser "deployada".
2. **Metodologia:** Todas as aulas (exceto teóricas e provas) possuem 50% do tempo dedicado à prática guiada.
3. **Gestão de Custos:** Utilizaremos o *AWS Free Tier*. 

>**Nota Importante:** O aluno deve monitorar rigorosamente o relatório de gastos e seguir os passos de limpeza de recursos para evitar cobranças, já que o Free Tier possui limites específicos de uso e tempo.