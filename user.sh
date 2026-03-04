#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[34m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.devcops.online

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

mkdir -p /app  &>>$LOG_FILE
VALIDATE  $? "creating app dir in / "


curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip   &>>$LOG_FILE
VALIDATE  $? "downloading source code"

cd /app                      &>>$LOG_FILE

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"

unzip /tmp/user.zip    &>>$LOG_FILE
VALIDATE  $? "unzipping source code"



cd /app           &>>$LOG_FILE
npm install      &>>$LOG_FILE
VALIDATE  $? "installing dependencies"


cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE  $? "copying user service"

systemctl daemon-reload    &>>$LOG_FILE
VALIDATE  $? "daemon-reload"

systemctl enable user    &>>$LOG_FILE
systemctl start user     &>>$LOG_FILE
VALIDATE  $? "enable and starting catalouge services"

