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

# Đặt VPC ID hoặc tìm VPC ID theo tên
VPC_NAME="anthos-VPC"

echo_info "Getting VPC ID for VPC with name: $VPC_NAME..."
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query "Vpcs[].VpcId" --output text)

if [ -z "$VPC_ID" ]; then
    echo_error "VPC ID not found for VPC with name $VPC_NAME. Exiting."
    exit 1
fi
echo

# 1. Xoá Instances
echo_info "Getting Instance IDs in VPC: $VPC_ID..."
INSTANCE_IDS=$(aws ec2 describe-instances \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Reservations[].Instances[].InstanceId" --output text)

if [ -n "$INSTANCE_IDS" ]; then
    echo_info "Terminating Instances..."
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo_info "Terminating Instance: $INSTANCE_ID"
        aws ec2 terminate-instances --instance-ids $INSTANCE_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully terminated Instance: $INSTANCE_ID"
        else
            echo_error "Failed to terminate Instance: $INSTANCE_ID"
        fi
    done
else
    echo_info "No Instances found in VPC: $VPC_ID."
fi
echo

# 2. Xoá Elastic IPs
echo_info "Getting Elastic IPs..."
ALLOCATION_IDS=$(aws ec2 describe-addresses \
  --filters "Name=domain,Values=vpc" \
  --query "Addresses[].AllocationId" --output text)

if [ -n "$ALLOCATION_IDS" ]; then
    echo_info "Releasing Elastic IPs..."
    for ALLOCATION_ID in $ALLOCATION_IDS; do
        echo_info "Releasing Elastic IP: $ALLOCATION_ID"
        aws ec2 release-address --allocation-id $ALLOCATION_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully released Elastic IP: $ALLOCATION_ID"
        else
            echo_error "Failed to release Elastic IP: $ALLOCATION_ID"
        fi
    done
else
    echo_info "No Elastic IPs found."
fi
echo

# 3. Xoá Load Balancers
echo_info "Getting Load Balancers..."
LOAD_BALANCERS=$(aws elb describe-load-balancers \
  --query "LoadBalancerDescriptions[].LoadBalancerName" --output text)

if [ -n "$LOAD_BALANCERS" ]; then
    echo_info "Deleting Load Balancers..."
    for LB_NAME in $LOAD_BALANCERS; do
        echo_info "Deleting Load Balancer: $LB_NAME"
        aws elb delete-load-balancer --load-balancer-name $LB_NAME > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Load Balancer: $LB_NAME"
        else
            echo_error "Failed to delete Load Balancer: $LB_NAME"
        fi
    done
else
    echo_info "No Load Balancers found."
fi
echo

# 4. Xoá Security Groups
echo_info "Getting Security Groups..."
SECURITY_GROUPS=$(aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "SecurityGroups[].GroupId" --output text)

if [ -n "$SECURITY_GROUPS" ]; then
    echo_info "Deleting Security Groups..."
    for SG_ID in $SECURITY_GROUPS; do
        echo_info "Deleting Security Group: $SG_ID"
        aws ec2 delete-security-group --group-id $SG_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Security Group: $SG_ID"
        else
            echo_error "Failed to delete Security Group: $SG_ID"
        fi
    done
else
    echo_info "No Security Groups found."
fi
echo

# 5. Xoá Network ACLs
echo_info "Getting Network ACLs..."
NETWORK_ACLS=$(aws ec2 describe-network-acls \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "NetworkAcls[].NetworkAclId" --output text)

if [ -n "$NETWORK_ACLS" ]; then
    echo_info "Deleting Network ACLs..."
    for NACL_ID in $NETWORK_ACLS; do
        echo_info "Deleting Network ACL: $NACL_ID"
        aws ec2 delete-network-acl --network-acl-id $NACL_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Network ACL: $NACL_ID"
        else
            echo_error "Failed to delete Network ACL: $NACL_ID"
        fi
    done
else
    echo_info "No Network ACLs found."
fi
echo 

# 6. Xoá Subnets
echo_info "Getting Subnet IDs in VPC: $VPC_ID..."
SUBNET_IDS=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[].SubnetId" --output text)

if [ -n "$SUBNET_IDS" ]; then
    echo_info "Deleting Subnets..."
    for SUBNET_ID in $SUBNET_IDS; do
        echo_info "Deleting Subnet: $SUBNET_ID"
        aws ec2 delete-subnet --subnet-id $SUBNET_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Subnet: $SUBNET_ID"
        else
            echo_error "Failed to delete Subnet: $SUBNET_ID"
        fi
    done
else
    echo_info "No Subnets found in VPC: $VPC_ID."
fi
echo

# 7. Xoá Route Tables
echo_info "Getting Route Tables..."
ROUTE_TABLES=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "RouteTables[].RouteTableId" --output text)

