# Arquitetura de Rede AWS - TF09

Este documento detalha a topologia de rede implementada na AWS para o projeto de Portfólio Pessoal.

## 1. Configuração da VPC
- **Nome do Projeto**: `tf09-portfolio`
- **Região**: `us-east-1` (N. Virginia)
- **VPC CIDR Block**: `10.0.0.0/16`
- **DNS Hostnames**: Habilitado (para permitir resolução de nomes na EC2)

## 2. Subnets e Zonas de Disponibilidade (AZ)
A rede foi segmentada para garantir a separação de responsabilidades e preparar o ambiente para escalabilidade:

| Nome da Subnet | CIDR Block | AZ | Tipo | Finalidade |
| :--- | :--- | :--- | :--- | :--- |
| `public-subnet` | `10.0.1.0/24` | `us-east-1a` | Pública | Hospedagem da Instância EC2 (Web Server) |
| `private-subnet` | `10.0.2.0/24` | `us-east-1a` | Privada | Isolamento para futuras camadas de dados (RDS) |

## 3. Roteamento (Routing)

### Public Route Table
Responsável por encaminhar o tráfego da subnet pública para a internet.
- **Destino**: `0.0.0.0/0`
- **Target**: `Internet Gateway (IGW)`
- **Associação**: Vinculada à `public-subnet`.

### Private Route Table
Responsável pelo tráfego interno da VPC.
- **Destino**: `10.0.0.0/16`
- **Target**: `local`
- **Associação**: Vinculada à `private-subnet`. (Nota: Não possui rota para IGW, garantindo isolamento total).

## 4. Gateways de Comunicação
- **Internet Gateway (IGW)**: Criado e atachado à VPC para permitir entrada/saída de tráfego na subnet pública.
- **Auto-assign Public IP**: Habilitado na `public-subnet` para que a EC2 receba um IP público automaticamente no lançamento.

## 5. Diagrama de Fluxo
`Internet` <--> `IGW` <--> `Public Route Table` <--> `Public Subnet (EC2)` <--> `Private Subnet (Isolada)`

---
*Documentação gerada como parte da entrega do TF09 - UniFAAT.*
