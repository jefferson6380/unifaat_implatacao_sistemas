# Análise de Segurança - TF09

Este documento descreve as estratégias e camadas de proteção implementadas para garantir a integridade e disponibilidade do projeto na AWS.

## Análise das medidas de segurança implementadas
- **Isolamento de Rede**: Criação de uma VPC customizada com subnets pública e privada, impedindo o acesso direto de rede a camadas que não necessitam de exposição externa.
- **Proteção de Segredos**: Migração de senhas e chaves para variáveis de ambiente (`.env`), removendo credenciais sensíveis do código-fonte e dos arquivos de configuração do Docker.
- **Isolamento de Containers**: Uso de rede interna do Docker (bridge) para comunicação entre API e Banco de Dados, sem expor as portas 5432 e 8000 para a internet.
- **Descobrimento Dinâmico de IP**: O script de provisionamento identifica o IP público do administrador em tempo de execução para aplicar regras restritivas de SSH.

## Justificativa das regras de Security Groups

| Grupo de Segurança | Regra de Entrada | Justificativa |
| :--- | :--- | :--- |
| `web-sg` | Porta 80 (HTTP) | Necessário para o acesso público ao frontend via Nginx. |
| `web-sg` | Porta 22 (SSH) | Restrito ao IP do administrador para prevenir ataques de força bruta. |
| `db-sg` | Porta 5432 (SQL) | Permitido apenas a partir do `web-sg`. Garante que apenas a aplicação possa acessar o banco de dados. |

## Identificação de possíveis melhorias
1. **AWS Secrets Manager**: Substituir o arquivo `.env` por um gerenciador de segredos gerenciado para maior conformidade e rotação de chaves.
2. **Uso de ALB (Application Load Balancer)**: Colocar a instância atrás de um balanceador de carga para isolá-la completamente de IPs públicos diretos.
3. **Certificado SSL (ACM)**: Implementar HTTPS para criptografia de dados em trânsito.
4. **Bastion Host**: Utilizar uma instância de salto para acesso SSH, mantendo a EC2 principal em uma subnet privada sem IP público.

## Compliance com boas práticas
- **Princípio do Menor Privilégio**: Regras de firewall (Security Groups) configuradas para abrir apenas o mínimo necessário para o funcionamento do serviço.
- **Infraestrutura como Código (IaC)**: Redução de erro humano ao automatizar a criação da infraestrutura via scripts auditáveis.
- **Arquitetura em Camadas**: Separação física e lógica de componentes web e de dados.
- **Segurança na Camada de Aplicação**: Uso de CORS (Cross-Origin Resource Sharing) restritivo no FastAPI.

---
*Análise de segurança para o projeto TF09 - UniFAAT.*
