# Troubleshooting

Em caso de problemas, consulte a lista abaixo:

### 1. Aplicação não inicia (Nginx Bad Gateway / Não conectado)
**Possível Causa:** O backend node em docker ou não instalou direito, ou a conexão bridge com docker compose obteve falha.
**Resolução:** 
- Acesse com SSH a EC2: `ssh -i seu-arquivo.pem ubuntu@IP`
- Valide os logs run do docker backend: `sudo docker logs application_backend_1`. Ajuste os erros conforme logs apontarem, reiniciando o bundle inteiro com `sudo docker-compose down && sudo docker-compose up -d`.

### 2. O Acesso SSH da ERRO DE TIMEOUT 
**Possível Causa:** A regra de IP automático pode pegar variação ISP. Ou seja, o IP público da sua conexão na hora do script foi diferente do IP público do servidor SSH que você tentou acessar, e o SG barrou a conexão.
**Resolução:**
- Verifique o seu IP via `curl http://checkip.amazonaws.com`
- Vá até a console web da AWS (EC2 -> Security Groups -> `TF09-Portfolio-Web-SG`) e clique em Editar Regras de Inbound. Altere a fonte da regra SSH porta 22 para o "Meu IP" da AWS Web Console UI e aplique.

### 3. Acesso negado com Chave .PEM
**Possível Causa:** As chaves PEM exigem que as permissões locais não sejam expostas abertamente a outros usuários.
**Resolução:** Ajuste as permissões localmente com: `chmod 400 TF09-Portfolio-Key.pem`.
