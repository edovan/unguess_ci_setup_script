#!/bin/bash
# <========== GENERAL SETUP  ==========> #
set -x
_CUSTOMER_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $CUSTOMER_NAME)
_PRODUCT_NAME=$(tr '[:upper:]' '[:lower:]'  <<<  $PRODUCT_NAME)
_AWS_REGION=$(tr '[:upper:]' '[:lower:]'  <<<  $AWS_REGION)

_AWS_REGION=$(tr '[:upper:]' '[:lower:]'  <<<  $AWS_REGION)

## Slack channel: QA_SQUAD_NOTIFICATION
_SLACK_WEB_HOOK=https://hooks.slack.com/services/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
_SLACK_WEB_HOOK=$SLACK_WEB_HOOK

## Folder and path
ALLURE_RESULTS=allure-results
ALLURE_REPORT=allure-report
WEB_ALLURE_FOLDER=allure
WEB_REPORT_FOLDER=latest
CURRENT_REPORT_FOLDER=$(date '+%Y%m%d%H%M%S')

## URL ROOT
URL_REPORT=https://$BUCKET.s3.$REGION.amazonaws.com/$WEB_REPORT_FOLDER
URL_DASHBOARD=https://$BUCKET.s3.$REGION.amazonaws.com/$WEB_ALLURE_FOLDER

# <====================================> #


# <======   RUN SPECIFIC SETUP  =======> #
# NONE!!!
# <====================================> #


# <======   GENERAL PARAM SETUP  =======> #
ENV_RUN=_default_
BROWSER_RUN=Chrome
CUSTOMER_NAME=$_CUSTOMER_NAME
PRODUCT_NAME=$_PRODUCT_NAME
# <====================================> #

# switch to right directory If running in Docker 
cd robot

# print all parameters
echo Your container pass me theese arguments: "$@"


# cleanup 
rm -rf ./results/*
rm -rf ./$ALLURE_RESULTS/*
rm -rf ./$ALLURE_REPORT/*

# check robot version
robot --version
# rfbrowser init 

# notify test starting 
MSG="{\"text\":\":robot_face: [_ *$ENV_RUN* _][_ $PRODUCT_NAME _] Starting tests execution :rocket: \"}"
curl -X POST -H 'Content-type: application/json' --data "$MSG" $_SLACK_WEB_HOOK
# run test
robot -L trace -v headless:True \
      -d ./results  \
      --listener "RobotNotifications;$_SLACK_WEB_HOOK;summary"  \
      --listener "allure_robotframework;$ALLURE_RESULTS" \
      -v ENV:$ENV_RUN \
      "$@"

# Upload results 
echo ===> Upload Results <===
## cleaning latest report
aws s3 rm --recursive s3://$BUCKET/$WEB_REPORT_FOLDER/$PRODUCT_NAME/
## upload on latest 
aws s3 sync ./results s3://$BUCKET/$WEB_REPORT_FOLDER/$PRODUCT_NAME/
## upload on current timestamp folder
aws s3 cp s3://$BUCKET/$WEB_REPORT_FOLDER/$PRODUCT_NAME/ s3://$BUCKET/$PRODUCT_NAME/$CURRENT_REPORT_FOLDER/ --recursive
## retrieve execution history 
aws s3 sync s3://$BUCKET/$WEB_ALLURE_FOLDER/$PRODUCT_NAME/history  ./$ALLURE_RESULTS/history
## set report variables
echo Product=$PRODUCT_NAME >> ./$ALLURE_RESULTS/environment.properties
echo Environment=$ENV_RUN >> ./$ALLURE_RESULTS/environment.properties
echo Browser=$BROWSER_RUN >> ./$ALLURE_RESULTS/environment.properties
## generate report 
allure generate ./$ALLURE_RESULTS --clean -o $ALLURE_REPORT
## cleaning old dashboard 
aws s3 rm --recursive s3://$BUCKET/$WEB_ALLURE_FOLDER/$PRODUCT_NAME/
## upload new dashboard 
aws s3 sync ./$ALLURE_REPORT s3://$BUCKET/$WEB_ALLURE_FOLDER/$PRODUCT_NAME/


# Send Notification
MSG="{\"text\":\":robot_face: [_ *$ENV_RUN* _][_ $PRODUCT_NAME _] *Report*: <$URL_REPORT/$PRODUCT_NAME/report.html|here>\"}"
curl -X POST -H 'Content-type: application/json' --data "$MSG" $_SLACK_WEB_HOOK
MSG="{\"text\":\":robot_face: [_ *$ENV_RUN* _][_ $PRODUCT_NAME _]*Dashboard*: <$URL_DASHBOARD/$PRODUCT_NAME/index.html|here>\"}"
curl -X POST -H 'Content-type: application/json' --data "$MSG" $_SLACK_WEB_HOOK

