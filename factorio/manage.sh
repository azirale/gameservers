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
PRIMARY_SAVE=serverfiles/save1.zip
PREVIOUS_AUTOSAVE=CURRENT_AUTOSAVE.zip
CURRENT_AUTOSAVE=$(printf ${BASE_DIR}/serverfiles/saves/; ls -t1 ${BASE_DIR}/serverfiles/saves | grep -P '_autosave\d+\.zip' | head -n1)
LATEST_BACKUP=${BUCKET_ROOT}/latest_autosave.zip
PERSISTENT_BACKUP=${BUCKET_ROOT}/${YMD}/${YMDHMS}
SETTINGS_BACKUP=${BUCKET_ROOT}/settings.tar


# will check if latest autosave is different to previously cached one and backup to latest if it is
do_latest_backup() {
    # if there is no autosave yet then ditch -- will have to wait for one to be generated
    if [[ ! -e ${CURRENT_AUTOSAVE} ]]
    then
        echo "No autosave yet -- cannot do a backup"
        return
    fi
    # if there is no previous autosave then copy the primary save in its place before trying to do compare
    if [[ ! -e ${PREVIOUS_AUTOSAVE} ]]
    then
        echo "No previous autosave -- using primary save as alternative"
        cp ${PRIMARY_SAVE} ${PREVIOUS_AUTOSAVE}
    fi
    # check if files match up -- can ditch now if they do
    echo ${CURRENT_AUTOSAVE}
    echo ${PREVIOUS_AUTOSAVE}
    cmp -s ${CURRENT_AUTOSAVE} ${PREVIOUS_AUTOSAVE}
    COMPARE_RC=$?
    if [[ ${COMPARE_RC} -eq 0 ]]
    then
        echo "Previous autosave matches current autosave -- latest backup update unnecessary"
        return
    fi
    # did not ditch so must need to do backup
    # wait for active handles on file to finish -- game is probably saving it right now
    echo "Latest autosave is different to previous -- updating latest backup"
    HANDLE_COUNT=$(lsof -- ${CURRENT_AUTOSAVE} | wc -l)
    if [[ ${HANDLE_COUNT} > 0 ]]
    then
        echo "File is busy, skipping this run -- will get it next time around"
        return
    # file must be ready for copy :fingers_crossed:
    else
        echo "Replacing latest autosave copy"
        cp ${CURRENT_AUTOSAVE} ${PREVIOUS_AUTOSAVE}
        aws s3 cp ${PREVIOUS_AUTOSAVE} ${LATEST_BACKUP}
    fi
}


# takes the latest backup and persists it with a unique name
do_persistent_backup() {
    aws s3 cp ${LATEST_BACKUP} ${PERSISTENT_BACKUP}
}


# saves the server settings to its own backup -- these generally do not change
do_settings_backup() {
    tar -cf settings.tar \
        serverfiles/mods \
        serverfiles/data/fctrserver.json \
        serverfiles/config/config.ini;
    aws s3 cp settings.tar ${SETTINGS_BACKUP}
    rm settings.tar
}


# restore server based on backup files
restore_backup() {
    # unpack settings first
    echo "Retrieving settings tar and unpacking"
    aws s3 cp ${SETTINGS_BACKUP} settings.tar
    tar -xf settings.tar
    rm settings.tar
    # and copy the latest backup -- this can go direct to the save file location
    echo "Retrieving latest save directly over primary save"
    aws s3 cp ${LATEST_BACKUP} ${PRIMARY_SAVE}
    # and copy it to previous autosave so the comparison can be done
    echo "Copying primary save to 'previous save' for backup checking"
    cp ${PRIMARY_SAVE} ${PREVIOUS_AUTOSAVE}
}


# handle call
if [[ "${COMMAND_PARAM}" = "BACKUP_LATEST" ]]
then
    do_latest_backup
elif [[ "${COMMAND_PARAM}" = "BACKUP_PERSISTENT" ]]
then
    do_persistent_backup
elif [[ "${COMMAND_PARAM}" = "BACKUP_SETTINGS" ]]
then
    do_settings_backup
elif [[ "${COMMAND_PARAM}" = "RESTORE" ]]
then
    restore_backup
else
    echo "Unknown management command [${COMMAND_PARAM}]"
fi
