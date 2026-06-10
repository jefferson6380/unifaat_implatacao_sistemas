# Security Analysis

## Medidas de Segurança Implementadas
- Security Group do Web Server: permite apenas HTTP (80) e SSH (22) do seu IP
- Security Group do Database: permite acesso apenas do backend
- Subnet privada para banco de dados
- Chave SSH protegida (Lab009Key.pem)

## Justificativa das Regras
- Princípio do menor privilégio: só portas e IPs necessários
- Banco de dados não exposto à internet

## Possíveis Melhorias
- Implementar VPN para acesso administrativo
- Habilitar logs de auditoria na AWS
- Usar IAM Roles para acesso a recursos AWS

## Compliance
- Segue boas práticas AWS Well-Architected Framework
