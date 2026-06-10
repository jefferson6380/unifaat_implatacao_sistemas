# Troubleshooting

## Problema: Não acessa o site

* Verificar Security Group (porta 80 aberta)
* Verificar se container está rodando

---

## Problema: Backend não responde

* Verificar porta 3000
* Testar com:

```bash
curl localhost:3000/health
```

---

## Problema: Erro SSH

* Verificar IP liberado
* Verificar permissões da chave

---

## Problema: Containers não sobem

```bash
docker compose up
```

Ver logs:

```bash
docker logs <container>
```

---
