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


dnf module disable nginx -y       &>>$LOG_FILE
dnf module enable nginx:1.24 -y    &>>$LOG_FILE
dnf install nginx -y                &>>$LOG_FILE
VALIDATE  $? "enableing nginx 1.24 and insatlling"

systemctl enable nginx           &>>$LOG_FILE
systemctl start nginx             &>>$LOG_FILE
VALIDATE  $? "enable and start nginx"

rm -rf /usr/share/nginx/html/*         &>>$LOG_FILE
VALIDATE  $? "removing content in html"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip    &>>$LOG_FILE
VALIDATE  $? "downloading frontend code"


cd /usr/share/nginx/html    &>>$LOG_FILE
unzip /tmp/frontend.zip      &>>$LOG_FILE
VALIDATE  $? "unzipping frontend"


cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf      &>>$LOG_FILE
VALIDATE  $? "copying conf file"


systemctl restart nginx       &>>$LOG_FILE
VALIDATE  $? "restart  nginx"
