#!/bin/bash

#1. To create the GKE Multi-Cloud API service agent role
echo "To create the GKE Multi-Cloud API service agent role..."
PROJECT_ID="$(gcloud config get-value project)"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" \
    --format "value(projectNumber)")

aws iam create-role --role-name aws-iam-role \
    --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
        {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
            "Federated": "accounts.google.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
            "StringEquals": {
            "accounts.google.com:sub": "service-'$PROJECT_NUMBER'@gcp-sa-gkemulticloud.iam.gserviceaccount.com"
            }
      }
    }
  ]
}'

#2. Create scoped permissions (default)
echo "Create scoped permissions..."
aws iam create-policy --policy-name gke-multi-api-aws-iam \
  --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Action": [
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateLaunchTemplate",
        "ec2:CreateNetworkInterface",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteLaunchTemplate",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeInstances",
        "ec2:DescribeInternetGateways",
        "ec2:DescribeKeyPairs",
        "ec2:DescribeLaunchTemplates",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeSecurityGroupRules",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs",
        "ec2:GetConsoleOutput",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RunInstances",
        "iam:AWSServiceName",
        "iam:CreateServiceLinkedRole",
        "iam:GetInstanceProfile",
        "iam:PassRole",
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DeleteTags",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DisableMetricsCollection",
        "autoscaling:EnableMetricsCollection",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RemoveTags",
        "kms:DescribeKey",
        "kms:Encrypt",
        "kms:GenerateDataKeyWithoutPlaintext"
      ],
      "Resource": "*"
    }
  ]
}'

#Create a policy to control access to AWS IAM with the following command
echo "Create a policy to control access to AWS IAM with the following command..."
aws iam create-policy --policy-name gke-multi-api-aws-iam_iam \
  --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iam:CreateServiceLinkedRole"],
      "Resource": [
        "arn:aws:iam::*:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
      ],
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "autoscaling.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["iam:CreateServiceLinkedRole"],
      "Resource": [
        "arn:aws:iam::*:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing"
      ],
      "Condition": {
        "StringEquals": {
          "iam:AWSServiceName": "elasticloadbalancing.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": ["iam:PassRole"],
      "Resource": ["arn:aws:iam::*:role/*"],
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": "ec2.amazonaws.com"
        }
      }
    }
    ,
    {
      "Effect": "Allow",
      "Action": ["iam:GetInstanceProfile"],
      "Resource": ["arn:aws:iam::*:instance-profile/*"]
    }
  ]
}'

#Create a policy to control access to AWS EC2 Auto Scaling resources with the following command:
echo "Create a policy to control access to AWS EC2 Auto Scaling resources with the following command:..."
aws iam create-policy --policy-name gke-multi-api-aws-iam_autoscaling \
  --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["autoscaling:DescribeAutoScalingGroups"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:CreateOrUpdateTags"
      ],
      "Resource": [
        "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/gke-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/autoscale": "dev"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DeleteTags",
        "autoscaling:DisableMetricsCollection",
        "autoscaling:EnableMetricsCollection",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup"
      ],
      "Resource": [
        "arn:aws:autoscaling:*:*:autoScalingGroup:*:autoScalingGroupName/gke-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/autoscale": "dev"
        }
      }
    }
  ]
}'

#3. Create a policy to control access to AWS Elastic Load Balancer resources.
echo "Create a policy to control access to AWS Elastic Load Balancer resources...."
aws iam create-policy --policy-name gke-multi-api-aws-iam_elasticloadbalancing \
  --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:AddTags"
      ],
      "Resource": ["arn:aws:elasticloadbalancing:*:*:targetgroup/gke-*"],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/autoscale": "dev"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RemoveTags"
      ],
      "Resource": ["arn:aws:elasticloadbalancing:*:*:targetgroup/gke-*"],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/autoscale": "dev"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:AddTags"
      ],
      "Resource": [
        "arn:aws:elasticloadbalancing:*:*:listener/net/gke-*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/gke-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:RequestTag/autoscale": "dev"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:RemoveTags"
      ],
      "Resource": [
        "arn:aws:elasticloadbalancing:*:*:listener/net/gke-*",
        "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/gke-*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/autoscale": "dev"
        }
      }
    }
  ]
}'

#4. Create an AWS KMS key
# Thuc hien buoc nay de lay gia tri ARN de fill vao buoc 5
echo " Create an AWS KMS key..."
aws --region ap-southeast-1 kms create-key \
    --description "ksm-for-all"


#5. Create a policy to control access to AWS Key Management Service resources.
aws iam create-policy --policy-name gke-multi-api-aws-iam_kms \
  --policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["kms:DescribeKey"],
      "Resource": ["arn:aws:kms:*:*:key/*"]
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Encrypt"],
      "Resource": arn:aws:kms:ap-southeast-1:339713164391:key/3e5a1b1d-7566-413e-82f3-f8bd6acc3e1d
    },
    {
      "Effect": "Allow",
      "Action": ["kms:Encrypt"],
      "Resource": arn:aws:kms:ap-southeast-1:339713164391:key/3e5a1b1d-7566-413e-82f3-f8bd6acc3e1d
    },
    {
      "Effect": "Allow",
      "Action": ["kms:GenerateDataKeyWithoutPlaintext"],
      "Resource": arn:aws:kms:ap-southeast-1:339713164391:key/3e5a1b1d-7566-413e-82f3-f8bd6acc3e1d
    }
  ]
}'

#6. Attach policies to the GKE Multi-Cloud API role
# Lay thong tin output tu cac buoc tao policy tren de attach vao role 
aws iam attach-role-policy \
    --policy-arn arn:aws:iam::339713164391:policy/gke-multi-api-aws-iam \
    --role-name aws-iam-role

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::339713164391:policy/gke-multi-api-aws-iam_iam \
    --role-name aws-iam-role

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::339713164391:policy/gke-multi-api-aws-iam_autoscaling \
    --role-name aws-iam-role

aws iam attach-role-policy \
    --policy-arn arn:aws:iam::339713164391:policy/gke-multi-api-aws-iam_elasticloadbalancing \
    --role-name aws-iam-role

