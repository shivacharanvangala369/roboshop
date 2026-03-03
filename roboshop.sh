#!/bin/bash


SG_ID="sg-0643d1da123417a9c"
AMI_ID="ami-0220d79f3f480ecf5"
ZONE_ID="Z10145393TKZKPDMJT8U0"
DOMAIN_NAME="devcops.online"

for instance in $@
do 
    INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro" \
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].IntanceId' \
    --output text )
   
    if [ $instance == "frontend" ]; then
      IP=$(
        aws ec2 describe-instance \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PublicIpAddress' \
        --output text )

      RECORD_NAME="$DOMAIN_NAME"
    else
      IP=$(
        aws ec2 describe-instance \
        --instance-ids $INSTANCE_ID \
        --query 'Reservations[].Instances[].PrivateIpAddress' \
        --output text )

      RECORD_NAME="$instance.$DOMAIN_NAME"
        
      fi
      
      echo "IP Address: $IP"

      aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch '

      {
        "Comment": "Updating record",
        "Changes": [
          {
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "'$RECORD_NAME'",
              "Type": "A",
              "TTL": 1,
              "ResourceRecords": [
                {
                  "Value": "'$IP'"
                }
              ]
            }
          }
        ]
      }
      '

echo "record updated for $instance"

done
