#!/bin/bash
# rackspace-wordpress-inallomatic, version 1
# Run as root, of course.
# Gavin Silver - 2013 - gavinsilver@gavinsilver.com


echo "Welcome to Gavin's wonderful wordpress-o-matic installer for rackspace cloud servers"

# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root you dummy!" 1>&2
   exit 1
fi
# ...


# Make sure the human didnt accidentally run the file?
read -p "Would you like to continue? (y/n) " RESP
if [ "$RESP" = "y" ]; then
	echo "Glad to hear it, let's get started"
else
	echo "Why run it then? PEACE"
	exit 1
fi
# ...


# Ask for new root mysql password, in the future handle this better (we shouldnt output the passwd to console)
# quit if the user typos
read -p "What password would you like to use for the MySQL installation?" SQLPWD
read -p "$SQLPWD - is this correct? (y/n) " RESP
if [ "$RESP" != "y" ]; then
   exit
fi
# ...

read -p "Do you want webmin installed? (y/n)" WEBMINQ
read -p "Do you want Postfix installed for mail? (y/n)" POSTFIXQ
if [ "$POSTFIXQ" != "y" ]; then
   read -p "Should we disable local delivery for $strHost ? (y/n)" POSTFIXDDQ
   
fi


apt-get update
echo mysql-server-5.1 mysql-server/root_password password $SQLPWD | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password $SQLPWD | debconf-set-selections
apt-get install -y mysql-server
