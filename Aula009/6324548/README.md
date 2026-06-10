# TF09 - Portfólio Pessoal na AWS

## Autoria
- **Nome Completo**: Seu Nome Aqui (Ajustar)
- **RA**: 6324548

## Visão Geral
Este projeto é a implementação do Trabalho Final (TF09) de Implantação de Sistemas. Consiste na elaboração e deploy automatizado e seguro de uma infraestrutura hospedada na AWS (EC2/VPC) para subir um sistema em containers com arquitetura Front/Back acopladas por Docker. 

## Arquitetura
A arquitetura foi baseada na criação de uma nova Virtual Private Cloud, isolando a regra de negócio do cenário Default:

### VPC Configuration
- CIDR Block: `10.200.0.0/16`
- Region: `us-east-1`

### Subnets
- Public Subnet: `10.200.1.0/24` - `us-east-1a` (Onde roda o WebServer EC2)
- Private Subnet: `10.200.2.0/24` - `us-east-1b` (Isolada para futuramente Banco de dados RDS)

### Routing
- Public Route Table: Roteia o tráfego de `10.200.1.0/24` para a Internet via Internet Gateway (`0.0.0.0/0`).
- Private Route Table: Sem portas para a internet.

## Como Executar
Siga o passo a passo completo ilustrado no [Guia de Deploy](docs/deployment-guide.md).

## Tecnologias Utilizadas
- **Node.JS + Express**: Backend escalável e de sintaxe unânime, com endpoint simulando armazenamento de projetos em JSON.
- **HTML + CSS Próprio + Vanilla JS**: Frontend clean.
- **Docker Compose**: Containerização Nginx webserver e Node App, unificando a inicialização rápida na AWS.
- **AWS CLI Bash Scripts**: Orquestração e destruição simples e imutável.

## Segurança Implementada
- Um AWS Security Group limitando tráfego do App apenas para portas 80 e 3000 (TCP).
- A porta 22 de Ingress SSH foi injetada com limite de Firewall específico permitindo comunicação apenas de uma Request Origin - o IP Local Público de quem gerou o ambiente da cloud.
- Detalhes estão disponíveis em [Análise de Segurança](docs/security-analysis.md).

## Custos Estimados
Os recursos configurados nestes scripts se enquadram perfeitamente no *AWS Free Tier*!
- VPC, Subnets, Routing: Serviços Base e Gratuitos ($0).
- Instância EC2 t2.micro `us-east-1`: Incluída no Free Tier (limitada a 750h). 
- Custo Final total do laboratório se utilizar os scripts temporariamente e rodar o Cleanup: **$ 0.00**.
