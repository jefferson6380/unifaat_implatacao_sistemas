# Troubleshooting Lab 1 - Deploy Manual em Linux Local

**Disciplina:** Implementação de Sistemas  
**Curso:** Análise e Desenvolvimento de Sistemas - UniFAAT  
**Lab:** 001 - Deploy Manual em Linux Local

## Problemas Mais Comuns

### 1. Nginx não Inicia ou Falha na Instalação

#### **Sintoma:**
```bash
sudo systemctl status nginx
# Mostra: failed (Result: exit-code)
```

#### **Diagnóstico:**
```bash
# Verifica logs de erro
sudo journalctl -u nginx.service -l

# Testa configuração
sudo nginx -t
```

#### **Soluções:**

**Problema: Porta 80 ocupada**
```bash
# Identifica processo usando porta 80
sudo lsof -i :80
sudo netstat -tulpn | grep :80

# Para Apache se estiver rodando
sudo systemctl stop apache2
sudo systemctl disable apache2
```

**Problema: Configuração inválida**
```bash
# Restaura configuração padrão
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```


### 2. Permission Denied ao Editar Arquivos

#### **Sintoma:**
```bash
nano /var/www/html/index.html
# Erro: Permission denied
```

#### **Diagnóstico:**
```bash
ls -la /var/www/html/
# Verifica proprietário dos arquivos
```

#### **Soluções:**

**Solução 1: Corrigir propriedade**
```bash
sudo chown -R $USER:$USER /var/www/html
chmod 755 /var/www/html
chmod 644 /var/www/html/*
```

**Solução 2: Se ainda não funcionar**
```bash
# Verifica se você está no grupo correto
groups $USER

# Adiciona ao grupo www-data se necessário
sudo usermod -a -G www-data $USER
```


### 3. Página não Carrega no Navegador

#### **Sintoma:**
- "This site can't be reached"
- "Connection refused"
- Página em branco

#### **Diagnóstico:**
```bash
# Verifica se Nginx está rodando
sudo systemctl status nginx

# Testa conectividade local
curl http://localhost
curl http://127.0.0.1

# Verifica porta
sudo netstat -tulpn | grep :80
```

#### **Soluções:**

**Problema: Nginx parado**
```bash
sudo systemctl start nginx
sudo systemctl enable nginx
```

**Problema: Firewall bloqueando**
```bash
# Ubuntu/Debian
sudo ufw allow 80
sudo ufw status

# Se usar iptables
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
```

**Problema: Arquivo index não encontrado**
```bash
# Verifica se existe index.html
ls -la /var/www/html/index.html

# Cria arquivo básico se não existir
echo "<h1>Teste</h1>" > /var/www/html/index.html
```


### 4. Esqueci a Senha Root no WSL

#### **Sintoma:**
```bash
sudo comando
# Erro: incorrect password
```

#### **Soluções:**

**Método 1: Reset via PowerShell (Windows)**
```powershell
# Abra PowerShell como Administrador
# Substitua "Ubuntu" pelo nome da sua distribuição

# Lista distribuições instaladas
wsl -l -v

# Define usuário padrão como root temporariamente
wsl -d Ubuntu -u root

# Dentro do WSL, redefine senha do seu usuário
passwd seuusuario

# Sai do WSL
exit

# Volta usuário padrão
ubuntu config --default-user seuusuario
```

**Método 2: Via Configuração WSL**
```powershell
# PowerShell como Administrador
wsl --shutdown

# Inicia como root
wsl -d Ubuntu -u root

# Redefine senha
passwd seuusuario

# Configura sudo sem senha (temporário)
echo "seuusuario ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/seuusuario
```

**Método 3: Reset Completo (Último Recurso)**
```powershell
# ATENÇÃO: Apaga todos os dados do WSL
wsl --unregister Ubuntu
# Reinstale o Ubuntu da Microsoft Store
```


### 5. Comando `apt update` Falha

#### **Sintoma:**
```bash
sudo apt update
# Erro: Could not resolve 'archive.ubuntu.com'
```

#### **Diagnóstico:**
```bash
# Testa conectividade
ping google.com
ping 8.8.8.8

# Verifica DNS
cat /etc/resolv.conf
```

#### **Soluções:**

**Problema: DNS no WSL**
```bash
# Edita configuração DNS
sudo nano /etc/resolv.conf

# Adiciona DNS público
nameserver 8.8.8.8
nameserver 8.8.4.4

# Reinicia networking
sudo systemctl restart systemd-resolved
```

