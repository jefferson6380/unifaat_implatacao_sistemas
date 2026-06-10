# Guia de Implementação e Deploy de Instância EC2

Este guia detalha o processo completo para provisionar um servidor virtual (EC2) na AWS via linha de comando, preparar os pré-requisitos e colocar a aplicação no ar.

## Fase 1: Adquirindo os Pré-requisitos

Para criar uma máquina virtual na AWS, você não pode simplesmente "ligar um servidor". Você precisa de permissões, chaves de acesso e uma rede configurada.

### 1. Autenticação na AWS (AWS CLI)
O terminal precisa estar conectado à sua conta AWS.
* Gere uma "Access Key" no painel da AWS (canto superior direito > Security Credentials > Create access key).
* No seu terminal Linux/WSL, digite `aws configure`.
* Cole a Access Key, a Secret Key e defina a região como `us-east-1`.

### 2. Chave de Acesso SSH (.pem)
A AWS não usa senhas para login em servidores Linux; ela usa criptografia de chaves.
* Crie a chave pelo terminal: `aws ec2 create-key-pair --key-name Lab009-KeyPair --query 'KeyMaterial' --output text > Lab009-KeyPair.pem`
* Proteja a chave localmente contra leitura não autorizada: `chmod 400 Lab009-KeyPair.pem`

### 3. Infraestrutura de Rede Base
O servidor precisa de um "terreno" (VPC), uma "rua" (Subnet) e um "segurança" (Security Group).
* Execute o script de criação: `./infrastructure/create-infrastructure.sh`
* Anote o **ID da Subnet Pública** (ex: `subnet-xxxx`) e o **ID do Security Group** (ex: `sg-xxxx`) que o script gerar na tela.



## Fase 2: Passo a Passo Principal (Subindo a EC2)

Com as chaves, a rede e a segurança prontas, podemos lançar o servidor.

### Passo 1: Executar o comando Run-Instances
No terminal, utilize o comando abaixo. Ele diz à AWS exatamente qual sistema operacional usar, o tamanho da máquina, em qual rede colocá-la e quem é o segurança da porta. 

**Atenção:** Como este é o servidor web que ficará acessível na internet, você deve usar obrigatoriamente o ID da **Subnet Pública**. (Substitua os IDs em maiúsculo pelos seus).

```bash
aws ec2 run-instances \
    --image-id resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 \
    --count 1 \
    --instance-type t3.micro \
    --key-name Lab009-KeyPair \
    --security-group-ids sg-058a0ed2bcdf71125 \
    --subnet-id COLOQUE_O_ID_DA_SUBNET_PUBLICA_AQUI \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TF09-WebServer}]'
```

### Passo 2: Descobrir o IP da Máquina
Acesse o painel da AWS no navegador. Vá em **EC2 > Instances**. Selecione a máquina recém-criada (`TF09-WebServer`) e copie o endereço numérico listado em **Public IPv4 address**. (Guarde este número, pois você vai precisar dele no próximo passo!).

### Passo 3: Conectar via SSH
No seu terminal local, use a chave que criamos na Fase 1 para entrar na máquina. Substitua o termo `SEU_IP_PUBLICO` no comando abaixo pelo endereço IP que você acabou de copiar no passo anterior:

```bash
ssh -i Lab009-KeyPair.pem ec2-user@SEU_IP_PUBLICO
```

### Passo 4: Instalar Docker e Fazer o Deploy
Dentro do servidor EC2 (repare que o seu terminal agora mostrará algo como `[ec2-user@ip-...]`), atualize o sistema e instale as ferramentas necessárias:

```bash
sudo yum update -y

sudo yum install -y docker git

sudo systemctl start docker

sudo curl -L "[https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname](https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname) -s)-$(uname -m)" -o /usr/bin/docker-compose

sudo chmod +x /usr/bin/docker-compose
```

Agora, você precisa trazer os arquivos do seu projeto para dentro do servidor usando o Git e entrar na pasta da aplicação para iniciar os containers:

### 1. Clone o seu repositório do GitHub (Substitua pela URL do seu Fork)
```bash
git clone COLOQUE_A_URL_DO_SEU_REPOSITORIO_AQUI
```

### 2. Entre na pasta da aplicação (Ajuste o caminho se necessário)
```bash
cd unifaat_implatacao_sistemas/Aula009/6324518/application
```

### 3. Suba a aplicação com o Docker Compose
```bash
sudo docker-compose up -d --build
```

Sua aplicação agora está rodando na nuvem! Acesse o IP público da sua EC2 no navegador para validar o portfólio.