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


dnf install maven -y    &>>$LOG_FILE
VALIDATE  $? "install maven"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop    &>>$LOG_FILE
VALIDATE  $? "add user to system"


rm -rf /app/*   &>>$LOG_FILE
VALIDATE  $? "removeing app dir in /"

mkdir -p /app    &>>$LOG_FILE

VALIDATE  $? "create app dir"


curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip    &>>$LOG_FILE
cd /app    &>>$LOG_FILE
unzip /tmp/shipping.zip    &>>$LOG_FILE
VALIDATE  $? "download and unzip the code"



cd /app      &>>$LOG_FILE
mvn clean package     &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar     &>>$LOG_FILE
VALIDATE  $? "build the package"



cp  $SCRIPT_DIR/shipping.service  /etc/systemd/system/shipping.service       &>>$LOG_FILE
VALIDATE  $? "cpying the shipping service file"
 
  
systemctl daemon-reload     &>>$LOG_FILE

VALIDATE  $? "daemon-reload "



systemctl enable shipping      &>>$LOG_FILE
systemctl start shipping        &>>$LOG_FILE
VALIDATE  $? "enable and start shipping"



############        Mysql-clinet           #################

dnf install mysql -y      &>>$LOG_FILE



mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql


mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql 



mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql



systemctl restart shipping     &>>$LOG_FILE