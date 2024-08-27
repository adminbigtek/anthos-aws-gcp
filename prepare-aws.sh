#!/bin/bash

# Định nghĩa màu sắc
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Hàm để hiển thị thông báo với màu sắc
function echo_success {
    echo -e "${GREEN}✅ $1${NC}"
}

function echo_error {
    echo -e "${RED}❌ $1${NC}"
}

function echo_info {
    echo -e "${YELLOW}🔄 $1${NC}"
}

#Create VPC
echo_info "Create AWS VPC..."
aws --region ap-southeast-1 ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc, Tags=[{Key=Name,Value=anthos-VPC}]' > /dev/null 2>&1
    

#Save your VPC ID to an environment variable and enable AWS-provided DNS support for the VPC:
echo "Save your VPC ID to an environment variable and enable AWS-provided DNS support for the VPC..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters 'Name=tag:Name,Values=anthos-VPC' \
  --query "Vpcs[].VpcId" --output text)
aws ec2 modify-vpc-attribute --enable-dns-hostnames --vpc-id $VPC_ID > /dev/null 2>&1
aws ec2 modify-vpc-attribute --enable-dns-support --vpc-id $VPC_ID > /dev/null 2>&1

#Create private subnets
echo "Create private subnets..."
   aws ec2 create-subnet \
     --availability-zone ap-southeast-1a \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.1.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet1}]' > /dev/null 2>&1
   aws ec2 create-subnet \
     --availability-zone ap-southeast-1b \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.2.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet2}]' > /dev/null 2>&1
   aws ec2 create-subnet \
     --availability-zone ap-southeast-1c \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.3.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet3}]' > /dev/null 2>&1
     
#Create public subnets
echo "Create public subnets..."
aws ec2 create-subnet \
  --availability-zone ap-southeast-1a \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.101.0/24 \
  --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PublicSubnet1}]' > /dev/null 2>&1
aws ec2 create-subnet \
  --availability-zone ap-southeast-1b \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.102.0/24 \
  --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PublicSubnet2}]' > /dev/null 2>&1
aws ec2 create-subnet \
  --availability-zone ap-southeast-1c \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.103.0/24 \
  --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PublicSubnet3}]' > /dev/null 2>&1

#Mark the subnets as public:
echo "Mark the subnets as public..."
PUBLIC_SUBNET_ID_1=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PublicSubnet1' \
  --query "Subnets[].SubnetId" --output text)
PUBLIC_SUBNET_ID_2=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PublicSubnet2' \
  --query "Subnets[].SubnetId" --output text)
PUBLIC_SUBNET_ID_3=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PublicSubnet3' \
  --query "Subnets[].SubnetId" --output text)
aws ec2 modify-subnet-attribute \
  --map-public-ip-on-launch \
  --subnet-id $PUBLIC_SUBNET_ID_1 > /dev/null 2>&1
aws ec2 modify-subnet-attribute \
  --map-public-ip-on-launch \
  --subnet-id $PUBLIC_SUBNET_ID_2 > /dev/null 2>&1
aws ec2 modify-subnet-attribute \
  --map-public-ip-on-launch \
  --subnet-id $PUBLIC_SUBNET_ID_3 > /dev/null 2>&1

#Create an internet gateway
echo "Create an internet gateway..."
aws --region ap-southeast-1  ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway, Tags=[{Key=Name,Value=anthos-InternetGateway}]' > /dev/null 2>&1

#Attach the internet gateway to your VPC
echo "Attach the internet gateway to your VPC..."
INTERNET_GW_ID=$(aws ec2 describe-internet-gateways \
  --filters 'Name=tag:Name,Values=anthos-InternetGateway' \
  --query "InternetGateways[].InternetGatewayId" --output text)
aws ec2 attach-internet-gateway \
  --internet-gateway-id $INTERNET_GW_ID \
  --vpc-id $VPC_ID > /dev/null 2>&1

#Create a route table for each of the public subnets
echo "Create a route table for each of the public subnets..."
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PublicRouteTbl1}]' > /dev/null 2>&1
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PublicRouteTbl2}]' > /dev/null 2>&1
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PublicRouteTbl3}]' > /dev/null 2>&1

