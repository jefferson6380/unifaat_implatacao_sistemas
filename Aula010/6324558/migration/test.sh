#!/bin/bash
# validate-aws-real.sh - Validação Técnica via Dry-Run

source "$(dirname "$0")/../.env"

echo "----------------------------------------------------------"
echo "EXECUTANDO VALIDAÇÃO FUNCIONAL (DRY-RUN)"
echo "----------------------------------------------------------"

# 1. Validação de Credenciais e Identidade
# Se o seu token estiver expirado, o script morre aqui.
echo -n "[1/3] Testando Autenticação AWS... "
aws sts get-caller-identity --query "Arn" --output text > /dev/null
if [ $? -eq 0 ]; then
    echo "CONECTADO."
else
    echo "FALHA: Credenciais inválidas."
    exit 1
fi

# 2. Teste de Criação de Security Group (Dry-Run)
# Valida: Permissão IAM, Sintaxe, VPC ID e Conectividade.
echo -n "[2/3] Validando criação de Security Group... "
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)

aws ec2 create-security-group \
    --dry-run \
    --group-name "TESTE-SINTAXE-$(date +%s)" \
    --description "Teste de Dry Run" \
    --vpc-id "$VPC_ID" 2>&1 | grep -q "DryRunOperation"

if [ $? -eq 0 ]; then
    echo "SINTAXE OK."
else
    echo "FALHA: Erro de permissão ou parâmetro."
    exit 1
fi

# 3. Teste de Autorização de Regra (Dry-Run)
# Valida: Formato do CIDR (IP) e porta.
#!/bin/bash
# debug-ingress.sh - Localizando o erro exato no Ingress

source "$(dirname "$0")/../.env"

MY_IP=$(curl -s -4 https://checkip.amazonaws.com)

echo "Testando comando de Ingress com Dry-Run para capturar o erro real:"
echo "----------------------------------------------------------"

# Executa sem esconder o erro para você ver o que a AWS responde
aws ec2 authorize-security-group-ingress \
    --dry-run \
    --group-id sg-01234567 \
    --protocol tcp \
    --port 5432 \
    --cidr "$MY_IP/32"

echo "----------------------------------------------------------"