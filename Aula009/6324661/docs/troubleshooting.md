# Guia de Solução de Problemas (Troubleshooting)

Este documento descreve os problemas mais comuns encontrados durante o laboratório e suas respectivas soluções.

### Erro 1: Permission denied (publickey) ao acessar o SSH
**Sintoma:** O terminal exibe `Warning: Identity file Lab009-KeyPair.pem not accessible: No such file or directory`.
**Causa:** O terminal está sendo executado em uma pasta diferente daquela onde a chave `.pem` foi salva.
**Solução:** Mova o arquivo da chave para a pasta atual ou navegue até a pasta correta usando o comando `cd`. Verifique com `ls` se o arquivo está listado antes de conectar.

### Erro 2: docker-compose command not found
**Sintoma:** Ao tentar subir a aplicação na instância EC2, o sistema não reconhece o Docker Compose.
**Causa:** O binário não foi baixado para o diretório de executáveis do sistema (`/usr/bin/`) ou não possui permissão de execução.
**Solução:** Execute o download com o `curl` apontando para `/usr/bin/docker-compose` e aplique `sudo chmod +x /usr/bin/docker-compose`.

### Erro 3: compose build requires buildx 0.17.0 or later
**Sintoma:** O Docker se recusa a construir a imagem no Amazon Linux 2.
**Causa:** A versão mais recente do `docker-compose` exige o plugin `buildx`, que não é nativo dessa versão do sistema operacional.
**Solução:** Instale uma versão clássica e estável do Docker Compose (ex: v2.12.2) ou adicione a variável de ambiente `DOCKER_BUILDKIT=0` antes do comando de build.