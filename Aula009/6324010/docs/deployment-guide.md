# 🚀 Deployment Guide

Este documento descreve o processo de implantação da aplicação em uma instância EC2 na AWS.

---

## 📌 1. Criação da Instância EC2

A instância foi criada utilizando as seguintes configurações:

* Tipo: **t3.micro (Free Tier)**
* Sistema Operacional: **Amazon Linux 2023**
* Região: **sa-east-1 (São Paulo)**

📸
![EC2](images/Ec2.png)

---

## 🔐 2. Configuração de Segurança

Foi configurado um **Security Group** com as seguintes regras:

| Tipo | Porta | Origem    |
| ---- | ----- | --------- |
| SSH  | 22    | Meu IP    |
| HTTP | 80    | 0.0.0.0/0 |

---

## 💻 3. Conexão com a Instância

A conexão foi realizada via SSH utilizando uma chave `.pem`:

```bash id="8d3r1p"
ssh -i minha-chave.pem ec2-user@15.228.220.147
```

📸
![SSH](images/shh.png)

---

## 📦 4. Preparação do Ambiente

Atualização do sistema:

```bash id="x2k9v1"
sudo yum update -y
```

Instalação do Apache:

```bash id="y7m4p8"
sudo yum install httpd -y
```

Inicialização do serviço:

```bash id="m1c8z5"
sudo systemctl start httpd
sudo systemctl enable httpd
```

---

## 📥 5. Clonagem do Repositório

Instalação do Git:

```bash id="t4n2q6"
sudo yum install git -y
```

Clonagem do projeto:

```bash id="p9v6r3"
git clone https://github.com/Vini67/unifaat_implatacao_sistemas.git
```

📸
![Git Clone](images/gitclone.png)

---

## 📁 6. Navegação até o Projeto

```bash id="k7f2s9"
cd unifaat_implatacao_sistemas/Aula009/Paulo/application/frontend
```

---

## 🌐 7. Deploy da Aplicação

Cópia dos arquivos para o servidor web:

```bash id="d3w8n1"
sudo cp -r * /var/www/html/
```

Reinício do Apache:

```bash id="b6q2l4"
sudo systemctl restart httpd
```

---

## 🌍 8. Acesso à Aplicação

A aplicação pode ser acessada via navegador:

```id="j8r5u2"
http://15.228.220.147
```

📸
![Site](images/fotodosite.png)

---

## ⚠️ 9. Problemas Enfrentados

* Erro de conexão SSH → resolvido ajustando regras de segurança
* Site não carregava → porta 80 não liberada
* Git não instalado → resolvido com `sudo yum install git`

---

## 💰 10. Custos

O projeto foi executado utilizando o **Free Tier da AWS**, sem custos adicionais.

---

## ✅ Conclusão

O deploy foi realizado com sucesso utilizando:

* AWS EC2
* Apache HTTP Server
* GitHub

A aplicação está disponível publicamente via IP da instância.

---
