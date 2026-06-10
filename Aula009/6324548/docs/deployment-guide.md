# Deployment Guide

## Pré-requisitos
- Ter o AWS CLI configurado em sua máquina local (`aws configure`).
- CLI do Git e bash (Linux/WSL).
- Permissões adequadas na AWS (IAM user com EC2/VPC permissions).

## Passo a Passo

### 1. Criar a Infraestrutura
Acesse a pasta `infrastructure/` e dê permissão de execução ao script:
```bash
chmod +x create-infrastructure.sh
./create-infrastructure.sh
```
Ao final da execução, anote o **IP Público da EC2** e confirme a criação do arquivo `TF09-Portfolio-Key.pem`.

### 2. Acessar Servidor e Fazer o Deploy Manual Inicial
Conecte-se na EC2 utilizando a chave e o IP público:
```bash
ssh -i "TF09-Portfolio-Key.pem" ubuntu@<IP_PUBLICO_DA_EC2>
```

Dentro da ec2, realize os processos a seguir:
```bash
git clone https://github.com/SEU_USUARIO/NOME_DO_REPO.git
cd NOME_DO_REPO/Aula009/6324548/application

# Rodar Docker Compose
sudo docker-compose up -d
```

### 3. Comandos de Verificação
Após rodar o docker-compose, você pode validar o status dos conteineres rodando os seguintes comandos na EC2:
```bash
sudo docker ps
sudo docker logs application_backend_1
```
Acesse `http://<IP_PUBLICO_DA_EC2>` em seu navegador.

### 4. Limpeza
Para evitar custos desnecessários, quando terminar a avaliação do trabalho, destrua os recursos usando:
```bash
chmod +x cleanup-infrastructure.sh
./cleanup-infrastructure.sh
```