**Problema: Repositórios inválidos**
```bash
# Backup atual
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Restaura repositórios padrão Ubuntu 22.04
sudo tee /etc/apt/sources.list << EOF
deb http://archive.ubuntu.com/ubuntu/ jammy main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted
deb http://archive.ubuntu.com/ubuntu/ jammy universe
deb http://archive.ubuntu.com/ubuntu/ jammy multiverse
deb http://security.ubuntu.com/ubuntu/ jammy-security main restricted
EOF

sudo apt update
```


### 6. Nano não Funciona Corretamente

#### **Sintoma:**
- Caracteres estranhos na tela
- Ctrl+O não salva
- Interface quebrada

#### **Soluções:**

**Problema: Terminal não configurado**
```bash
# Define variáveis de ambiente
export TERM=xterm-256color
export EDITOR=nano

# Adiciona ao .bashrc para permanência
echo 'export TERM=xterm-256color' >> ~/.bashrc
echo 'export EDITOR=nano' >> ~/.bashrc
```

**Alternativa: Usar vim básico**
```bash
# Instala vim se necessário
sudo apt install vim -y

# Uso básico do vim
vim /var/www/html/index.html
# Pressione 'i' para inserir
# Pressione 'Esc' depois ':wq' para salvar e sair
```


### 7. Logs não Aparecem

#### **Sintoma:**
```bash
sudo tail -f /var/log/nginx/error.log
# Arquivo não existe ou vazio
```

#### **Soluções:**

**Verifica se logs estão habilitados**
```bash
# Verifica configuração de logs
sudo nginx -T | grep log

# Cria diretório se não existir
sudo mkdir -p /var/log/nginx

# Reinicia nginx para criar logs
sudo systemctl restart nginx

# Força geração de log com erro
curl http://localhost/arquivo-inexistente
```


### 8. Problemas de Encoding/Caracteres

#### **Sintoma:**
- Acentos aparecem como "?" ou caracteres estranhos
- HTML não renderiza corretamente

#### **Soluções:**

**Configura locale corretamente**
```bash
# Verifica locale atual
locale

# Instala locales brasileiros
sudo apt install locales -y
sudo locale-gen pt_BR.UTF-8

# Define locale
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8

# Adiciona ao .bashrc
echo 'export LANG=pt_BR.UTF-8' >> ~/.bashrc
echo 'export LC_ALL=pt_BR.UTF-8' >> ~/.bashrc
```


## Comandos de Diagnóstico Rápido

### Verificação Completa do Sistema
```bash
#!/bin/bash
echo "=== DIAGNÓSTICO LAB 1 ==="
echo "Data: $(date)"
echo

echo "1. Status do Nginx:"
sudo systemctl status nginx --no-pager -l

echo -e "\n2. Teste de conectividade:"
curl -I http://localhost 2>/dev/null || echo "FALHA: Nginx não responde"

echo -e "\n3. Permissões /var/www/html:"
ls -la /var/www/html/

echo -e "\n4. Processos na porta 80:"
sudo lsof -i :80

echo -e "\n5. Últimos logs de erro:"
sudo tail -5 /var/log/nginx/error.log 2>/dev/null || echo "Sem logs de erro"

echo -e "\n6. Configuração Nginx:"
sudo nginx -t

echo -e "\n7. Espaço em disco:"
df -h /var/www/html

echo -e "\n=== FIM DIAGNÓSTICO ==="
```

### Script de Correção Automática
```bash
#!/bin/bash
echo "=== CORREÇÃO AUTOMÁTICA LAB 1 ==="

# Corrige permissões
sudo chown -R $USER:$USER /var/www/html
chmod 755 /var/www/html
chmod 644 /var/www/html/* 2>/dev/null

# Reinicia nginx
sudo systemctl restart nginx

# Testa configuração
sudo nginx -t

# Verifica resultado
if curl -s http://localhost > /dev/null; then
    echo "✅ Nginx funcionando corretamente!"
else
    echo "❌ Ainda há problemas. Execute diagnóstico manual."
fi
```


## Quando Pedir Ajuda

### Antes de chamar o professor, execute:

1. **Diagnóstico básico:**
```bash
sudo systemctl status nginx
sudo nginx -t
curl http://localhost
```

2. **Colete informações:**
```bash
# Versão do sistema
lsb_release -a

# Logs recentes
sudo journalctl -u nginx.service --since "10 minutes ago"
```

3. **Documente o erro:**
- Comando exato que executou
- Mensagem de erro completa
- O que estava tentando fazer

### Informações para o professor:
- Sistema operacional (Ubuntu, WSL, etc.)
- Versão do Nginx
- Logs de erro específicos
- Passos já tentados

> [!NOTE]
> **Desenvolvido por:** Professor Alexandre Tavares - UniFAAT  
> **Versão:** 1.0 - Semestre 2026.1  
> **Última atualização:** Janeiro 2025