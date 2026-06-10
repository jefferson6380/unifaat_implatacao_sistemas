## Respostas:

### 1:
A - CI é a entrega contínua de codgo funcional. O codgo é automaticamente testado para evitar bugs.

b - CD é quando o códgo que foi testado pelo CI é enviado para a area de testes do codgo para ser de fato enviado para produção

### 2:

Podemos automarizar o CI com o uso do GitHub Actions para altomatizar os testes,

### 3:

a - O docker é utilizado em embiente de dezenvolvimento, ja o ECR é um serviço seguro AWS para armazenar as imagens e pronta para integrar com outros serviços da propria aws.

b - ERC é um serviço global, no entanto devemos escolher uma região específica para usarmos o ECR, isso o limita por região. A URI tem o padão 


### 4:

Autenticação - Criamos uma imagem dockefile e criamos variaveis com ID e região do usuario da AWS, e uma variavel para a imagem docker.
Criamos um repositório ECR passanso as variaveis de usuario aws.
Conectamos o docker com o serviço aws.

Tagging - conectamos a imagem com o ECR por meio das variaveis criadas

Upload - com tudo conectado podemos enviar a imagem para o ECR

### 5:



