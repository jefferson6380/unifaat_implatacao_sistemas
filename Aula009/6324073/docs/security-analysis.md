# Security Analysis - TF09

## Medidas Implementadas

### 1. Segregação de Rede
A rede foi dividida em subnets pública e privada. A aplicação web reside na pública, enquanto recursos críticos (como um banco de dados futuro) ficariam na privada, sem rota direta para a internet.

### 2. Regras de Ingress/Egress
- **Porta 80**: Aberta apenas para o tráfego web legítimo.
- **Porta 22 (SSH)**: Recomendado restringir ao IP do desenvolvedor (`/32`).
- **Comunicação Interna**: O backend só é acessível internamente ou via proxy reverso do Nginx.

### 3. Gestão de Chaves
Utilização de Key Pairs da AWS para acesso criptografado, sem senhas simples para login.

## Melhorias Futuras
- Implementação de um Application Load Balancer (ALB).
- Uso de AWS WAF para proteção contra ataques web.
- Habilitação de HTTPS via AWS Certificate Manager (ACM).
