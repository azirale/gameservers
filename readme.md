A place to store scripts for running game servers with LGSM over AWS.

Each folder under here is a 'CONTEXT' for a server.
This is used to drive a lot of behaviour, like where to find scripts and where to store backups
within a cloud storage account. The directory names must be natively URL-friendly.

The basic premise is that each folder will have a userdata.sh file that does the intial bootstrapping.
That file provides the 'CONTEXT' for its own folder, the S3 'BUCKET_NAME' that will be used for storage,
and the 'BRANCH' that it should pull the scripts from.

The userdata.sh bootstrapper will download the init script and run it as the intended game running user.
The init script takes care of configuring the server, installing the game, setting the management scripts,
and restoring any existing backups (in case of terminate and fresh instance)