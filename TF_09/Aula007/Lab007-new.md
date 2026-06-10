# Lab 006 - Revisão Prática Individual

## Objetivos
- Verificar funcionamento completo do stack local
- Revisar conceitos das aulas 1-5
- Identificar e resolver problemas pendentes
- Preparar para a prova intermediária

## Laboratório Prático Completo

### Cenário: Sistema de Blog Completo

Vamos implementar um sistema de blog com todas as tecnologias estudadas:
- **Frontend**: Nginx servindo arquivos estáticos
- **Backend**: API Node.js/Python
- **Banco**: MySQL/PostgreSQL
- **Proxy**: Nginx como proxy reverso
- **Monitoramento**: Healthchecks e logs

### Parte 1: Preparação do Ambiente

#### 1.1 Estrutura do Projeto
```bash
# Criar estrutura
mkdir -p ~/lab006-blog/{app,nginx,db}
cd ~/lab006-blog

# Estrutura esperada:
# lab006-blog/
# ├── docker-compose.yml
# ├── .env
# ├── app/
# │   ├── Dockerfile
# │   ├── package.json
# │   └── server.js
# ├── nginx/
# │   └── nginx.conf
# └── db/
#     └── init.sql
```

#### 1.2 Aplicação Backend (Node.js)

Crie `app/package.json`:
```json
{
  "name": "blog-api",
  "version": "1.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "mysql2": "^3.6.0"
  }
}
```

Crie `app/server.js`:
```javascript
const express = require('express');
const mysql = require('mysql2/promise');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.static('public'));

// Database connection
const dbConfig = {
  host: process.env.DB_HOST || 'db',
  user: process.env.DB_USER || 'blog_user',
  password: process.env.DB_PASSWORD || 'blog_pass',
  database: process.env.DB_NAME || 'blog_db'
};

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    await connection.ping();
    await connection.end();
    res.json({ 
      status: 'healthy', 
      timestamp: new Date().toISOString(),
      database: 'connected'
    });
  } catch (error) {
    res.status(503).json({ 
      status: 'unhealthy', 
      error: error.message 
    });
  }
});

// API endpoints
app.get('/api/posts', async (req, res) => {
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [rows] = await connection.execute('SELECT * FROM posts ORDER BY created_at DESC');
    await connection.end();
    res.json(rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/posts', async (req, res) => {
  const { title, content } = req.body;
  try {
    const connection = await mysql.createConnection(dbConfig);
    const [result] = await connection.execute(
      'INSERT INTO posts (title, content) VALUES (?, ?)',
      [title, content]
    );
    await connection.end();
    res.json({ id: result.insertId, title, content });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Blog API running on port ${PORT}`);
});
```

Crie `app/Dockerfile`:
```dockerfile
FROM node:16-alpine

# Instalar curl para healthcheck
RUN apk add --no-cache curl

WORKDIR /app

# Copiar package.json primeiro (cache layer)
COPY package*.json ./
RUN npm ci --only=production

# Copiar código da aplicação
COPY . .

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["npm", "start"]
```

### Parte 2: Configuração do Banco de Dados

Crie `db/init.sql`:
```sql
CREATE DATABASE IF NOT EXISTS blog_db;
USE blog_db;

CREATE TABLE IF NOT EXISTS posts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Dados de exemplo
INSERT INTO posts (title, content) VALUES 
('Primeiro Post', 'Este é o conteúdo do primeiro post do blog.'),
('Docker e Containers', 'Aprendendo sobre containerização com Docker.'),
('Nginx como Proxy', 'Configurando Nginx como proxy reverso.');
```

### Parte 3: Configuração do Nginx

Crie `nginx/nginx.conf`:
```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server app:3000;
    }
    
    server {
        listen 80;
        server_name localhost;
        
        # Logs
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        
        # Health check do Nginx
        location /nginx-health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }
        
        # Proxy para API
        location /api/ {
            proxy_pass http://backend;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
        
        # Health check da aplicação
        location /health {
            proxy_pass http://backend/health;
        }
        
        # Servir arquivos estáticos
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files $uri $uri/ /index.html;
        }
    }
}
```

### Parte 4: Docker Compose

Crie `.env`:
```env
# Database
MYSQL_ROOT_PASSWORD=root_password
MYSQL_DATABASE=blog_db
MYSQL_USER=blog_user
MYSQL_PASSWORD=blog_pass

# Application
PORT=3000
DB_HOST=db
DB_USER=blog_user
DB_PASSWORD=blog_pass
DB_NAME=blog_db

