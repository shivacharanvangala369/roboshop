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


curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>>$LOG_FILE
VALIDATE  $? "downloading source code"

cd /app                      &>>$LOG_FILE

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"


unzip /tmp/catalogue.zip    &>>$LOG_FILE
VALIDATE  $? "unzipping source code"



cd /app           &>>$LOG_FILE
npm install      &>>$LOG_FILE
VALIDATE  $? "installing dependencies"


cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service 
VALIDATE  $? "copying catalogue service"

systemctl daemon-reload    &>>$LOG_FILE
VALIDATE  $? "daemon-reload"

systemctl enable catalogue    &>>$LOG_FILE
systemctl start catalogue     &>>$LOG_FILE
VALIDATE  $? "enable and starting catalouge services"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  
VALIDATE  $? "copying mongorepo"



dnf install mongodb-mongosh -y    &>>$LOG_FILE
VALIDATE  $? "installing mogo-client"


#INDEX=$(mongosh --host $MONGODB_HOST  --quiet --eval 'db.getMongo().getDBNames().indexof("catalogue")')  &>>$LOG_FILE
#VALIDATE  $? "Load Master Data"

#if [ $INDEX -le 0 ]; then
#    mongosh --host $MONGODB_HOST </app/db/master-data.js   
#    VALIDATE  $? "Loading products"
#else
#    echo -e "Product is arelady loaded $Y... skipping $N"
#fi

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi



systemctl restart catalogue     &>>$LOG_FILE
VALIDATE  $? "restarting catalouge services"