# Deployment Guide

## Pré-requisitos

* Conta AWS
* Instância EC2 criada
* Docker instalado

---

## Passo a Passo

1. Conectar na EC2:

```bash
ssh -i tf09-key.pem ubuntu@IP
```

2. Atualizar sistema:

```bash
sudo apt update -y
```

3. Instalar Docker:

```bash
sudo apt install docker.io -y
```

4. Instalar Docker Compose:

```bash
sudo apt install docker-compose-plugin -y
```

5. Clonar repositório:

```bash
git clone https://github.com/vieira-dih/unifaat_implatacao_sistemas.git
```

6. Acessar pasta:

```bash
cd Aula009/6324639/application
```

7. Subir aplicação:

```bash
docker compose up -d
```

---

## Verificação

```bash
docker ps
```

Testar:

* http://IP
* http://IP:3000/health

---