#Associate the public route tables with the public subnets
echo "Associate the public route tables with the public subnets..."
PUBLIC_ROUTE_TABLE_ID_1=$(aws ec2 describe-route-tables \
    --filters 'Name=tag:Name,Values=anthos-PublicRouteTbl1' \
    --query "RouteTables[].RouteTableId" --output text)
PUBLIC_ROUTE_TABLE_ID_2=$(aws ec2 describe-route-tables \
    --filters 'Name=tag:Name,Values=anthos-PublicRouteTbl2' \
    --query "RouteTables[].RouteTableId" --output text)
PUBLIC_ROUTE_TABLE_ID_3=$(aws ec2 describe-route-tables \
    --filters 'Name=tag:Name,Values=anthos-PublicRouteTbl3' \
    --query "RouteTables[].RouteTableId" --output text)
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID_1 \
  --subnet-id $PUBLIC_SUBNET_ID_1 > /dev/null 2>&1
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID_2 \
  --subnet-id $PUBLIC_SUBNET_ID_2 > /dev/null 2>&1
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_ROUTE_TABLE_ID_3 \
  --subnet-id $PUBLIC_SUBNET_ID_3 > /dev/null 2>&1

#Create default routes to the internet gateway
echo "Create default routes to the internet gateway..."
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID_1 \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GW_ID > /dev/null 2>&1
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID_2 \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GW_ID > /dev/null 2>&1
aws ec2 create-route --route-table-id $PUBLIC_ROUTE_TABLE_ID_3 \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $INTERNET_GW_ID > /dev/null 2>&1

#Allocate an Elastic IP (EIP) address for each NAT gateway
echo "Allocate an Elastic IP (EIP) address for each NAT gateway..."
aws ec2 allocate-address \
  --tag-specifications 'ResourceType=elastic-ip, Tags=[{Key=Name,Value=anthos-NatEip1}]' > /dev/null 2>&1
aws ec2 allocate-address \
  --tag-specifications 'ResourceType=elastic-ip, Tags=[{Key=Name,Value=anthos-NatEip2}]' > /dev/null 2>&1
aws ec2 allocate-address \
  --tag-specifications 'ResourceType=elastic-ip, Tags=[{Key=Name,Value=anthos-NatEip3}]' > /dev/null 2>&1

#Create a NAT gateway in each of the three public subnets:
echo "Create a NAT gateway in each of the three public subnets..."
   NAT_EIP_ALLOCATION_ID_1=$(aws ec2 describe-addresses \
     --filters 'Name=tag:Name,Values=anthos-NatEip1' \
     --query "Addresses[].AllocationId" --output text)
   NAT_EIP_ALLOCATION_ID_2=$(aws ec2 describe-addresses \
     --filters 'Name=tag:Name,Values=anthos-NatEip2' \
     --query "Addresses[].AllocationId" --output text)
   NAT_EIP_ALLOCATION_ID_3=$(aws ec2 describe-addresses \
     --filters 'Name=tag:Name,Values=anthos-NatEip3' \
     --query "Addresses[].AllocationId" --output text)
   aws ec2 create-nat-gateway \
     --allocation-id $NAT_EIP_ALLOCATION_ID_1 \
     --subnet-id $PUBLIC_SUBNET_ID_1 \
     --tag-specifications 'ResourceType=natgateway, Tags=[{Key=Name,Value=anthos-NatGateway1}]' > /dev/null 2>&1
   aws ec2 create-nat-gateway \
     --allocation-id $NAT_EIP_ALLOCATION_ID_2 \
     --subnet-id $PUBLIC_SUBNET_ID_2 \
     --tag-specifications 'ResourceType=natgateway, Tags=[{Key=Name,Value=anthos-NatGateway2}]' > /dev/null 2>&1
   aws ec2 create-nat-gateway \
     --allocation-id $NAT_EIP_ALLOCATION_ID_3 \
     --subnet-id $PUBLIC_SUBNET_ID_3 \
     --tag-specifications 'ResourceType=natgateway, Tags=[{Key=Name,Value=anthos-NatGateway3}]' > /dev/null 2>&1

#Create a route table for each private subnet
echo "Create a route table for each private subnet..."
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PrivateRouteTbl1}]' > /dev/null 2>&1
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PrivateRouteTbl2}]' > /dev/null 2>&1
aws ec2 create-route-table --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table, Tags=[{Key=Name,Value=anthos-PrivateRouteTbl3}]' > /dev/null 2>&1

