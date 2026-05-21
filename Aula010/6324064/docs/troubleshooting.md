# Troubleshooting - TF10 Migracao para RDS

## 1) Erro de autenticacao no AWS CLI
Sintoma:
- `Unable to locate credentials` ou `AccessDenied`

Causa provavel:
- AWS CLI sem credencial configurada ou role sem permissao

Correcao:
1. Executar `aws configure`.
2. Validar identidade com `aws sts get-caller-identity`.
3. Garantir permissoes para RDS, EC2, CloudWatch e SNS.

## 2) Nao conecta no RDS (timeout)
Sintoma:
- `could not connect to server: Connection timed out`

Causa provavel:
- Security Group ou subnet sem rota/permitido

Correcao:
1. Confirmar porta 5432 liberada apenas para origem autorizada.
2. Confirmar RDS em subnet privada com rota valida.
3. Testar conectividade via host autorizado.

## 3) Falha ao importar schema/dados
Sintoma:
- Erros de permissao ou objeto ja existente

Causa provavel:
- Ordem de import incorreta ou dump inconsistente

Correcao:
1. Rodar novamente na ordem: schema -> dados.
2. Garantir `--no-owner --no-privileges` no dump.
3. Verificar role usada no RDS.

## 4) Divergencia na validacao
Sintoma:
- `validate-migration.sh` retorna divergencias

Causa provavel:
- Tabelas sem migracao completa, falha parcial ou alteracoes durante a janela

Correcao:
1. Revisar o relatorio emitido pelo `validate-migration.sh` no terminal/log salvo.
2. Reexecutar migracao em janela controlada.
3. Bloquear escrita no banco origem durante o corte.

## 5) Custo acima do esperado
Sintoma:
- Fatura AWS acima do estimado

Causa provavel:
- Instancia acima do necessario, snapshots acumulados, backups longos

Correcao:
1. Revisar classe de instancia e storage.
2. Limpar snapshots manuais antigos.
3. Ajustar retention de backup.
4. Executar `migration/cleanup.sh` ao final.

## 6) Performance pior que local
Sintoma:
- Latencia maior e throughput menor no RDS

Causa provavel:
- Indices ausentes, pool de conexao inadequado, classe pequena

Correcao:
1. Rodar queries de diagnostico em `monitoring/performance-queries.sql`.
2. Criar indices para queries criticas.
3. Ajustar pool de conexoes da aplicacao.
4. Considerar upgrade de instancia.

## 7) Falha no failover
Sintoma:
- Aplicacao nao reconecta apos failover

Causa provavel:
- Aplicacao presa em conexao antiga ou timeout curto

Correcao:
1. Usar endpoint oficial da instancia RDS.
2. Configurar retry com backoff exponencial na conexao.
3. Ajustar timeout de conexao na aplicacao.

## 8) Comandos shell no Windows
Sintoma:
- Scripts `.sh` nao executam no PowerShell puro

Causa provavel:
- Ambiente sem Git Bash/WSL

Correcao:
1. Executar scripts via Git Bash, WSL ou shell Linux equivalente.
2. Alternativa: traduzir para `.ps1` mantendo a mesma logica.
