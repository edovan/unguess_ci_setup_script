#!/bin/bash
# <========== GENERAL SETUP  ==========> #
_CUSTOMER_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $CUSTOMER_NAME)
_PRODUCT_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $PRODUCT_NAME)
_AWS_REGION=$(tr '[:upper:]' '[:lower:]'  <<<  $AWS_REGION)
# <====================================> #

### TODO:
# 1. Create ECR repository 
# 2. Create Results Bucket
# 3. Create Execution Cluster 

## 1. Create ECR entry 
### Login to ECR 
aws ecr get-login-password --region ${_AWS_REGION} | docker login --username AWS --password-stdin 005876332748.dkr.ecr.${_AWS_REGION}.amazonaws.com
### Create Repository
aws ecr create-repository \
    --repository-name e2e_${_CUSTOMER_NAME}_${_PRODUCT_NAME} \
    --image-scanning-configuration scanOnPush=true \
    --region ${_AWS_REGION}

## 2. Create S3 Bucket 
aws s3 mb s3://e2e-${_CUSTOMER_NAME}-${_PRODUCT_NAME}_repo

## 3. Create Execution Cluster 
aws ecs create-cluster --cluster-name e2e-${_CUSTOMER_NAME}-${_PRODUCT_NAME}
