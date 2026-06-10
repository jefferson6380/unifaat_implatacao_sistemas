# Deployment Guide

## Pré-requisitos
- Conta AWS com Free Tier
- AWS CLI configurado
- Docker e Docker Compose instalados

## Passo a Passo
1. Execute o script `infrastructure/create-infrastructure.sh` para criar a infraestrutura AWS.
2. Faça upload do código da aplicação para a instância EC2.
3. Configure as variáveis de ambiente conforme `.env.example`.
4. Execute `docker-compose up -d` na EC2 para subir frontend, backend e banco de dados.
5. Acesse o frontend pelo IP público da EC2.

## Comandos de Verificação
- `aws ec2 describe-instances` para checar status da EC2
- `docker ps` para checar containers
- Teste API: `curl http://<EC2_IP>:3000/health`

## Troubleshooting
- Verifique regras de Security Group se não conseguir acessar a aplicação
- Consulte `docs/troubleshooting.md` para problemas comuns
