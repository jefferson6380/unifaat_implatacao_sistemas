# 🛠️ Troubleshooting Guide

Este documento descreve problemas comuns encontrados durante o deploy e suas soluções.

---

## ❌ 1. Erro: Não conecta via SSH

### Mensagem:

```id="0h7xwe"
Connection timed out
```

### ✔ Solução:

* Verificar se a porta **22 (SSH)** está liberada
* Conferir se o IP está correto no Security Group

---

## ❌ 2. Erro: Permission denied (publickey)

### ✔ Solução:

* Verificar se está usando a chave `.pem` correta
* Conferir permissões da chave (no Linux: `chmod 400`)

---

## ❌ 3. Erro: Site não abre

### Mensagem:

```id="sn0k3i"
ERR_CONNECTION_TIMED_OUT
```

### ✔ Solução:

* Liberar porta **80 (HTTP)** no Security Group
* Verificar se o Apache está rodando:

```bash id="63b53i"
sudo systemctl status httpd
```

---

## ❌ 4. Erro: Apache não inicia

### ✔ Solução:

```bash id="1a8m34"
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

## ❌ 5. Erro: git: command not found

### ✔ Solução:

```bash id="q8cbte"
sudo yum install git -y
```

---

## ❌ 6. Erro no git clone

### Mensagem:

```id="0l1k5d"
RPC failed / early EOF
```

### ✔ Solução:

```bash id="6kwtq4"
git clone --depth 1 URL_DO_REPOSITORIO
```

---

## ❌ 7. Arquivos não aparecem no site

### ✔ Solução:

* Verificar se os arquivos foram copiados:

```bash id="v8k2v0"
ls /var/www/html/
```

* Copiar novamente:

```bash id="9m2kdl"
sudo cp -r * /var/www/html/
```

---

## ❌ 8. Erro ao usar chmod no Windows

### ✔ Explicação:

* O comando `chmod` não funciona no CMD

### ✔ Solução:

* Usar Git Bash ou ignorar no Windows

---

## ❌ 9. Conexão SSH cai (Connection reset)

### ✔ Possíveis causas:

* Instância reiniciando
* Problema de rede

---

## ❌ 10. Caminho não encontrado (cd)

### ✔ Solução:

* Verificar se o diretório existe:

```bash id="r9zj8k"
ls
```

---

## ✅ Conclusão

A maioria dos erros está relacionada a:

* Configuração de rede
* Permissões
* Comandos incorretos

Todos foram resolvidos com ajustes simples.

---
