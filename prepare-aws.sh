#Create VPC
aws --region ap-southeast-1 ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc, Tags=[{Key=Name,Value=anthos-VPC}]'

#Save your VPC ID to an environment variable and enable AWS-provided DNS support for the VPC:
VPC_ID=$(aws ec2 describe-vpcs \
  --filters 'Name=tag:Name,Values=anthos-VPC' \
  --query "Vpcs[].VpcId" --output text)
aws ec2 modify-vpc-attribute --enable-dns-hostnames --vpc-id $VPC_ID
aws ec2 modify-vpc-attribute --enable-dns-support --vpc-id $VPC_ID

#Create private subnets
   aws ec2 create-subnet \
     --availability-zone AWS_ZONE_1 \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.1.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet1}]'
   aws ec2 create-subnet \
     --availability-zone AWS_ZONE_2 \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.2.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet2}]'
   aws ec2 create-subnet \
     --availability-zone AWS_ZONE_3 \
     --vpc-id $VPC_ID \
     --cidr-block 10.0.3.0/24 \
     --tag-specifications 'ResourceType=subnet, Tags=[{Key=Name,Value=anthos-PrivateSubnet3}]'

#

