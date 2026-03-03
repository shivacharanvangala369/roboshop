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

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE  $? "copying mongorepo"


dnf install mongodb-org -y   &>>$LOG_FILE
VALIDATE  $? "Installing mongodb"

systemctl enable mongod      &>>$LOG_FILE
VALIDATE  $? "enable mongodb"

systemctl start mongod      &>>$LOG_FILE
VALIDATE  $? "start mongodb"

sed -i "s/127.0.0.1/0.0.0.0/g"   /etc/mongod.conf  &>>$LOG_FILE
VALIDATE  $? "Update listen address"

systemctl restart mongod     &>>$LOG_FILE
VALIDATE  $? "restart mongodb"