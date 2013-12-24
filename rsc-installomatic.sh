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

# Version check for Ubuntu 12.04
/etc/lsb-release
if ["$DISTRIB_RELEASE" != "12.04"]; then
   echo "This script is only tested to work (sorta) on Ubuntu 12.04 LTS" 1>&2
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


#set hostname
read -p "Set your hosrname (e.g. gavinsilver.com or www.gavinsilver.com): " NEWHOSTSTRING
read -p "$NEWHOSTSTRING - is this correct? (y/n) " RESP
	if [ "$RESP" != "y" ]; then
		echo "cowardly exiting the program because im too lazy to re-ask, run again and type correctly please"
		exit
	fi
/bin/hostname $NEWHOSTSTRING
echo "Hostname Updated!"
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
	
read -p "Do you want to setup auto-updates? (y/n) " AUTOUPQ
	if [ "$AUTOUPQ" = "y" ]; then
		read -e -p "What email should we use for alerts? " ALERTALIAS
	fi
# ...


# echo my output so far for testing
# echo "your mysql pwd will be $SQLPWD"
# echo "install webmin?- $WEBMINQ"
# echo "install postfix?- $POSTFIXQ"
# echo "your postfix alias is- $POSTFIXALIAS"
# echo "are we disabling local delivery for $HOSTNAME ? - $POSTFIXDDQ "

# Do webmin Stuff
if [ "$WEBMINQ" = "y" ]; then
	echo "Adding webmin keys and repos"
	wget -P /root/ http://www.webmin.com/jcameron-key.asc
	apt-key add /root/jcameron-key.asc
	echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list	
fi
# ...



# update & upgrade
apt-get update
apt-get -y upgrade
# ..

# add pre-req for webmin
apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python


# preset mysql pass info
echo "adding password info to mysql files"
echo mysql-server-5.1 mysql-server/root_password password $SQLPWD | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password $SQLPWD | debconf-set-selections
# ...

# DO IT!
apt-get install -y lamp-server^ php5-gd

if [ "$POSTFIXQ" = "y" ]; then
	apt-get install -y postfix
fi

if [ "$WEBMINQ" = "y" ]; then
	apt-get install -y webmin
fi

# post-apache isntall config
echo "this is where i should alert alloqoverride for htaccess to work"
a2enmod rewrite
service apache2 restart


# post-postfix install config setup
if [ "$POSTFIXQ" = "y" ]; then
	echo "setting $POSTFIXALIAS as alias for root mail"
	echo "root:	$POSTFIXALIAS" >> /etc/aliases
	if [ "$POSTFIXDDQ" = "y" ]; then
		echo "disabling local delivery for $HOSTNAME"
		postconf mydestination=localhost
	fi
service postfix restart
fi

if [ "$AUTOUPQ" = "y" ]; then
	echo "setting up unattended security updates and email alerts..."
	apt-get -y install unattended-upgrades apticron;sed -i -e 's/root/alerts@vanwestmedia.com/' /etc/apticron/apticron.conf
	sed -i -e 's|//Unattended-Upgrade::Mail "root@localhost"|Unattended-Upgrade::Mail '$ALERTALIAS'|' /etc/apt/apt.conf.d/50unattended-upgrades
fi


echo " is it done? "










