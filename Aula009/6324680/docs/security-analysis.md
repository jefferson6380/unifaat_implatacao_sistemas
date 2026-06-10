# Análise de Segurança — TF09

## Arquitetura de Segurança

A infraestrutura segue o princípio do **menor privilégio** em todas as camadas.

---

## Security Groups Implementados

### sg-web (Web Server)

| Tipo     | Porta | Protocolo | Origem              | Justificativa                              |
|----------|-------|-----------|---------------------|--------------------------------------------|
| HTTP     | 80    | TCP       | 0.0.0.0/0           | Acesso público à aplicação web             |
| HTTPS    | 443   | TCP       | 0.0.0.0/0           | Acesso seguro (produção)                   |
| Flask    | 5000  | TCP       | 0.0.0.0/0           | API da aplicação (dev/demo)                |
| SSH      | 22    | TCP       | \<MEU_IP\>/32       | Acesso administrativo restrito ao meu IP   |
| Outbound | All   | All       | 0.0.0.0/0           | Permitir atualizações e chamadas externas  |

### sg-db (Database — subnet privada)

| Tipo       | Porta | Protocolo | Origem   | Justificativa                          |
|------------|-------|-----------|----------|----------------------------------------|
| PostgreSQL | 5432  | TCP       | sg-web   | Apenas o web server acessa o banco     |

O banco de dados não tem acesso à internet — fica isolado na subnet privada.

---

## Princípios de Segurança Aplicados

### 1. Menor Privilégio
Cada Security Group libera apenas as portas estritamente necessárias. SSH aberto apenas para o IP do desenvolvedor, nunca para `0.0.0.0/0`.

### 2. Defesa em Profundidade
Duas camadas de segurança:
- **Security Groups** no nível da instância (stateful)
- **Network ACLs** no nível da subnet (stateless, padrão AWS)

### 3. Isolamento de Rede
- Web server na **subnet pública** (acessível via internet)
- Banco de dados na **subnet privada** (sem rota para internet)

### 4. Gerenciamento de Chaves SSH
- Key pair gerado especificamente para este projeto
- Arquivo `.pem` com permissão `400` (apenas leitura pelo dono)
- Chave nunca versionada no Git (está no `.gitignore`)

---

## Possíveis Melhorias (produção)

| Melhoria | Motivo |
|----------|--------|
| Usar HTTPS com certificado SSL (ACM) | Criptografia em trânsito |
| Mover banco para RDS na subnet privada | Separação de responsabilidades |
| Habilitar VPC Flow Logs | Auditoria de tráfego |
| Usar AWS Systems Manager Session Manager | SSH sem porta 22 aberta |
| WAF na frente do web server | Proteção contra OWASP Top 10 |
| CloudTrail ativo | Auditoria de chamadas de API |

---

## Conformidade com Boas Práticas AWS

- [x] Conta root protegida com MFA
- [x] Usuário IAM para operações (não root)
- [x] Billing alarm configurado
- [x] Free Tier monitorado
- [x] Credenciais nunca no código
- [x] Recursos tagueados para identificação
