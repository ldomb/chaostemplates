#!/bin/bash

AWS_REGION=us-east-1
INSTANCE1=i-0068d1415766ec8ca
INSTANCE2=i-0b759846ea8d40599
LOAD_BALANCER_NAME="chaos-alb"
CONTROLURL=control.example.com
EXPERIMENTURL=experiment.example.com


aws elbv2 create-load-balancer \
  --name chaos-alb \
  --subnets subnet-01ba995abdd5c14c0 subnet-0d555f8430d4313c2 \
  --security-groups sg-01144b770f3bc096a \
  --scheme internet-facing \
  --ip-address-type ipv4

LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query "LoadBalancers[?LoadBalancerName=='$LOAD_BALANCER_NAME'].LoadBalancerArn" --output text)


# Create the Control Group Target Group

aws elbv2 create-target-group --name control-group --protocol HTTP --port 80 --vpc-id vpc-03a3056e154dca626 --health-check-path /
TARGET_GROUP_CONTROL_ARN=$(aws elbv2 describe-target-groups --region "$AWS_REGION" --query "TargetGroups[?contains(TargetGroupName, 'control-group')].TargetGroupArn" --output text)

# Add the control group EC2 instances to the control group target group
aws elbv2 register-targets --target-group-arn $TARGET_GROUP_CONTROL_ARN --targets Id=$INSTANCE1

# Create the Experimental Group Target Group
aws elbv2 create-target-group --name experiment-group --protocol HTTP --port 80 --vpc-id vpc-03a3056e154dca626 --health-check-path /
TARGET_GROUP_EXPERIMENT_ARN=$(aws elbv2 describe-target-groups --region "$AWS_REGION" --query "TargetGroups[?contains(TargetGroupName, 'experiment-group')].TargetGroupArn" --output text)

# Add the control group EC2 instances to the control group target group
aws elbv2 register-targets --target-group-arn $TARGET_GROUP_EXPERIMENT_ARN --targets Id=$INSTANCE2

aws elbv2 create-listener \
    --load-balancer-arn $LOAD_BALANCER_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_CONTROL_ARN

# Create the Listener Rule for the Control Group (based on host header)
LISTENER_ARN=$(aws elbv2 describe-listeners --region "$AWS_REGION" --load-balancer-arn "$LOAD_BALANCER_ARN" --query "Listeners[0].ListenerArn" --output text)

aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --conditions Field=host-header,Values=$CONTROLURL \
  --priority 10 \
  --actions Type=forward,TargetGroupArn=$TARGET_GROUP_CONTROL_ARN

# Create the Listener Rule for the Experiment Group (based on host header)
aws elbv2 create-rule \
  --listener-arn $LISTENER_ARN \
  --conditions Field=host-header,Values=$EXPERIMENTURL \
  --priority 11\
  --actions Type=forward,TargetGroupArn=$TARGET_GROUP_EXPERIMENT_ARN
