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


cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo   &>>$LOG_FILE
VALIDATE  $? "copying service files"

dnf install rabbitmq-server -y  &>>$LOG_FILE
VALIDATE  $? "install rabbitmq"


systemctl enable rabbitmq-server &>>$LOG_FILE
systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE  $? "enable and start server"


rabbitmqctl add_user roboshop roboshop123    &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"     &>>$LOG_FILE
VALIDATE  $? "add and set permissions"
