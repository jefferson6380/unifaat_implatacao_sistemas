# Troubleshooting Lab 4 - Docker Compose

**Lab:** 004 - Docker Compose  
**Foco:** Multi-container, orquestração, networks

## Problemas Mais Comuns

### 1. Docker Compose não Encontrado

#### **Sintoma:**
```bash
docker-compose --version
# Command not found
```

#### **Soluções:**
```bash
# Instala Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Ou usa plugin do Docker
docker compose version
```

### 2. Serviços não se Comunicam

#### **Sintoma:**
- Aplicação não conecta com banco de dados
- "Connection refused" entre containers

#### **Diagnóstico:**
```bash
# Verifica network
docker network ls
docker network inspect nome-da-network

# Testa conectividade
docker exec -it container1 ping container2
```

#### **Soluções:**
```bash
# Verifica docker-compose.yml
# Certifica que estão na mesma network
# Usa nomes de serviço para conexão, não localhost
```

### 3. Volumes não Persistem

#### **Sintoma:**
- Dados perdidos após restart
- Arquivos não aparecem no host

#### **Soluções:**
```bash
# Verifica volumes
docker volume ls
docker volume inspect nome-volume

# Corrige permissões
sudo chown -R $USER:$USER ./data

# Verifica mapeamento no compose
# volumes:
#   - ./data:/app/data
```

### 4. Build Context Incorreto

#### **Sintoma:**
- "COPY failed: no such file or directory"
- Build não encontra arquivos

#### **Soluções:**
```bash
# Verifica estrutura de arquivos
tree .

# Ajusta context no docker-compose.yml
# build:
#   context: .
#   dockerfile: Dockerfile
```

## Troubleshooting Comum

### "502 Bad Gateway"

**Problema:** Nginx não consegue conectar aos backends  
**Solução:** Verificar se containers app1 e app2 estão rodando

```bash
docker compose ps
docker compose logs app1 app2
```

### "upstream not found"

**Problema:** Erro na configuração do nginx.conf  
**Solução:** Verificar sintaxe e nomes dos serviços

```bash
# Testar configuração
docker exec nginx-proxy nginx -t
```

### Balanceamento não funciona

**Problema:** Sempre o mesmo servidor responde  
**Solução:** Verificar algoritmo e configuração upstream

```bash
# Verificar configuração carregada
docker exec nginx-proxy cat /etc/nginx/nginx.conf
```

> [!NOTE]
> **Desenvolvido por:** Professor Alexandre Tavares - UniFAAT  
> **Versão:** 1.0 - Semestre 2026.1  
> **Última atualização:** Janeiro 2025