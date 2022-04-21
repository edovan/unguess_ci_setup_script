#!/bin/bash
set -x
while getopts c:p:r: flag
do
    case "${flag}" in
        c) customerName=${OPTARG};;
        p) productName=${OPTARG};;
        r) regionName=${OPTARG};;
    esac
done
echo "Customer Name: $customerName";
echo "Product Name: $productName";
echo "Regione Name: $regionName";
 
# <========== GENERAL SETUP  ==========> #
_CUSTOMER_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $customerName)
_PRODUCT_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $productName)
_AWS_REGION=$(tr '[:upper:]' '[:lower:]'  <<<  $regionName)
# <====================================> #


echo "Customer Name: $_CUSTOMER_NAME";
echo "Product Name: $_PRODUCT_NAME";
echo "Regione Name: $_AWS_REGION";
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
    --region $_AWS_REGION

## 2. Create S3 Bucket 
aws s3 mb s3://e2e-${_CUSTOMER_NAME}-${_PRODUCT_NAME}-repo  --region $_AWS_REGION

## 3. Create Execution Cluster 
aws ecs create-cluster --cluster-name e2e-$_CUSTOMER_NAME-$_PRODUCT_NAME  --region $_AWS_REGION
