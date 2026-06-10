# Guia de Troubleshooting

Consulte este guia caso encontre erros durante a execução dos scripts ou no acesso à aplicação.

## 1. Erros no `create-infrastructure.sh`

### Instância `t3.micro` não suportada na Zona de Disponibilidade (AZ)
**Erro:** `An error occurred (Unsupported) when calling the RunInstances operation... in your requested Availability Zone (us-east-1e).`
- **Causa:** A AWS não disponibiliza o tipo `t3.micro` em todas as zonas de `us-east-1`.
- **Solução:** O script foi fixado para usar `us-east-1a` (`--availability-zone ${REGION}a`). Caso persistir, tente mudar para `b` ou `c`.

### Erro de Dependência na Exclusão (VPC ou Security Group)
**Erro:** `DependencyViolation: resource sg-xxx has a dependent object`
- **Causa:** Ocorre quando se tenta deletar um Security Group que ainda está em uso ou que possui regras referenciando outros grupos.
- **Solução:** Utilize o script de emergência `./force-cleanup.sh`. Ele limpa todas as regras de ingress/egress antes de deletar os grupos, resolvendo dependências circulares.

### Script "Travado" com um símbolo de `:`
- **Causa:** A AWS CLI está usando um paginador (pager) para mostrar saídas longas.
- **Solução:** Pressione a tecla **`q`** para sair e continuar o script. (Os scripts atuais já possuem `export AWS_PAGER=""` para evitar isso).

## 2. Acesso SSH

### Timeout ao conectar
- **Causa:** Seu IP público pode ter mudado desde que você criou a infraestrutura.
- **Solução:** Vá ao Console AWS > Security Groups > `tf09-portfolio-web-sg` e atualize a regra da porta 22 para o seu IP atual ("My IP").

### Permissão de Chave Incorreta (Windows/WSL)
**Erro:** `Permissions 0777 for '...pem' are too open`
- **Solução:** Mova a chave para o seu diretório `~/.ssh/` dentro do WSL e rode `chmod 400 ~/.ssh/tf09-portfolio-key.pem`.

## 3. Docker e Aplicação

### Containers não iniciam ou Banco de Dados falha
- **Causa:** Erro de sintaxe no `.env` ou o banco de dados ainda está subindo.
- **Solução:** 
  1. Verifique o status com `sudo docker compose ps`.
  2. Verifique os logs com `sudo docker compose logs -f`.
  3. Tente reiniciar o stack: `sudo docker compose restart`.

### Mudanças no código não aparecem no site
- **Causa:** O Docker está usando uma imagem antiga em cache.
- **Solução:** Recompile as imagens com: `sudo docker compose up -d --build`.
