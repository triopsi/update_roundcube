#!/bin/bash
#---------------------------------------------------------------------
# Script: update_roundcube.sh
# Version: 1.0
# Description: Update einer Roundcube Instanz
# Vorraussetzungen: 
# - Roundcube existiert schon
# ---------------------------------------------------------------------

echo "
  _____                       _            _          
 |  __ \                     | |          | |         
 | |__) |___  _   _ _ __   __| | ___ _   _| |__   ___ 
 |  _  // _ \| | | |  _ \ / _  |/ __| | | |  _ \ / _ |
 | | \ \ (_) | |_| | | | | (_| | (__| |_| | |_) |  __/
 |_|  \_\___/ \__,_|_| |_|\__,_|\___|\__,_|_.__/ \___|
 
"
APWD=$(pwd);
TMPWD="$APWD/tmp"
URLROUNDCUBE_PART="https://github.com/roundcube/roundcubemail/releases/download/"

#Owner Roundcube
GROUP=""
OWNER=""

#DB Roundcube
DBUSER=""
DBPASSWORD=""
DBBASE=""

# ------------------------------------------------------------------------------------------
# Logging
#-------------------------------------------------------------------------------------------
#Those lines are for logging purposes
exec > >(tee -i ${APWD}/roundcube_update.log)
exec 2>&1
echo 
echo "Welcome to Roundcube update Setup Script V1.0"
echo "========================================="
echo "Roundcube updater"
echo "========================================="

echo -n "Auto detect the roundcube directory? (y/n) "
read -n 1 -r
echo -e "\n"    
RE='^[Yy]$'
if [[ ! $REPLY =~ $RE ]]; then
	while read -r -p "Path to roundcube:" roundcube_path && [ ! -d $roundcube_path ]; do
    echo "invalid input. Please try again"
  done
else
  roundcube_path="$(pwd ..)/web"
  echo "Path $roundcube_path"
  echo -n "Is this correct? (y/n) :"
  read -n 1 -r
  echo -e "\n"    
  RE='^[Yy]$'
  if [[ ! $REPLY =~ $RE ]]; then
    exit 1
  fi
fi

RE='^([0-9]{1}\.[0-9]{1}\.[0-9]{1})$'
while read -r -p "Which Version you will update? (e.g 1.4.0) :" to_roundcube_version && [[ ! $to_roundcube_version =~ $RE ]]; do
   echo "invalid input. Please try again."
done
echo "You will update to the Version $to_roundcube_version"
echo -n "Is this correct? (y/n) :"
read -n 1 -r
echo -e "\n"    
RE='^[Yy]$'
if [[ ! $REPLY =~ $RE ]]; then
	exit 1
fi

echo -n "Backup the roundcube Instanz?  (y/n) :"
read -n 1 -r
echo -e "\n"    
RE='^[Yy]$'
if [[ $REPLY =~ $RE ]];then
  if [ ! -d backup ];then
    mkdir backup
    if [ $? -ne 0 ];then
      echo "Failed to make a backup directory"
      exit 99
    fi
    cd backup
    tar cjf roundcube_rootdir_`date +"%Y-%m-%d"`.tar.bz2 $roundcube_path/* 
    mysqldump -u$DBUSER -p$DBPASSWORD $DBBASE > roundcubedb_`date +"%Y-%m-%d"`.sql
    cd -
  fi
fi

if [ ! -d tmp ];then
  mkdir tmp
  if [ $? -ne 0 ];then
    echo "Failed to make a tmp directory"
    exit 99
  fi
else 
 rm -rf "$TMPWD/*"
fi

wgeturl=$URLROUNDCUBE_PART$to_roundcube_version"/roundcubemail-"$to_roundcube_version"-complete.tar.gz"

wget -P $TMPWD $wgeturl
if [ $? -ne 0 ];then
  echo "Failed to download the roundcube TARGZ"
  exit 99
fi

if [ ! -f $TMPWD/roundcubemail-$to_roundcube_version-complete.tar.gz ];then
  echo "Failed to open the roundcube TARGZ"
  exit 99
fi

tar -C $TMPWD -zxvf $TMPWD/roundcubemail-$to_roundcube_version-complete.tar.gz
if [ $? -ne 0 ];then
  echo "Failed to decompress the roundcube TARGZ"
  exit 99
fi

if [ ! -f "$TMPWD/roundcubemail-$to_roundcube_version/bin/installto.sh" ];then
  echo "Install script don't exits"
  exit 99
fi

$TMPWD/roundcubemail-$to_roundcube_version/bin/installto.sh $roundcube_path
if [ $? -ne 0 ];then
  echo "Failed to update roundcube"
  exit 99
fi

chown -R $OWNER:$GROUP $roundcube_path
if [ $? -ne 0 ];then
  echo "Failed to chown the files"
  exit 99
fi

echo "Finisch"
echo "RC=0"
exit 0