# Security Analysis

## Medidas Implementadas

* Acesso SSH restrito ao IP do administrador
* Porta HTTP liberada para acesso público
* Porta 3000 liberada apenas para testes do backend
* Banco de dados não exposto publicamente
* Uso de subnet privada

---

## Princípio do Menor Privilégio

As regras de segurança foram configuradas para permitir apenas o tráfego necessário:

* SSH apenas para um IP específico
* Backend acessível apenas para testes
* Banco restrito à aplicação

---

## Possíveis Melhorias

* Implementar HTTPS (SSL)
* Configurar WAF
* Uso de bastion host
* Remover acesso direto ao backend

---
