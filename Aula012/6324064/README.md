# TF012 - CI/CD Basico e Amazon ECR

## Identificacao
- RA: 6324064
- Disciplina: Implementacao de servidor e nuvem (cloud)
- Aula: 12

## Questao 1 - Conceitos de CI/CD
### a) CI (Continuous Integration)
CI tem como objetivo integrar mudancas de codigo com frequencia, executando build e testes automaticamente a cada commit para detectar erros cedo e manter a branch principal estavel.

### b) CD (Continuous Delivery/Deployment)
CD tem como objetivo automatizar a entrega do artefato gerado no CI (imagem/container), promovendo para ambientes de teste e/ou producao com processo reproduzivel, rapido e com baixo risco.

## Questao 2 - Ferramentas de Pipeline (CI)
Tres exemplos de ferramentas/servicos para CI:
1. Jenkins
2. GitHub Actions
3. AWS CodeBuild

## Questao 3 - Amazon ECR
### a) Vantagem principal do ECR
Para aplicacao privada, o ECR oferece integracao nativa com IAM (controle de acesso por usuario/role/policy), mantendo imagens privadas com seguranca e governanca alinhadas ao ambiente AWS.

### b) ECR e regionalidade
O ECR e um servico regional.

Formato padrao do URI do repositorio:
`<aws_account_id>.dkr.ecr.<region>.amazonaws.com/<repository_name>`

Exemplo:
`123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app-repo`

## Questao 4 - Processo de Push (ordem correta)
1. Passo de autenticacao (AWS CLI + Docker CLI)
   - `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account_id>.dkr.ecr.<region>.amazonaws.com`
2. Passo de tagging (Docker CLI)
   - `docker tag <imagem_local>:<tag> <account_id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`
3. Passo de upload/push (Docker CLI)
   - `docker push <account_id>.dkr.ecr.<region>.amazonaws.com/<repo>:<tag>`

## Questao 5 - Simulacao com valores do enunciado
Parametros fornecidos:
- AWS_ACCOUNT_ID: `123456789012`
- AWS_REGION: `us-east-1`
- REPO_NAME: `web-app-repo`
- Imagem local: `web-app:v1`

### a) Criacao do repositorio
`aws ecr create-repository --repository-name web-app-repo --region us-east-1`

### b) Autenticacao (login Docker)
`aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com`

### c) Tagging da imagem
`docker tag web-app:v1 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app-repo:v1`

### d) Push final
`docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/web-app-repo:v1`

## Questao 6 - Evidencias praticas da execucao do Lab012

### Parte 1 - Preparacao e Configuracao
1. `evidencias/01-aws-configure-list.txt`
   - Saida do `aws configure list`.
2. `evidencias/02-ecr-login.txt`
   - Comando de login no ECR e retorno `Login Succeeded`.
3. `evidencias/03-docker-build.txt`
   - Build da imagem `web-app-v1:v1.0` concluido com sucesso.

### Parte 2 - Registro e Push da imagem
1. `evidencias/04-ecr-create-describe.txt`
   - Criacao e descricao do repositorio ECR `web-app-repo-6324064`.
2. `evidencias/05-docker-tag.txt`
   - Tag da imagem local com URI completo do ECR.
3. `evidencias/06-docker-images-filtered.txt`
   - Verificacao da imagem local marcada com o URI do ECR.
4. `evidencias/07-docker-push.txt`
   - Push da imagem para o ECR com upload dos layers e digest final.

### Parte 3 - Verificacao remota e bonus EKS
1. `evidencias/08-ecr-describe-images.txt`
   - Verificacao remota da imagem no ECR exibindo tag `v1.0`.
2. Bonus EKS
   - Nao executado neste TF.

### Parte 4 - Comandos executados
- Arquivo: `comandos-lab012.txt`
- Contem a lista completa dos comandos utilizados na execucao do lab.

## Observacoes de execucao
- O Docker daemon inicialmente estava inativo no host; apos iniciar o Docker Desktop, o fluxo build/tag/push foi executado normalmente.
- A regiao utilizada foi `us-east-1`.
- Repositorio utilizado para evidencias reais: `506609161223.dkr.ecr.us-east-1.amazonaws.com/web-app-repo-6324064`.
- Apos a coleta das evidencias, o repositorio ECR de laboratorio foi removido para evitar custo de armazenamento.
