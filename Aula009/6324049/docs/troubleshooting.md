# Troubleshooting - TF09

## Problemas Comuns

### Site não carrega (http://IP)
1. Verificar se o container frontend está rodando:
```bash
sudo docker-compose ps
```
2. Verificar se a porta 80 está liberada no Security Group
3. Verificar logs do nginx:
```bash
sudo docker-compose logs frontend
```

### API Offline
1. Verificar se a porta 5000 está liberada no Security Group
2. Verificar se o container backend está rodando:
```bash
sudo docker-compose ps
```
3. Verificar logs do backend:
```bash
sudo docker-compose logs backend
```

### Erro de conexão SSH
1. Verificar se o IP mudou (IPs públicos mudam ao reiniciar o EC2)
2. Verificar se o Security Group tem seu IP liberado na porta 22
3. Verificar permissão da chave:
```bash
chmod 400 TF09-KeyPair.pem
```

### Containers não sobem
1. Verificar logs de erro:
```bash
sudo docker-compose up --build
```
2. Verificar espaço em disco:
```bash
df -h
```
3. Reiniciar o Docker:
```bash
sudo systemctl restart docker
```

## Comandos Úteis
```bash
# Ver containers rodando
sudo docker-compose ps

# Ver logs em tempo real
sudo docker-compose logs -f

# Reiniciar aplicação
sudo docker-compose restart

# Parar aplicação
sudo docker-compose down

# Verificar uso de recursos
sudo docker stats
```
