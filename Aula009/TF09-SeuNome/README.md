# TF09 - Portfólio Pessoal na AWS

## Visão Geral
Projeto de portfólio pessoal hospedado na AWS, utilizando EC2, VPC customizada, subnets públicas e privadas, Security Groups e boas práticas de segurança de rede.

## Arquitetura
Veja o diagrama em `infrastructure/infrastructure-diagram.png` e detalhes em `docs/deployment-guide.md`.

## Como Executar
Consulte o guia de implantação em `docs/deployment-guide.md`.

## Tecnologias Utilizadas
- AWS EC2, VPC, Security Groups
- Docker, Docker Compose
- Node.js (backend)
- React (frontend)
- MySQL/PostgreSQL (database)

## Segurança Implementada
- Princípio do menor privilégio nos Security Groups
- Chave SSH protegida
- Subnet privada para banco de dados

## Custos Estimados
Infraestrutura dimensionada para uso no Free Tier AWS. Consulte detalhes em `docs/deployment-guide.md`.