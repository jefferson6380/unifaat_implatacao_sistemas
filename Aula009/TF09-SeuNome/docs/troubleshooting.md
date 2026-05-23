# Troubleshooting

## Problemas Comuns

### Não consegue acessar a aplicação
- Verifique se a instância EC2 está rodando
- Cheque regras do Security Group
- Confirme se o Docker está rodando

### Banco de dados inacessível
- Verifique se o backend está na mesma VPC/subnet privada
- Cheque variáveis de ambiente do banco
- Veja logs do container com `docker logs <container>`

### Erro de permissão SSH
- Confirme que está usando a chave correta
- Permissão do arquivo: `chmod 400 Lab009Key.pem`