#Associate the private route tables with the private subnets
echo "Associate the private route tables with the private subnets..."
PRIVATE_SUBNET_ID_1=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PrivateSubnet1' \
  --query "Subnets[].SubnetId" --output text)
PRIVATE_SUBNET_ID_2=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PrivateSubnet2' \
  --query "Subnets[].SubnetId" --output text)
PRIVATE_SUBNET_ID_3=$(aws ec2 describe-subnets \
  --filters 'Name=tag:Name,Values=anthos-PrivateSubnet3' \
  --query "Subnets[].SubnetId" --output text)
PRIVATE_ROUTE_TABLE_ID_1=$(aws ec2 describe-route-tables \
  --filters 'Name=tag:Name,Values=anthos-PrivateRouteTbl1' \
  --query "RouteTables[].RouteTableId" --output text)
PRIVATE_ROUTE_TABLE_ID_2=$(aws ec2 describe-route-tables \
  --filters 'Name=tag:Name,Values=anthos-PrivateRouteTbl2' \
  --query "RouteTables[].RouteTableId" --output text)
PRIVATE_ROUTE_TABLE_ID_3=$(aws ec2 describe-route-tables \
  --filters 'Name=tag:Name,Values=anthos-PrivateRouteTbl3' \
  --query "RouteTables[].RouteTableId" --output text)
aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID_1 \
  --subnet-id $PRIVATE_SUBNET_ID_1 > /dev/null 2>&1
aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID_2 \
  --subnet-id $PRIVATE_SUBNET_ID_2 > /dev/null 2>&1
aws ec2 associate-route-table --route-table-id $PRIVATE_ROUTE_TABLE_ID_3 \
  --subnet-id $PRIVATE_SUBNET_ID_3 > /dev/null 2>&1

#Create the default routes to NAT gateways
echo "Create the default routes to NAT gateways..."
NAT_GW_ID_1=$(aws ec2 describe-nat-gateways \
 --filter 'Name=tag:Name,Values=anthos-NatGateway1' \
 --query "NatGateways[].NatGatewayId" --output text)
NAT_GW_ID_2=$(aws ec2 describe-nat-gateways \
 --filter 'Name=tag:Name,Values=anthos-NatGateway2' \
 --query "NatGateways[].NatGatewayId" --output text)
NAT_GW_ID_3=$(aws ec2 describe-nat-gateways \
 --filter 'Name=tag:Name,Values=anthos-NatGateway3' \
 --query "NatGateways[].NatGatewayId" --output text)
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID_1  \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GW_ID_1 > /dev/null 2>&1
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID_2  \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GW_ID_2 > /dev/null 2>&1
aws ec2 create-route --route-table-id $PRIVATE_ROUTE_TABLE_ID_3 \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $NAT_GW_ID_3 > /dev/null 2>&1

#Tag the public subnets with kubernetes.io/role/elb
echo "Tag the public subnets with kubernetes.io/role/elb..."
aws ec2 create-tags \
  --resources $PUBLIC_SUBNET_ID_1 \
  --tags Key=kubernetes.io/role/elb,Value=1 > /dev/null 2>&1
aws ec2 create-tags \
  --resources $PUBLIC_SUBNET_ID_2 \
  --tags Key=kubernetes.io/role/elb,Value=1 > /dev/null 2>&1
aws ec2 create-tags \
  --resources $PUBLIC_SUBNET_ID_3 \
  --tags Key=kubernetes.io/role/elb,Value=1 > /dev/null 2>&1

#Tag the private subnets with kubernetes.io/role/internal-elb
echo "Tag the private subnets with kubernetes.io/role/internal-elb..."
aws ec2 create-tags \
  --resources $PRIVATE_SUBNET_ID_1 \
  --tags Key=kubernetes.io/role/internal-elb,Value=1 > /dev/null 2>&1
aws ec2 create-tags \
  --resources $PRIVATE_SUBNET_ID_2 \
  --tags Key=kubernetes.io/role/internal-elb,Value=1 > /dev/null 2>&1
aws ec2 create-tags \
  --resources $PRIVATE_SUBNET_ID_3 \
  --tags Key=kubernetes.io/role/internal-elb,Value=1 > /dev/null 2>&1
  

  


  