if [ -n "$ROUTE_TABLES" ]; then
    echo_info "Deleting Route Tables..."
    for RT_ID in $ROUTE_TABLES; do
        echo_info "Deleting Route Table: $RT_ID"
        aws ec2 delete-route-table --route-table-id $RT_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Route Table: $RT_ID"
        else
            echo_error "Failed to delete Route Table: $RT_ID"
        fi
    done
else
    echo_info "No Route Tables found in VPC: $VPC_ID."
fi
echo

# 8. Xoá VPC Peering Connections
echo_info "Getting VPC Peering Connections..."
PEERING_CONNECTIONS=$(aws ec2 describe-vpc-peering-connections \
  --filters "Name=requester-vpc-info.vpc-id,Values=$VPC_ID" "Name=accepter-vpc-info.vpc-id,Values=$VPC_ID" \
  --query "VpcPeeringConnections[].VpcPeeringConnectionId" --output text)

if [ -n "$PEERING_CONNECTIONS" ]; then
    echo_info "Deleting VPC Peering Connections..."
    for PEERING_ID in $PEERING_CONNECTIONS; do
        echo_info "Deleting VPC Peering Connection: $PEERING_ID"
        aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PEERING_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted VPC Peering Connection: $PEERING_ID"
        else
            echo_error "Failed to delete VPC Peering Connection: $PEERING_ID"
        fi
    done
else
    echo_info "No VPC Peering Connections found."
fi
echo

# 9. Xoá Internet Gateways
echo_info "Getting Internet Gateways..."
INTERNET_GATEWAYS=$(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[].InternetGatewayId" --output text)

if [ -n "$INTERNET_GATEWAYS" ]; then
    echo_info "Detaching and Deleting Internet Gateways..."
    for IGW_ID in $INTERNET_GATEWAYS; do
        echo_info "Detaching Internet Gateway: $IGW_ID"
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully detached Internet Gateway: $IGW_ID"
        else
            echo_error "Failed to detach Internet Gateway: $IGW_ID"
        fi

        echo_info "Deleting Internet Gateway: $IGW_ID"
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted Internet Gateway: $IGW_ID"
        else
            echo_error "Failed to delete Internet Gateway: $IGW_ID"
        fi
    done
else
    echo_info "No Internet Gateways found."
fi
echo

# 10. Xoá NAT Gateways
echo_info "Getting NAT Gateways..."
NAT_GATEWAYS=$(aws ec2 describe-nat-gateways \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "NatGateways[].NatGatewayId" --output text)

if [ -n "$NAT_GATEWAYS" ]; then
    echo_info "Deleting NAT Gateways..."
    for NAT_ID in $NAT_GATEWAYS; do
        echo_info "Deleting NAT Gateway: $NAT_ID"
        aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted NAT Gateway: $NAT_ID"
        else
            echo_error "Failed to delete NAT Gateway: $NAT_ID"
        fi
    done
else
    echo_info "No NAT Gateways found."
fi
echo

# 11. Xoá VPN Connections
echo_info "Getting VPN Connections..."
VPN_CONNECTIONS=$(aws ec2 describe-vpn-connections \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "VpnConnections[].VpnConnectionId" --output text)

if [ -n "$VPN_CONNECTIONS" ]; then
    echo_info "Deleting VPN Connections..."
    for VPN_ID in $VPN_CONNECTIONS; do
        echo_info "Deleting VPN Connection: $VPN_ID"
        aws ec2 delete-vpn-connection --vpn-connection-id $VPN_ID > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo_success "Successfully deleted VPN Connection: $VPN_ID"
        else
            echo_error "Failed to delete VPN Connection: $VPN_ID"
        fi
    done
else
    echo_info "No VPN Connections found."
fi
echo

# 12. Xoá VPC
echo_info "Deleting VPC: $VPC_ID..."
aws ec2 delete-vpc --vpc-id $VPC_ID > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo_success "Successfully deleted VPC: $VPC_ID"
else
    echo_error "Failed to delete VPC: $VPC_ID"
fi
