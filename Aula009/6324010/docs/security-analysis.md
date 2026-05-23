# 🔐 Security Analysis

Este documento apresenta a análise de segurança da aplicação implantada na AWS EC2.

---

## 📌 Visão Geral

A aplicação foi hospedada em uma instância EC2 utilizando um servidor Apache, com acesso público via HTTP.

---

## 🔒 1. Configuração de Segurança

### Security Group configurado:

| Tipo | Porta | Origem    |
| ---- | ----- | --------- |
| SSH  | 22    | Meu IP    |
| HTTP | 80    | 0.0.0.0/0 |

---

## 🛡️ 2. Medidas de Segurança Implementadas

### ✅ Restrição de acesso SSH

* A porta 22 foi limitada apenas ao IP do usuário
* Evita acessos não autorizados

---

### ✅ Uso de chave privada (.pem)

* A autenticação foi feita via chave SSH
* Mais seguro que login por senha

---

### ✅ Separação de sub-redes

* Uso de sub-rede pública para acesso web
* Boa prática de arquitetura em nuvem

---

### ✅ Firewall via Security Group

* Controle de tráfego de entrada e saída
* Apenas portas necessárias abertas

---

## ⚠️ 3. Riscos Identificados

### ❌ HTTP sem criptografia

* O acesso está em HTTP (porta 80)
* Dados não são criptografados

🔧 **Solução recomendada:**

* Implementar HTTPS com certificado SSL (ex: Let's Encrypt)

---

### ❌ Porta 80 aberta para todos

* Necessário para acesso público
* Porém aumenta superfície de ataque

---

### ❌ Servidor padrão Apache

* Página inicial simples
* Pode expor informações básicas do servidor

---

## 🔧 4. Melhorias Recomendadas

* Implementar HTTPS (porta 443)
* Utilizar Nginx ou proxy reverso
* Configurar firewall adicional (ex: UFW)
* Monitoramento com CloudWatch
* Atualizações automáticas de segurança

---

## 🔍 5. Boas Práticas

* Não expor chave `.pem`
* Não usar root
* Manter sistema atualizado
* Monitorar acessos

---

## ✅ Conclusão

A aplicação possui uma configuração básica de segurança adequada para fins acadêmicos, mas pode ser aprimorada para ambientes de produção.

---
