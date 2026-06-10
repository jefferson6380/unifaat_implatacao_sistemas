# Security Analysis - TF09

## 1. Segurança de Rede AWS

### Security Group Web Server (sg-0670d8d578466813d)

| Porta | Protocolo | Origem | Justificativa |
|---|---|---|---|
| 80 | TCP | 0.0.0.0/0 | Necessário para acesso público ao portfólio |
| 22 | TCP | 179.125.164.125/32 | SSH restrito ao IP do aluno — princípio do menor privilégio |

**Portas não abertas por design:**
- 3000 (Node.js): não exposta ao exterior — o Nginx faz proxy internamente
- 5432 (PostgreSQL): não exposta ao exterior nem ao Security Group — isolada na rede Docker

### Princípio do Menor Privilégio
O SSH é a porta mais crítica em qualquer servidor. Abrir a porta 22 para `0.0.0.0/0` permitiria tentativas de brute force de qualquer IP do mundo. A restrição ao IP do aluno (`/32`) elimina esse vetor de ataque.

---

## 2. Isolamento de Rede (Docker)

A aplicação usa duas redes Docker separadas:

```
Internet → Nginx (frontend-net) → Node.js (api-net) → PostgreSQL
```

- O **Nginx** não enxerga o PostgreSQL diretamente
- O **PostgreSQL** não tem nenhuma porta exposta ao host
- O **Node.js** é o único serviço com acesso ao banco

Isso replica o conceito de subnet pública/privada dentro da camada de aplicação, adicionando uma segunda camada de isolamento além da VPC.

---

## 3. Gerenciamento de Credenciais

- O arquivo `.env` com senhas do banco **não está no repositório Git**
- O repositório contém apenas o `.env.example` com as chaves vazias
- A chave `.pem` do EC2 foi gerada com `chmod 400` e também não está no repositório

---

## 4. Possíveis Melhorias

| Melhoria | Motivo |
|---|---|
| Adicionar HTTPS (certificado SSL) | Tráfego HTTP é transmitido sem criptografia |
| Mover PostgreSQL para subnet privada com instância RDS | Maior isolamento físico do banco |
| Configurar AWS WAF | Proteção contra ataques na camada 7 |
| Habilitar CloudWatch Logs | Centralização e alertas de logs |
| Implementar Auto Scaling Group | Alta disponibilidade |

---

## 5. Compliance com Boas Práticas AWS

| Prática | Status |
|---|---|
| SSH restrito a IP específico | ✅ Implementado |
| Banco de dados sem acesso público | ✅ Implementado |
| Credenciais fora do repositório | ✅ Implementado |
| Key Pair com permissão restrita | ✅ Implementado (chmod 400) |
| VPC customizada (não usar default) | ✅ Implementado |
| Free Tier utilizado | ✅ t3.micro |