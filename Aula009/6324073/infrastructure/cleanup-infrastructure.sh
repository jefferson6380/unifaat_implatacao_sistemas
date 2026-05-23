#!/bin/bash

# This script would normally use IDs stores in a state file or retrieved by tags
# For this lab, assume we use the name tags to identify resources

PROJECT_NAME="TF09-6324073"
REGION="us-east-1"

echo "Starting cleanup for $PROJECT_NAME..."

# 1. Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$PROJECT_NAME-vpc" --query 'Vpcs[0].VpcId' --output text)

if [ "$VPC_ID" != "None" ]; then
    echo "Deleting resources in VPC: $VPC_ID"
    # This is a simplified cleanup. In production, use Terraform or CloudFormation
    # for robust cleanup.
    echo "Cleanup manual steps required for complete deletion (Instances -> SGs -> Subnets -> IGW -> VPC)"
else
    echo "No VPC found with name $PROJECT_NAME-vpc"
fi
