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



dnf install python3 gcc python3-devel -y  &>>$LOG_FILE
VALIDATE  $? "install python3"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin  --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding roboshop as system user"
else
    echo -e "Roboshop user alraedy exist...$Y SKIPPLNG $N"
fi

rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"

mkdir -p /app 


curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip   &>>$LOG_FILE
cd /app 
unzip /tmp/payment.zip  &>>$LOG_FILE
VALIDATE  $? "downloading and zip the code"


cd /app   &>>$LOG_FILE
pip3 install -r requirements.txt  &>>$LOG_FILE
VALIDATE  $? "pip3 install"


cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE  $? "copying service files"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE  $? "daemon-reload"

systemctl enable payment   &>>$LOG_FILE
systemctl start payment  &>>$LOG_FILE
VALIDATE  $? "enable and start mysql"