#!/bin/bash

#######################################################
# Author : Abdul Moiz
# Date : 29 Nov
# Vsersion : v1
# Description : This script will report the AWS resource usage
######################################################

# AWS S3
# AWS EC2
# AWS Lambda
# AWS IAM USERS

LOG_DIR="/home/abdul-moiz/aws_reports"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/aws-report-$(date +'%Y-%m-%d_%H%M%S').log"

echo "=== AWS Resource Report Started at $(date) ===" >> "$LOG_FILE"

echo "List aws s3 bucket"
/usr/local/bin/aws s3 ls >> "$LOG_FILE" 2>&1

echo "Describe aws ec2 instances"
/usr/local/bin/aws ec2 describe-instances >> "$LOG_FILE" 2>&1

echo "List aws lambda functions"
/usr/local/bin/aws lambda list-functions >> "$LOG_FILE" 2>&1

echo "List aws iam users"
/usr/local/bin/aws iam list-users | /usr/bin/jq '.Users[] .UserName' | tee -a "$LOG_FILE"


echo "=== AWS Resource Report Finished at $(date) ===" >> "$LOG_FILE"