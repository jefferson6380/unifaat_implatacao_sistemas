# Troubleshooting Guide

## Erros Comuns

### 1. Aplicação não carrega no navegador
- Verifique se o Security Group permite tráfego na porta 80.
- Verifique se os containers estão rodando: `docker ps`.
- Verifique o Internet Gateway e a Route Table da subnet pública.

### 2. Erro de permissão ao rodar scripts
- Aplique permissão de execução: `chmod +x script.sh`.

### 3. Backend não conecta com Banco de Dados
- Verifique se o Database Security Group permite tráfego vindo do Web Security Group.
- Verifique as variáveis de ambiente no arquivo `.env`.

### 4. Health Check falhando
- Verifique os logs do container backend: `docker logs <container_id>`.
