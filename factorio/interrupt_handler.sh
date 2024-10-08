#!/bin/bash

# gameserver item
BASE_DIR=__BASE_DIR_REPLACEME__

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

while sleep 5; do
    # check response to metadata api
    HTTP_CODE=$(curl -H "X-aws-ec2-metadata-token: ${TOKEN}" -s -w %{http_code} -o /dev/null http://169.254.169.254/latest/meta-data/spot/instance-action)
    # token has expired so get a new one
    if [[ "${HTTP_CODE}" -eq 401 ]] ; then
        TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 30"`
    # 200OK means there is a spot instance action, per spot request, so handle it
    elif [[ "${HTTP_CODE}" -eq 200 ]] ; then
        # copy the latest autosave out
        cd ${BASE_DIR}
        ./fctrserver st
        ./manage.sh BACKUP_LATEST
        ./manage.sh BACKUP_SETTINGS
        exit
    fi
done