#!/bin/bash
# create-infrastructure.sh
set -e

# Configuration variables
PROJECT_NAME="tf09-portfolio"
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"
AMI_ID="ami-04b70fa74e45c3917" # Ubuntu 24.04 LTS us-east-1 (Free Tier eligible)
INSTANCE_TYPE="t3.micro"

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$PROJECT_NAME-vpc --region $REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}" --region $REGION

echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --region $REGION --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$PROJECT_NAME-igw --region $REGION
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION

echo "Creating Public Subnet..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=Name,Value=$PROJECT_NAME-public-subnet --region $REGION
aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch --region $REGION

echo "Creating Private Subnet..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_CIDR --availability-zone ${REGION}a --region $REGION --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PRIVATE_SUBNET_ID --tags Key=Name,Value=$PROJECT_NAME-private-subnet --region $REGION

echo "Creating Route Table for Public Subnet..."
PUBLIC_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PUBLIC_RT_ID --tags Key=Name,Value=$PROJECT_NAME-public-rt --region $REGION
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION > /dev/null
aws ec2 associate-route-table --subnet-id $PUBLIC_SUBNET_ID --route-table-id $PUBLIC_RT_ID --region $REGION > /dev/null

echo "Creating Route Table for Private Subnet..."
PRIVATE_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --region $REGION --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PRIVATE_RT_ID --tags Key=Name,Value=$PROJECT_NAME-private-rt --region $REGION
aws ec2 associate-route-table --subnet-id $PRIVATE_SUBNET_ID --route-table-id $PRIVATE_RT_ID --region $REGION > /dev/null

echo "Getting your public IP for SSH access..."
MY_IP=$(curl -s ifconfig.me)
if [ -z "$MY_IP" ]; then
    MY_IP="0.0.0.0/0"
    echo "Warning: Could not get public IP. Using 0.0.0.0/0 for SSH (NOT recommended)."
else
    MY_IP="${MY_IP}/32"
    echo "Your IP is $MY_IP"
fi

echo "Creating Web Security Group..."
WEB_SG_ID=$(aws ec2 create-security-group --group-name $PROJECT_NAME-web-sg --description "Security group for web server" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
aws ec2 create-tags --resources $WEB_SG_ID --tags Key=Name,Value=$PROJECT_NAME-web-sg --region $REGION
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr $MY_IP --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION > /dev/null
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $REGION > /dev/null

echo "Creating DB Security Group..."
DB_SG_ID=$(aws ec2 create-security-group --group-name $PROJECT_NAME-db-sg --description "Security group for database" --vpc-id $VPC_ID --region $REGION --query 'GroupId' --output text)
aws ec2 create-tags --resources $DB_SG_ID --tags Key=Name,Value=$PROJECT_NAME-db-sg --region $REGION
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 5432 --source-group $WEB_SG_ID --region $REGION > /dev/null

echo "Creating Key Pair..."
KEY_NAME="$PROJECT_NAME-key"
KEY_PATH="$HOME/.ssh/$KEY_NAME.pem"
mkdir -p "$HOME/.ssh"

if [ -f "$KEY_PATH" ]; then
    echo "Key pair $KEY_PATH already exists locally. Skipping creation."
else
    aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION 2>/dev/null || true
    rm -f "$KEY_PATH"
    aws ec2 create-key-pair --key-name $KEY_NAME --query 'KeyMaterial' --output text --region $REGION > "$KEY_PATH"
    chmod 400 "$KEY_PATH"
fi

echo "Creating user-data script..."
cat << 'EOF' > user-data.sh
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
curl -fsSL https://get.docker.com | sh
usermod -aG docker ubuntu
systemctl enable docker
EOF

echo "Launching EC2 Instance..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --user-data file://user-data.sh \
    --region $REGION \
    --query 'Instances[0].InstanceId' \
    --output text)

aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value=$PROJECT_NAME-web-server --region $REGION

echo "Waiting for instance to be running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION

PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $REGION)

echo "Saving resource IDs to state file..."
cat << EOF > infrastructure-state.txt
VPC_ID=$VPC_ID
IGW_ID=$IGW_ID
PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
PRIVATE_RT_ID=$PRIVATE_RT_ID
WEB_SG_ID=$WEB_SG_ID
DB_SG_ID=$DB_SG_ID
INSTANCE_ID=$INSTANCE_ID
KEY_NAME=$KEY_NAME
REGION=$REGION
EOF

echo "Waiting for SSH to become available..."
TIMEOUT=180
ELAPSED=0
while ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$KEY_PATH" ubuntu@$PUBLIC_IP "echo 'SSH is ready'" >/dev/null 2>&1; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: SSH timeout after ${TIMEOUT}s. Verifique o key pair e o security group."
        exit 1
    fi
done

echo "Waiting for the server to finish installing dependencies (Docker)..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$PUBLIC_IP "cloud-init status --wait" > /dev/null 2>&1 || true

TIMEOUT=300
ELAPSED=0
while ! ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$PUBLIC_IP "command -v docker" >/dev/null 2>&1; do
    sleep 5
    ELAPSED=$((ELAPSED + 5))
    if [ $ELAPSED -ge $TIMEOUT ]; then
        echo "ERROR: Docker não ficou disponível após ${TIMEOUT}s."
        exit 1
    fi
done

echo "Uploading application files..."
scp -o StrictHostKeyChecking=no -i "$KEY_PATH" -r ../application ubuntu@$PUBLIC_IP:~/

echo "Starting application with Docker..."
ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" ubuntu@$PUBLIC_IP "cd application && [ ! -f .env ] && cp .env.example .env || true && sudo docker compose up -d --build"

echo "=================================================="
echo "Infrastructure and Application deployed successfully!"
echo "Instance ID: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "SSH Command: ssh -i $KEY_PATH ubuntu@$PUBLIC_IP"
echo "Application URL: http://$PUBLIC_IP"
echo "=================================================="