#!/bin/bash

# parameter command passed in -- what should the script do
COMMAND_PARAM=$1

# root path to local data and configuration -- init.sh will replace this as per configuration from userdata.sh
BASE_DIR=__BASE_DIR_REPLACEME__
# root path in bucket to store things -- init.sh will replace this as per configuration from userdata.sh
BUCKET_ROOT=__BUCKET_ROOT_REPLACEME__

# we are expecting BASE_DIR to be provided as an environment variable
# everything is executed from the context of the base directory
cd ${BASE_DIR}

# current run date and time as text for naming things
YMDHMS=$(date +%Y%m%d-%H%M%S)
YMD=$(date +%Y%m%d)
HOUR=$(date +%H)

# locations of various save files and backups
BACKUP_TAR=backup.tar.gz
LATEST_BACKUP=${BUCKET_ROOT}/latest.tar.gz
PERSISTENT_BACKUP=${BUCKET_ROOT}/${YMD}/${YMDHMS}.tar.gz

# game specific files/directories to tarball and copy to s3
BACKUPGLOBS="serverfiles/Configs/ serverfiles/Storage/"



# will check if latest autosave is different to previously cached one and backup to latest if it is
do_soft_backup() {
    # if there is no autosave yet then ditch -- will have to wait for one to be generated
    echo "Writing backup tar"
    tar -czvf ${BACKUP_TAR} ${BACKUPGLOBS}
    echo "Copying to s3"
    aws s3 cp ${BACKUP_TAR} ${LATEST_BACKUP}
    echo "Cloning to timestamped"
    aws s3 cp ${LATEST_BACKUP} ${PERSISTENT_BACKUP}
    rm ${BACKUP_TAR}
}


# takes the latest backup and persists it with a unique name
do_hard_backup() {
    echo "Doing hard backup"
    ./ecoserver stop
    do_soft_backup
    ./ecoserver start
}


# restore server based on backup files
restore_backup() {
    # copy latest backup and unpack
    echo "Retrieving latest save directly over primary save"
    aws s3 cp ${LATEST_BACKUP} ${BACKUP_TAR}
    # and copy it to previous autosave so the comparison can be done
    tar -xzf ${BACKUP_TAR}
    rm ${BACKUP_TAR}
}


# handle call
if [[ "${COMMAND_PARAM}" = "BACKUP_SOFT" ]]
then
    do_soft_backup
elif [[ "${COMMAND_PARAM}" = "BACKUP_HARD" ]]
then
    do_hard_backup
elif [[ "${COMMAND_PARAM}" = "RESTORE" ]]
then
    restore_backup
else
    echo "Unknown management command [${COMMAND_PARAM}]"
fi
