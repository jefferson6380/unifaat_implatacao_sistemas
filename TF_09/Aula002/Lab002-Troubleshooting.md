# Troubleshooting Lab 2 - Virtual Hosts e HTTPS

**Lab:** 002 - Virtual Hosts e HTTPS  
**Foco:** Múltiplos sites, certificados SSL, configuração avançada

## Problemas Mais Comuns

### 1. Virtual Host não Funciona

#### **Sintoma:**
- Todos os sites mostram o mesmo conteúdo
- "404 Not Found" para sites específicos

#### **Diagnóstico:**
```bash
# Verifica sites habilitados
ls -la /etc/nginx/sites-enabled/

# Testa configuração
sudo nginx -t

# Verifica logs
sudo tail -f /var/log/nginx/error.log
```

#### **Soluções:**
```bash
# Habilita site
sudo ln -s /etc/nginx/sites-available/meusite /etc/nginx/sites-enabled/

# Remove site padrão se necessário
sudo rm /etc/nginx/sites-enabled/default

# Recarrega configuração
sudo systemctl reload nginx
```

### 2. Certificado SSL Falha

#### **Sintoma:**
- "Your connection is not private"
- "SSL_ERROR_BAD_CERT_DOMAIN"

#### **Soluções:**
```bash
# Verifica certificado
openssl x509 -in /etc/ssl/certs/meusite.crt -text -noout

# Regenera certificado autoassinado
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/meusite.key \
  -out /etc/ssl/certs/meusite.crt
```

### 3. Redirecionamento HTTP→HTTPS não Funciona

#### **Sintoma:**
- Site carrega em HTTP mas não redireciona para HTTPS

#### **Solução:**
```bash
# Verifica configuração de redirecionamento
sudo nginx -T | grep -A 10 "return 301"

# Adiciona redirecionamento se ausente
sudo nano /etc/nginx/sites-available/meusite
# Adicionar: return 301 https://$server_name$request_uri;
```


> [!NOTE]
> **Desenvolvido por:** Professor Alexandre Tavares - UniFAAT  
> **Versão:** 1.0 - Semestre 2026.1  
> **Última atualização:** Janeiro 2025