# Análise de Segurança - TF09

## Medidas de Segurança Implementadas

### 1. VPC Isolada
- Rede privada exclusiva para o projeto
- CIDR 10.0.0.0/16 sem sobreposição com outras redes
- Isolamento completo de outras contas AWS

### 2. Segmentação de Rede
- **Subnet Pública (10.0.1.0/24)**: Apenas o EC2 web server
- **Subnet Privada (10.0.2.0/24)**: Banco de dados isolado
- Banco de dados sem acesso direto à internet

### 3. Security Groups

#### SG Web Server
| Porta | Protocolo | Origem | Justificativa |
|-------|-----------|--------|---------------|
| 80 | TCP | 0.0.0.0/0 | Acesso público ao site |
| 443 | TCP | 0.0.0.0/0 | Acesso seguro ao site |
| 5000 | TCP | 0.0.0.0/0 | API backend |
| 22 | TCP | 187.0.234.39/32 | SSH restrito ao IP do desenvolvedor |

#### SG Database
| Porta | Protocolo | Origem | Justificativa |
|-------|-----------|--------|---------------|
| 5432 | TCP | SG-Web | Apenas o EC2 acessa o banco |

### 4. Princípio do Menor Privilégio
- SSH liberado apenas para o IP do desenvolvedor
- Banco de dados acessível apenas pelo Security Group do web server
- Nenhuma porta desnecessária aberta

### 5. Gerenciamento de Chaves SSH
- Key Pair criado exclusivamente para este projeto
- Permissão 400 na chave privada (somente leitura pelo dono)
- Chave privada nunca commitada no repositório

## Possíveis Melhorias Futuras
- Implementar HTTPS com certificado SSL (Let's Encrypt)
- Adicionar WAF (Web Application Firewall)
- Configurar VPN para acesso SSH em vez de IP fixo
- Habilitar AWS CloudTrail para auditoria
- Implementar AWS GuardDuty para detecção de ameaças

## Compliance com Boas Práticas AWS
- ✅ Princípio do menor privilégio aplicado
- ✅ Rede segmentada em pública e privada
- ✅ Acesso SSH restrito
- ✅ Banco de dados em subnet privada
- ✅ Security Groups documentados
