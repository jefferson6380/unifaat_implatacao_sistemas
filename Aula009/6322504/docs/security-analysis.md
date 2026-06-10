# Análise de Segurança - TF09

**Aluno:** Luan Teixeira | **RA:** 6322504

## Medidas de Segurança Implementadas

### 1. Segmentação de Rede (VPC)

A arquitetura utiliza uma VPC customizada com duas subnets em zonas de isolamento diferentes:

| Componente | Subnet | Acesso externo |
|---|---|---|
| Web Server | Pública (10.0.1.0/24) | Sim (HTTP/HTTPS) |
| Database | Privada (10.0.2.0/24) | Não |

**Justificativa:** O banco de dados nunca deve ser acessível diretamente pela internet. Colocá-lo em subnet privada garante que apenas o web server (na mesma VPC) possa se conectar a ele.

---

### 2. Security Groups

#### Web Server SG (`TF09-WebServer-SG`)

| Protocolo | Porta | Origem | Justificativa |
|---|---|---|---|
| TCP | 22 (SSH) | `138.99.162.75/32` | Apenas o IP do administrador |
| TCP | 80 (HTTP) | `0.0.0.0/0` | Acesso público à aplicação |
| TCP | 443 (HTTPS) | `0.0.0.0/0` | Acesso público seguro |
| TCP | 3000 (App) | `0.0.0.0/0` | Porta da API Node.js |

#### Database SG (`TF09-Database-SG`)

| Protocolo | Porta | Origem | Justificativa |
|---|---|---|---|
| TCP | 3306 (MySQL) | `TF09-WebServer-SG` | Apenas o Web Server acessa o banco |
| TCP | 22 (SSH) | `TF09-WebServer-SG` | Administração via bastião (web server) |

**Princípio do Menor Privilégio:** Cada Security Group libera somente as portas estritamente necessárias para o funcionamento do sistema.

---

### 3. Gerenciamento de Chaves SSH

- Key Pair gerado pelo AWS CLI com 2048-bit RSA
- Arquivo `.pem` com permissão `400` (somente leitura pelo dono)
- Acesso SSH restrito ao IP público do administrador (`/32` = um único IP)
- Chave privada nunca comitada no repositório

---

### 4. Arquitetura de Acesso ao Banco

```
Internet → Web Server (SG: Web) → Database (SG: DB, subnet privada)
                ↓
         Nginx (porta 80)
                ↓
         Node.js API (porta 3000)
                ↓
         MySQL (porta 3306, IP privado)
```

O banco de dados **não tem route table para internet**, garantindo isolamento total.

---

## Possíveis Melhorias Futuras

| Melhoria | Benefício |
|---|---|
| Habilitar HTTPS com certificado SSL (Let's Encrypt) | Criptografar tráfego em trânsito |
| Usar AWS RDS em vez de MySQL em EC2 | Backups automáticos, alta disponibilidade |
| Implementar NAT Gateway na subnet privada | Permitir atualizações de pacotes no DB sem expor à internet |
| Adicionar WAF (Web Application Firewall) | Proteção contra SQL injection, XSS |
| Habilitar CloudTrail | Auditoria de todas as ações na conta AWS |
| Rotacionar credenciais do banco periodicamente | Reduzir janela de exposição em caso de vazamento |

---

## Compliance com Boas Práticas AWS

- [x] Princípio do menor privilégio nos Security Groups
- [x] Banco de dados em subnet privada
- [x] SSH restrito a IP específico
- [x] Chave privada protegida (chmod 400)
- [x] Tags aplicadas em todos os recursos
- [x] Free Tier utilizado (t3.micro)
- [ ] HTTPS habilitado (melhoria futura)
- [ ] MFA na conta root AWS (recomendado)
