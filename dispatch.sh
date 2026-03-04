#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[34m"
SCRIPT_DIR=$PWD

if [ $USERID -ne 0 ]; then
     echo -e "$R please run this script using root user" | tee -a $LOG_FILE
     exit 1
fi

mkdir -p $LOG_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2... $R FAILURE" | tee -a $LOG_FILE
    else
        echo -e "$2... $G SUCCESS" | tee -a $LOG_FILE
    fi
}

dnf install golang -y  &>>$LOG_FILE
VALIDATE  $? "install golang"


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin  --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding roboshop as system user"
else
    echo -e "Roboshop user alraedy exist...$Y SKIPPLNG $N"
fi

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"

mkdir -p /app   &>>$LOG_FILE
VALIDATE  $? "create a ap dir"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip  &>>$LOG_FILE
cd /app 

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"


unzip /tmp/dispatch.zip  &>>$LOG_FILE
VALIDATE  $? "download unzip the code"
 
cd /app   &>>$LOG_FILE
go mod init dispatch   &>>$LOG_FILE
go get    &>>$LOG_FILE
go build  &>>$LOG_FILE
VALIDATE  $? "go mod init, get, build"


cp   $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service 
VALIDATE  $? "copy service files"



systemctl daemon-reload &>>$LOG_FILE
VALIDATE  $? "daemon reload"


systemctl enable dispatch &>>$LOG_FILE
systemctl start dispatch &>>$LOG_FILE
VALIDATE  $? "enable and start dispatch"