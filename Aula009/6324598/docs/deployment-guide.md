# Guia de Deployment - TF09

Este guia fornece as instruções necessárias para realizar o deploy completo da infraestrutura e da aplicação na AWS.

## Pré-requisitos
Para garantir o sucesso do deployment, certifique-se de possuir:
- **Conta AWS**: Com permissões de administrador.
- **AWS CLI**: Instalado e devidamente configurado (`aws configure`).
- **Terminal Unix/Linux**: Recomendamos o uso do WSL2 no Windows ou Linux Nativo.
- **Conectividade**: Acesso à internet para download de pacotes e descoberta do IP público.

## Passo a passo detalhado

### 1. Preparação dos Scripts
Navegue até a pasta de infraestrutura e dê permissão de execução aos arquivos:
```bash
cd infrastructure
chmod +x *.sh
```

### 2. Execução do Provisionamento
Inicie o script principal. Ele criará toda a rede (VPC, Subnets, SG) e a máquina EC2:
```bash
./create-infrastructure.sh
```
*Aguarde a conclusão. O script irá configurar automaticamente o Docker e realizar o upload dos arquivos da aplicação.*

### 3. Acesso à Aplicação
Ao final da execução bem-sucedida, o script exibirá a **URL da Aplicação**. Copie o IP fornecido e abra no seu navegador:
`http://<IP_PUBLICO_FORNECIDO>`

## Comandos de verificação
Para validar se os serviços estão rodando corretamente dentro da instância AWS:

1. **Verificar Status dos Containers**:
   ```bash
   ssh -i ~/.ssh/tf09-portfolio-key.pem ubuntu@<IP_PUBLICO> "sudo docker compose ps"
   ```
2. **Checar Logs do Backend**:
   ```bash
   ssh -i ~/.ssh/tf09-portfolio-key.pem ubuntu@<IP_PUBLICO> "sudo docker compose logs backend"
   ```
3. **Teste de Health Check**:
   Acesse via navegador ou cURL: `http://<IP_PUBLICO>/health`

## Troubleshooting básico

- **Erro de Timeout no SSH**: Verifique se o seu IP público mudou. Atualize a regra de entrada no Security Group `tf09-portfolio-web-sg` na porta 22.
- **Instância não sobe**: Se houver erro de "Unsupported instance type", o script já está fixado para a zona `us-east-1a`, mas você pode tentar alterar para `us-east-1b` no script de criação.
- **Bolinha Vermelha no Frontend**: Indica que o backend não respondeu. Tente reiniciar os containers na EC2 com `sudo docker compose restart`.
- **Limpeza de Recursos**: Caso a exclusão padrão falhe, utilize o script de emergência: `./force-cleanup.sh`.

---
*Documentação de deployment para o projeto TF09 - UniFAAT.*
