# Factorio Server
This is set up for an Ubuntu 22.04+ host on AWS with NVME drive.

Recommend 4+ vCPU and 16GB RAM for non-blocking autosave


## Initial Game Setup
* Configure userdata.sh with the appropriate settings

* Manually get an initial server state working as per intended target state.
    * init.sh can help guide how to do this.
* Install LGSM and factorio, install mods, configure settings.
* Verify game is working as intended.
* Use the manage.sh script to BACKUP_SETTINGS
    * you will need to set the REPLACEME values for the BASE_DIR and BUCKET_ROOT

## Bootstrapped Instance
* Create an instance or spot request with appropriate settings
* Copy userdata.sh into the userdata field
* New server instances will pull latest init.sh from WEBROOT -- make changes and terminate/restart
