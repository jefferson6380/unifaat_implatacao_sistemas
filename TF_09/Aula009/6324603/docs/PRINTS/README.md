# Screenshots - TF09

Adicione aqui os screenshots após executar a infraestrutura na AWS:

## Screenshots Obrigatórios

| Arquivo | O que capturar |
|---------|---------------|
| `vpc-created.png` | AWS Console → VPC → Your VPCs → mostrar a VPC criada |
| `subnets.png` | AWS Console → VPC → Subnets → mostrar as 2 subnets |
| `security-groups.png` | AWS Console → EC2 → Security Groups → mostrar as regras |
| `ec2-running.png` | AWS Console → EC2 → Instances → mostrar instância running |
| `app-frontend.png` | Browser abrindo `http://<EC2_IP>` → página do portfólio |
| `health-check.png` | Browser ou terminal → `http://<EC2_IP>/api/health` |
| `api-projects.png` | Browser ou terminal → `http://<EC2_IP>/api/projects` |

## Como tirar os screenshots

1. Execute `./create-infrastructure.sh`
2. Acesse o AWS Console em https://console.aws.amazon.com
3. Navegue até cada serviço e tire o print
4. Salve os arquivos nesta pasta com os nomes acima
