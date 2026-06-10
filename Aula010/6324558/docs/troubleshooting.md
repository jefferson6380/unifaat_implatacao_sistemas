# Troubleshooting

## psql: command not found

Instale o PostgreSQL Client Tools em https://www.enterprisedb.com/downloads/postgres-postgresql-downloads marcando apenas **Command Line Tools**. Adicione ao PATH no Git Bash:

```bash
export PATH=$PATH:"/c/Program Files/PostgreSQL/18/bin"
```

## Connection refused na porta 5432

Seu IP não está liberado no Security Group do RDS. Descubra seu IP e adicione uma regra de entrada:

```bash
curl -4 ifconfig.me
```

No Console AWS: RDS → Security Group → Inbound Rules → Add Rule → PostgreSQL → seu IP/32.

## Dump gerado com 669 bytes (vazio)

O banco local estava sem dados. Verifique se o container subiu corretamente e os dados foram carregados:

```bash
docker exec -t postgres-erp psql -U postgres -d northwind -c "SELECT COUNT(*) FROM orders;"
```

## Instância RDS não encontrada no script

O RDS ainda está em criação. Aguarde o status **Available** no Console AWS antes de rodar o migrate-data.sh.

## Password authentication failed

A senha do banco local é `postgres`. A senha do RDS é a definida no arquivo `.env` na variável `DB_PASSWORD`.