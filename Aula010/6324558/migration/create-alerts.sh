#!/bin/bash
# setup-alerts.sh - Configuração de alertas do CloudWatch

# Criando o alarme de CPU alta (> 80%)
aws cloudwatch put-metric-alarm \
    --alarm-name "RDS-High-CPU-6324558" \
    --alarm-description "Alerta de seguranca para uso de CPU" \
    --metric-name CPUUtilization \
    --namespace AWS/RDS \
    --statistic Average \
    --period 300 \
    --threshold 80.0 \
    --comparison-operator GreaterThanThreshold \
    --dimensions Name=DBInstanceIdentifier,Value=unifaat-db-6324558 \
    --evaluation-periods 1 \
    --unit Percent

# Exportando a configuração para o arquivo exigido no TF
aws cloudwatch describe-alarms --alarm-name-prefix "RDS" > ./6324558/monitoring/alerts-config.json

echo "Alertas configurados e arquivo alerts-config.json gerado!"