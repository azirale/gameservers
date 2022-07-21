#!/bin/bash

# we are expecting to run as GAME_USER -- must have sudo access
# we are expecting env vars of BRANCH;CONTEXT;GAME_USER;BUCKET_NAME;WEBROOT
# we are expecting to run on ubuntu latest with an NVME drive

# this is where everything is going to operate out of -- we do not touch anything else
BASE_DIR=/home/${GAME_USER}/ssd

# backups will go here
BUCKET_ROOT=s3://${BUCKET_NAME}/${CONTEXT}

# settings to update Route53 to point at this server
URLBASE=azirale.net
URLPREFIX=${CONTEXT}
URLTTL=60
R53ZONE=Z2YZPOMGKJCOKK


# keep a status file updated in case admin wants to watch as the script goes without all the other shell output guff
INIT_STATUS_PATH=/home/${GAME_USER}/INIT_STATUS
update_init_status() {
    echo "===================================================================="
    echo "$*"
    echo "===================================================================="
    echo "$*">${INIT_STATUS_PATH}
}


# update and install dependencies for the game, plus awscli for self-management
update_init_status DEPENDENCIES
sudo dpkg --add-architecture i386;
sudo apt update;
sudo apt install -yq awscli
sudo apt install -yq curl wget file tar bzip2 gzip unzip bsdmainutils python3 util-linux ca-certificates binutils bc jq tmux netcat lib32gcc1 lib32stdc++6 xz-utils


# update url to point at this server
update_init_status URL
PUBLICIP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
aws route53 change-resource-record-sets --hosted-zone-id ${R53ZONE} --change-batch "{\"Comment\":\"Update_server_ip\",\"Changes\":[{\"Action\":\"UPSERT\",\"ResourceRecordSet\":{\"Name\":\"${URLPREFIX}.${URLBASE}\",\"Type\":\"A\",\"TTL\":${URLTTL},\"ResourceRecords\":[{\"Value\":\"${PUBLICIP}\"}]}}]}"


# prepare local storage, mount it to the base path for the game and hand over ownership to default user
update_init_status MOUNT
sudo mkfs.ext4 -E nodiscard -m0 /dev/nvme1n1
mkdir ${BASE_DIR}
sudo mount -o discard /dev/nvme1n1 ${BASE_DIR}
sudo chown ${GAME_USER}:${GAME_USER} ${BASE_DIR}


# fetch and run the LGSM bootstrapper
update_init_status LGSM BOOTSTRAP
LGSMFILE=linuxgsm.sh
LGSMGAME=fctrserver
cd ${BASE_DIR}
wget -O ${LGSMFILE} https://linuxgsm.sh
chmod +x ${LGSMFILE}
./${LGSMFILE} ${LGSMGAME}


# install the game server
update_init_status GAME INSTALL
cd ${BASE_DIR}
./${LGSMGAME} ai # autoinstall -- no prompts to hold things up


# prep the management script
update_init_status PREPARING SCRIPTS
cd ${BASE_DIR}
wget -O manage.sh ${WEBROOT}/manage.sh
chmod +x manage.sh
# inject instance configuration information into the management script
sed -i "s|__BASE_DIR_REPLACEME__|${BASE_DIR}|g" manage.sh
sed -i "s|__BUCKET_ROOT_REPLACEME__|${BUCKET_ROOT}|g" manage.sh


# run restore over base installation
update_init_status RESTORING LAST SAVED STATE
cd ${BASE_DIR}
./manage.sh RESTORE

# start game
update_init_status STARTING GAME
cd ${BASE_DIR}
./${COMMAND_FILE} start
./${COMMAND_FILE} details # just to put this in the cloud init log

# now that everything is in place schedule backups -- script runs every minute and has logic to determine if it should do anything
update_init_status SCHEDULING BACKUPS
# list cron settings and echo new ones -- rewrite back into cron
(
    crontab -l;
    # every minute do the latest backup -- should validate if latest has changed
    echo "* * * * * ${BASE_DIR}/backup.sh BACKUP_LATEST"
    # every hour do a persistent backup
    echo "0 * * * * ${BASE_DIR}/backup.sh BACKUP_PERSISTENT"
) | crontab -


# final init status update
update_init_status COMPLETE
