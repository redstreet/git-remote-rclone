#!/usr/bin/bash

# Add this to rclone.conf
# [testrepo]
# type = alias
# remote = $HOME/LOCALCLOUD/testrepo

info() { echo -e "\n\n---------------- $1 ------------" }

REMOTE_PATH=$HOME/LOCALCLOUD/testrepo
SANDBOX=$HOME/gnu/SANDBOX

info "Creating cloud"
rm -fr $REMOTE_PATH
mkdir -pv $REMOTE_PATH

info "Creating local repo"
cd $SANDBOX
rm -fr testrepo
mkdir -v testrepo
cd testrepo
git init .
echo "Hello world! How are you?" > xyz
git add xyz
git commit -m "Initial commit."


info "Adding remote"
rclone mkdir "$REMOTE_PATH"
git remote add origin rclone://testrepo
git push origin main
git push -u origin main
