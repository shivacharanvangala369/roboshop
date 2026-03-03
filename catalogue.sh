#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[34m"

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




dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE  $? "module disable nodejs"

dnf module enable nodejs:20 -y   &>>$LOG_FILE
VALIDATE  $? "module enable nodejs"


dnf install nodejs -y    &>>$LOG_FILE
VALIDATE  $? "install nodejs"
 


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin  --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding roboshop as system user"
else
    echo -e "Roboshop user alraedy exist...$Y SKIPPLNG $N"
fi

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"

mkdir -p /app  &>>$LOG_FILE
VALIDATE  $? "creating app dir in / "


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>>$LOG_FILE
VALIDATE  $? "downloading source code"

cd /app                      &>>$LOG_FILE
unzip /tmp/catalogue.zip    &>>$LOG_FILE
VALIDATE  $? "unzipping source code"



cd /app           &>>$LOG_FILE
npm install      &>>$LOG_FILE
VALIDATE  $? "installing dependencies"



systemctl daemon-reload    &>>$LOG_FILE
VALIDATE  $? "daemon-reload "

systemctl enable catalogue    &>>$LOG_FILE
systemctl start catalogue     &>>$LOG_FILE
VALIDATE  $? "enable and starting catalouge services"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE  
VALIDATE  $? "copying mongorepo"



dnf install mongodb-mongosh -y    &>>$LOG_FILE
VALIDATE  $? "installing mogo-client"


mongosh --host mongodb.devcops.online </app/db/master-data.js    &>>$LOG_FILE
VALIDATE  $? "Load Master Data"

mongosh --host mongodb.devcops.online   &>>$LOG_FILE
VALIDATE  $? "check data is loaded into mongodb or not Connect to MongoDB"