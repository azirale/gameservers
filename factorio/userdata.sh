#!/bin/bash

# override with a branch if you are faffing about
export BRANCH=master

# this should match the current folder name -- unless this folder has been archived off somewhere
# this MUST be URL-friendly
export CONTEXT=factorio

# the game user -- everything will be run as this user
export GAME_USER=ubuntu

# s3 bucket we will be doing backups etc into and restoring from
export BUCKET_NAME=azirale-home

# where to fetch our scripts and so on -- everything under this root should match up with the folder this is sourced from
export WEBROOT=https://raw.githubusercontent.com/azirale/gameservers/${BRANCH}/${CONTEXT}

# grab the init file into the user's home and run as that user to bootstrap everything
INIT_FILE=/home/${GAME_USER}/init.sh
wget -O ${INIT_FILE} ${WEBROOT}/init.sh
chown ${GAME_USER}:${GAME_USER} ${INIT_FILE}
chmod +x ${INIT_FILE}
sudo -E -u ${GAME_USER} ${INIT_FILE}
