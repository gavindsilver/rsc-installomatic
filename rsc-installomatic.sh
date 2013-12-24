#!/bin/bash
# rackspace-wordpress-inallomatic, version 1
# Run as root, of course.
# Gavin Silver - 2013 - gavinsilver@gavinsilver.com

echo " "
echo " "
echo " "
echo "Welcome to Gavin's wonderful wordpress-o-matic installer for rackspace cloud servers"
echo " "
echo " "

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
read -p "What password would you like to use for the MySQL installation? " SQLPWD
read -p "$SQLPWD - is this correct? (y/n) " RESP
if [ "$RESP" != "y" ]; then
	echo "cowardly exiting the program because im too lazy to re-ask, run again and type correctly please"
	exit
fi
# ...

# Optional options from the dept. of redundancy dept.
read -p "Do you want webmin installed? (y/n) " WEBMINQ
read -p "Do you want Postfix installed for mail? (y/n) " POSTFIXQ
if [ "$POSTFIXQ" = "y" ]; then
	read -e -p "What email should we use for postmaster/abuse/root etc? " POSTFIXALIAS
	read -p "Should we disable local delivery for $HOSTNAME ? (y/n) " POSTFIXDDQ
fi
# ...


# echo my output so far for testing

echo "your mysql pwd will be $SQLPWD"
echo "install webmin?- $WEBMINQ"
echo "install postfix?- $POSTFIXQ"
echo "your postfix alias is- $POSTFIXALIAS"
echo "are we disabling local delivery for $HOSTNAME ? - $POSTFIXDDQ "

# Do webmin Stuff
if [ "$WEBMINQ" = "y" ]; then
	echo "Adding webmin keys and repos"
	wget -P /root/ http://www.webmin.com/jcameron-key.asc
	apt-key add /root/jcameron-key.asc
	echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list	
fi


# update system
apt-get update

# echo mysql-server-5.1 mysql-server/root_password password $SQLPWD | debconf-set-selections
# echo mysql-server-5.1 mysql-server/root_password_again password $SQLPWD | debconf-set-selections
# apt-get install -y mysql-server
