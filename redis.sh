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



dnf module disable redis -y    &>>$LOG_FILE
dnf module enable redis:7 -y   &>>$LOG_FILE
dnf install redis -y           &>>$LOG_FILE
VALIDATE  $? " enable and install redis"


sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode/ c protected-mode no" /etc/redis/redis.conf 
VALIDATE  $? "Allowing remote connection"

systemctl enable redis   &>>$LOG_FILE
systemctl start redis    &>>$LOG_FILE
VALIDATE  $? "enable and start redis"