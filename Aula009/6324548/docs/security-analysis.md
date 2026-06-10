# Security Analysis

## Análise das medidas de segurança implementadas

A infraestrutura foi construída seguindo os princípios de segurança em nuvem. As principais medidas implementadas foram:
1. **Isolamento de Rede:** A criação de uma VPC customizada isola nosso ambiente do ambiente default (Default VPC).
2. **Subnets Direcionadas:** Criação de recursos com segregação (Public para o webserver e provisionamento de uma Private para camadas de backend/banco de rede no futuro).
3. **IAM e Chaves SSH:** Utilização de key pairs seguras. As instâncias são injetadas com uma PublicKey provisionada durante a criação, em que o dev detêm a PrivateKey localmente no arquivo `.pem`.

## Justificativa das Regras de Security Groups
O Security Group da aplicação web foi nomeado como `web-sg`. Ele define as portas com suas devidas restrições de origem (Inbound/Ingress):
- **Porta 80 / 3000 (HTTP):** Aberta para todo a internet (`0.0.0.0/0`) pois a premissa é servir uma aplicação web global (Frontend em Nginx e uma interface de API em Node).
- **Porta 22 (SSH):** Exclusiva para administração do sistema operacional, portanto seu acesso (Ingress) foi rigorosamente limitado diretamente ao endereço IP dinâmico/fixo do administrador que executou a script, pegando o IP via `curl -s http://checkip.amazonaws.com`.

## Conformidade e Princípio de Privilégio Mínimo
- Apenas as portas estritamente funcionais da aplicação se encontram abertas (80/3000 para a internet e 22 para admin). Demais portas ficam em DENEG default inbound. Isto cumpre as diretrizes básicas de Least Privilege.

## Melhorias Futuras Identificadas
- Inserir um Application Load Balancer na subnet pública, com certificado de camada TLS/SSL, migrando a EC2 para uma subnet privada sem acesso público na internet, aumentando a segurança.
- Restringir a porta 3000 do backend apenas para o IP do docker/proxy ou ALB, evitando acesso direto à porta pela internet, canalizando todo o tráfego via Nginx/Proxy.
