# Factorio Server
This is set up for an Ubuntu 22.04+ host on AWS.


## Initial Game Setup
* Configure userdata.sh with the appropriate settings

* Manually get an initial server state working as per intended target state.
    * init.sh can help guide how to do this.
* Install LGSM and factorio, install mods, configure settings.
* Verify game is working as intended.
* Use the manage.sh script to BACKUP_SETTINGS
    * you will need to set the REPLACEME values for the BASE_DIR and BUCKET_ROOT.

## A
* 



Create an appropriate AWS instance request and copy userdata.sh contents into userdata field.

userdata.sh has comments explaining what it is expecting.

It will take a bit of manual work to get settings and so on working the first time.
Rather than trying to programmatically fetch mods and deal with versions and so on,
just set up the server manually as a once off, validate that the server is behaving
as expected then run the management script to back up the settings and backup latest.

From there the setup server can be terminated, and the auto-initialising version with
userdata can be configured. This is particularly useful for running a server on a spot
request with auto-renewal. If it has to be terminated and swapped to another instance
it will just restart from the last save.

Also works if terminating a reserved instance and restoring
 