# Nginx
NGINX_PORT=8080
```

Crie `docker-compose.yml`:
```yaml
version: '3.8'

services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      timeout: 20s
      retries: 10
      start_period: 30s
    networks:
      - blog_network

  app:
    build: ./app
    environment:
      - PORT=${PORT}
      - DB_HOST=${DB_HOST}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
    depends_on:
      db:
        condition: service_healthy
    networks:
      - blog_network

  nginx:
    image: nginx:alpine
    ports:
      - "${NGINX_PORT}:80"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./frontend:/usr/share/nginx/html
    depends_on:
      - app
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/nginx-health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - blog_network

volumes:
  db_data:

networks:
  blog_network:
    driver: bridge
```

### Parte 5: Frontend Simples

Crie `frontend/index.html`:
```html
<!DOCTYPE html>
<html>
<head>
    <title>Blog - Lab 006</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .post { border: 1px solid #ddd; padding: 20px; margin: 20px 0; }
        .health { background: #f0f0f0; padding: 10px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Blog - Laboratório 006</h1>
    
    <div class="health">
        <h3>Status do Sistema</h3>
        <button onclick="checkHealth()">Verificar Saúde</button>
        <div id="health-status"></div>
    </div>
    
    <div>
        <h3>Posts do Blog</h3>
        <button onclick="loadPosts()">Carregar Posts</button>
        <div id="posts"></div>
    </div>
    
    <script>
        async function checkHealth() {
            try {
                const response = await fetch('/health');
                const data = await response.json();
                document.getElementById('health-status').innerHTML = 
                    `<p>Status: ${data.status}</p><p>Database: ${data.database}</p>`;
            } catch (error) {
                document.getElementById('health-status').innerHTML = 
                    `<p style="color: red;">Erro: ${error.message}</p>`;
            }
        }
        
        async function loadPosts() {
            try {
                const response = await fetch('/api/posts');
                const posts = await response.json();
                const postsHtml = posts.map(post => 
                    `<div class="post">
                        <h4>${post.title}</h4>
                        <p>${post.content}</p>
                        <small>Criado em: ${post.created_at}</small>
                    </div>`
                ).join('');
                document.getElementById('posts').innerHTML = postsHtml;
            } catch (error) {
                document.getElementById('posts').innerHTML = 
                    `<p style="color: red;">Erro ao carregar posts: ${error.message}</p>`;
            }
        }
    </script>
</body>
</html>
```

### Parte 6: Script de Automação

Crie `deploy.sh`:
```bash
#!/bin/bash
set -e

echo "🚀 Iniciando deploy do Blog Lab 006..."

# Limpeza
echo "🧹 Limpando ambiente anterior..."
docker-compose down -v 2>/dev/null || true
docker system prune -f

# Build e start
echo "🏗️ Construindo e iniciando serviços..."
docker-compose up -d --build

# Aguardar serviços ficarem saudáveis
echo "⏳ Aguardando serviços ficarem saudáveis..."
sleep 30

# Verificar status
echo "📊 Verificando status dos serviços..."
docker-compose ps

# Testes básicos
echo "🧪 Executando testes básicos..."

# Teste 1: Nginx respondendo
if curl -f http://localhost:8080/nginx-health > /dev/null 2>&1; then
    echo "✅ Nginx: OK"
else
    echo "❌ Nginx: FALHOU"
    exit 1
fi

# Teste 2: API Health
if curl -f http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ API Health: OK"
else
    echo "❌ API Health: FALHOU"
    exit 1
fi

# Teste 3: API Posts
if curl -f http://localhost:8080/api/posts > /dev/null 2>&1; then
    echo "✅ API Posts: OK"
else
    echo "❌ API Posts: FALHOU"
    exit 1
fi

echo "🎉 Deploy concluído com sucesso!"
echo "📱 Acesse: http://localhost:8080"
echo "🔍 Health: http://localhost:8080/health"
echo "📝 API: http://localhost:8080/api/posts"
```

```bash
chmod +x deploy.sh
```

## Checklist de Execução

### ✅ Preparação
- [ ] Estrutura de pastas criada
- [ ] Todos os arquivos criados
- [ ] Docker e Docker Compose instalados
- [ ] Permissões do script configuradas

### ✅ Execução
- [ ] `./deploy.sh` executado sem erros
- [ ] Todos os containers rodando (healthy)
- [ ] Frontend acessível em http://localhost:8080
- [ ] Health check respondendo
- [ ] API retornando posts

### ✅ Testes de Conceitos

#### Aula 1: Ciclo de Vida
- [ ] Entendo que este é um ambiente de desenvolvimento
- [ ] Sei que em produção seria diferente (HTTPS, domínio real)
- [ ] Compreendo o processo de deploy automatizado

#### Aula 2: Docker
- [ ] Dockerfile da aplicação funciona
- [ ] Imagem é construída corretamente
- [ ] Container executa a aplicação

#### Aula 3: Docker Compose
- [ ] Múltiplos serviços orquestrados
- [ ] Volume persistindo dados do banco
- [ ] Rede conectando os containers
- [ ] Dependências configuradas corretamente

#### Aula 4: Nginx
- [ ] Proxy reverso funcionando
- [ ] Variáveis de ambiente carregadas
- [ ] Arquivos estáticos servidos
- [ ] Logs sendo gerados

#### Aula 5: Automação
- [ ] Script de deploy automatizado
- [ ] Healthchecks implementados
- [ ] Testes automatizados
- [ ] Monitoramento básico funcionando

## Verificação Final do Sistema

### Arquitetura Implementada
```
┌─────────────────┐
│   Navegador     │ :8080
└─────────┬───────┘
          │ HTTP
┌─────────▼───────┐
│     Nginx       │ (Proxy + Static Files)
│   (Container)   │
└─────────┬───────┘
          │ /api/*
┌─────────▼───────┐
│   Node.js API   │ :3000 (interno)
│   (Container)   │
└─────────┬───────┘
          │ MySQL Protocol
┌─────────▼───────┐
│     MySQL       │ :3306 (interno)
│   (Container)   │
└─────────────────┘
```

### Checklist de Validação Final
- [ ] **Sistema completo funcionando**
- [ ] **Frontend carregando em http://localhost:8080**
- [ ] **Health check retornando status healthy**
- [ ] **API retornando posts do banco**
- [ ] **Dados persistindo após restart**
- [ ] **Logs acessíveis via docker-compose logs**
- [ ] **Todos os containers com status healthy**
- [ ] **Script de deploy executando sem erros**

## Comandos de Verificação e Troubleshooting

### Verificação Geral
```bash
# Status detalhado dos containers
docker-compose ps

# Verificar se todos estão healthy
docker-compose ps | grep -E "(healthy|Up)"

# Logs de todos os serviços
docker-compose logs --tail=50

# Uso de recursos em tempo real
docker stats --no-stream

# Verificar redes criadas
docker network ls | grep lab006

# Verificar volumes
docker volume ls | grep lab006
```

### Testes Funcionais
```bash
# Teste completo do sistema
curl -s http://localhost:8080 | grep -q "Blog - Lab 006" && echo "✅ Frontend OK" || echo "❌ Frontend FALHOU"

# Teste da API de health
curl -s http://localhost:8080/health | jq '.status' 2>/dev/null || echo "❌ Health check falhou"

# Teste da API de posts
curl -s http://localhost:8080/api/posts | jq 'length' 2>/dev/null || echo "❌ API posts falhou"

# Teste do Nginx health
curl -s http://localhost:8080/nginx-health | grep -q "healthy" && echo "✅ Nginx OK" || echo "❌ Nginx FALHOU"
```

### Verificação de Logs por Serviço
```bash
# Logs da aplicação Node.js
docker-compose logs app | tail -20

# Logs do Nginx (access e error)
docker-compose logs nginx | tail -20

# Logs do MySQL
docker-compose logs db | tail -20

# Seguir logs em tempo real (útil para debugging)
docker-compose logs -f --tail=10
```

### Comandos de Debug Avançado
```bash
# Entrar no container da aplicação
docker-compose exec app sh

# Verificar conectividade interna
docker-compose exec app ping db

# Testar conexão com banco de dentro do container
docker-compose exec app nc -zv db 3306

# Verificar variáveis de ambiente
docker-compose exec app env | grep DB

# Testar configuração do Nginx
docker-compose exec nginx nginx -t
```

## Troubleshooting - Problemas Específicos do Lab

### Problema: "Port 8080 already in use"
```bash
# Verificar o que está usando a porta
sudo lsof -i :8080

# Parar containers conflitantes
docker-compose down

# Ou alterar porta no .env
echo "NGINX_PORT=8081" >> .env
docker-compose up -d
```

### Problema: Container 'app' não inicia
```bash
# Verificar logs específicos
docker-compose logs app

# Problemas comuns:
# 1. Dependências não instaladas
docker-compose build --no-cache app

# 2. Banco não está pronto
docker-compose ps db  # Deve mostrar 'healthy'

# 3. Variáveis de ambiente incorretas
docker-compose exec app env | grep DB
```

### Problema: API retorna erro 503
```bash
# Verificar se banco está acessível
docker-compose exec app ping db

# Testar conexão MySQL
docker-compose exec app nc -zv db 3306

# Verificar se banco foi inicializado
docker-compose exec db mysql -u blog_user -pblog_pass -e "SHOW TABLES FROM blog_db;"
```

### Problema: Frontend não carrega
```bash
# Verificar se arquivos estão no lugar certo
ls -la frontend/

# Verificar configuração do Nginx
docker-compose exec nginx nginx -t

# Verificar logs do Nginx
docker-compose logs nginx | grep error
```

### Problema: Healthcheck sempre unhealthy
```bash
# Verificar se curl está instalado no container
docker-compose exec app which curl

# Testar healthcheck manualmente
docker-compose exec app curl -f http://localhost:3000/health

# Verificar se aplicação está rodando na porta correta
docker-compose exec app netstat -tlnp | grep 3000
```

### Reset Completo (Último Recurso)
```bash
# Parar tudo e limpar
docker-compose down -v
docker system prune -a -f

# Rebuild completo
docker-compose build --no-cache
docker-compose up -d
```

## Preparação para Prova Intermediária

### Competências Demonstradas neste Lab

#### 1. **Containerização** (Aula 2)
- ✅ Dockerfile multi-stage com healthcheck
- ✅ Build de imagem personalizada
- ✅ Configuração de ambiente de execução

#### 2. **Orquestração** (Aula 3)
- ✅ Docker Compose com múltiplos serviços
- ✅ Dependências entre containers
- ✅ Volumes para persistência
- ✅ Redes isoladas

#### 3. **Proxy Reverso** (Aula 4)
- ✅ Nginx como proxy e servidor estático
- ✅ Configuração de upstream
- ✅ Variáveis de ambiente
- ✅ Logs estruturados

#### 4. **Automação** (Aula 5)
- ✅ Script de deploy automatizado
- ✅ Healthchecks em todos os serviços
- ✅ Testes automatizados
- ✅ Monitoramento básico

### Pontos de Atenção para a Prova

#### ⚠️ **Não espere exatamente este cenário**
- A prova terá cenário similar mas diferente
- Pode ser outra linguagem (Python, Java)
- Pode ser outro banco (PostgreSQL)
- Pode ter requisitos adicionais

#### ✅ **Foque nos Conceitos**
- **Dockerfile**: Estrutura, layers, healthcheck
- **Compose**: Services, networks, volumes, depends_on
- **Nginx**: Proxy_pass, upstream, static files
- **Troubleshooting**: Logs, conectividade, debugging

#### 🎯 **Pratique Estes Comandos**
```bash
# Essenciais para a prova
docker-compose ps
docker-compose logs [service]
docker-compose exec [service] [command]
docker-compose build --no-cache
docker-compose down -v
curl -I [url]
telnet [host] [port]
```

### Simulado Rápido

#### Teste seu conhecimento:
1. **Como verificar se um container está healthy?**
2. **Como debuggar um container que não inicia?**
3. **Como testar conectividade entre containers?**
4. **Como verificar se o proxy reverso está funcionando?**
5. **Como persistir dados de um banco de dados?**

#### Respostas esperadas:
1. `docker-compose ps` ou `docker inspect`
2. `docker-compose logs [service]`
3. `docker-compose exec [service] ping [target]`
4. `curl` com headers ou verificar logs do Nginx
5. Volumes no docker-compose.yml

## Recursos de Apoio
- [Lab006-Troubleshooting.md](Lab006-Troubleshooting.md)
- [TA006.md](TA006.md) - Conceitos teóricos
- Laboratórios das aulas 001-005
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)

## Entrega do Lab

### O que entregar:
1. **Código funcionando**: Todo o projeto rodando
2. **Screenshot**: Sistema funcionando no navegador
3. **Log de execução**: Output do `./deploy.sh`
4. **Documentação**: README.md explicando como executar

### Critérios de avaliação:
- **Funcionalidade** (60%): Sistema completo funcionando
- **Código** (25%): Qualidade e organização
- **Documentação** (15%): Clareza das instruções

## Próxima Aula
**Aula 007 - Prova Teórico-Prática 1**
- Cenário similar mas diferente
- Tempo limitado (2 horas)
- Avaliação individual
- Demonstração obrigatória

---

**🎯 Objetivo alcançado:** Você agora domina um stack completo local com Docker, Compose, Nginx e automação!