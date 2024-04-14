#!/bin/bash
URL="${1}.example.com"
AWS_REGION=us-east-1

LOAD_BALANCER_NAME="chaos-alb"

LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?LoadBalancerName=='$LOAD_BALANCER_NAME'].LoadBalancerArn" --output text)

# Set the DNS name
LB_DNS_NAME=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?LoadBalancerArn=='$LOAD_BALANCER_ARN'].DNSName" --output text)

# Set the header value
header_value=$URL

# Perform the HTTP request and capture the response
response=$(curl -H "Host: $header_value" $LB_DNS_NAME)

# Print the response
echo "$response"
