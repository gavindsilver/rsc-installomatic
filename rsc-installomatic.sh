#!/bin/bash
# rackspace-wordpress-inallomatic, version 1
# Run as root, of course.
# Gavin Silver - 2013 - gavinsilver@gavinsilver.com

#log doesnt work yet!
DATE=$(date +"%Y%m%d%H%M")
logfile="rsc-installomatic"$DATE".log"
# get a random string why not?!!?
RAND=`tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1`

echo " "
echo " "
echo " "
echo "Welcome to Gavin's wonderful install-o-matic for rackspace cloud servers"
# touch /var/log/$logfile
# echo "... creating a logfile: $logfile "
echo " "



# Make sure only root can run our script
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root you dummy!" 1>&2
   exit 1
fi
# ...

# Version check for Ubuntu 12.04
. /etc/lsb-release
if [ "$DISTRIB_RELEASE" != "12.04" ]; then
   echo "This script is only tested to work (sorta) on Ubuntu 12.04 LTS. Exiting." 1>&2
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
read -p "Set your FQDN (e.g. gavinsilver.com): " NEWHOSTSTRING
if [ "$NEWHOSTSTRING" != "$HOSTNAME" ]; then
	read -p "$NEWHOSTSTRING - is this correct? (y/n) " RESP
		if [ "$RESP" != "y" ]; then
			echo "cowardly exiting the program because im too lazy to re-ask, run again and type correctly please"
			exit
		fi
	sed -ie 's|'$HOSTNAME'|'$NEWHOSTSTRING'|' /etc/hosts
	/bin/hostname $NEWHOSTSTRING
	echo "Hostname Updated! DON'T FORGET TO REBOOT"
else
	echo "That's your hostname already so I am not touching anything here."
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
read -p "Do you want Postfix installed for mail with disabled local delivery? (y/n) " POSTFIXQ
	if [ "$POSTFIXQ" = "y" ]; then
		read -e -p "What email should we use for postmaster/abuse/root etc? " POSTFIXALIAS
	fi
	
read -p "Do you want to setup auto-updates? (y/n) " AUTOUPQ
	if [ "$AUTOUPQ" = "y" ]; then
		read -e -p "What email should we use for alerts? " ALERTALIAS
	fi

read -p "Do you want to install performancing enhancing drugs? I mean, codes? [memcache/apc/opcode/mod_expires|headers etc ?] (y/n) " PERFEQ
# ...

#wordpress latest
read -p "I can also install the latest version of WordPress for you.. interested? " WORDPRESSQ




# Do webmin Stuff
if [ "$WEBMINQ" = "y" ]; then
	echo "Adding webmin keys and repos"
	wget -P /root/ http://www.webmin.com/jcameron-key.asc -q
	apt-key add /root/jcameron-key.asc
	echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
	echo "deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib" >> /etc/apt/sources.list	
fi
# ...



# update & upgrade
apt-get update -qq
apt-get upgrade -qq
# ..

# add pre-req for webmin
apt-get install -qq perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python 1>&2


# preset mysql pass info
echo "adding password info to mysql files"
echo mysql-server-5.1 mysql-server/root_password password $SQLPWD | debconf-set-selections
echo mysql-server-5.1 mysql-server/root_password_again password $SQLPWD | debconf-set-selections
# ...

# DO IT!
apt-get install -qq lamp-server^ php5-gd unzip

if [ "$POSTFIXQ" = "y" ]; then
	echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
	echo "postfix postfix/mailname string $HOSTNAME" | debconf-set-selections
	echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
	apt-get install -qq postfix
	/usr/sbin/postconf -e "inet_interfaces = loopback-only"
	echo "disabling local delivery for $HOSTNAME"
	postconf mydestination=localhost
	echo "setting $POSTFIXALIAS as alias for root mail and restarting postfix..."
	echo "root:	$POSTFIXALIAS" >> /etc/aliases
	service postfix restart
fi

if [ "$WEBMINQ" = "y" ]; then
	apt-get install -qq webmin
fi

# post-apache install config
a2enmod rewrite
sed -i '7 s/AllowOverride None/AllowOverride All/' /etc/apache2/sites-enabled/000-default
sed -i '11 s/AllowOverride None/AllowOverride All/' /etc/apache2/sites-enabled/000-default


if [ "$PERFEQ" = "y" ]; then
	echo "Installing & configuring performance optimzations..."
	a2enmod headers
	a2enmod expires
	apt-get install -qq php-pear php5-dev make libpcre3-dev php5-curl php5-tidy 
	printf "\n" | pecl install apc 1>&2
	printf "\n" | pecl install memcache 1>&2
	echo "adding all the extension config info that pecl bitches about..."
	echo "extension=memcache.so" >> /etc/php5/apache2/php.ini
	echo "extension=apc.so" >> /etc/php5/apache2/php.ini
	echo "apc.shm_size = 64" >> /etc/php5/apache2/php.ini
	echo "apc.stat = 0" >> /etc/php5/apache2/php.ini
	cp /usr/share/doc/php-apc /var/www/$RAND.php
	echo "...done"
fi

service apache2 restart

# auto updates
if [ "$AUTOUPQ" = "y" ]; then
	echo "setting up unattended security updates and email alerts..."
	apt-get install -qq unattended-upgrades apticron
	sed -i -e 's/root/'$ALERTALIAS'/' /etc/apticron/apticron.conf
	sed -i -e 's|//Unattended-Upgrade::Mail "root@localhost"|Unattended-Upgrade::Mail '$ALERTALIAS'|' /etc/apt/apt.conf.d/50unattended-upgrades
fi

#Wordpress latest
if [ "$WORDPRESSQ" = "y" ]; then
	wget -P /var/www http://wordpress.org/latest.tar.gz -q
	tar -xf /var/www/latest.tar.gz -C /var/www
	mv /var/www/wordpress/* /var/www/
	rm -rf /var/www/wordpress /var/www/latest.tar.gz
	chown -R www-data:www-data /var/www
	rm -f /var/www/index.html
	
#	CMD="create database rsc_wordpress;"
#	mysql -u root -p$SQLPWD -e "$CMD"
	
#add plugins	
	wget -P /var/www/wp-content/plugins/ http://downloads.wordpress.org/plugin/w3-total-cache.zip -q
	wget -P /var/www/wp-content/plugins/ http://downloads.wordpress.org/plugin/better-wp-security.zip -q
	wget -P /var/www/wp-content/plugins/ http://downloads.wordpress.org/plugin/velvet-blues-update-urls.zip -q
	wget -P /var/www/wp-content/plugins/ http://downloads.wordpress.org/plugin/all-in-one-seo-pack.zip -q
	wget -P /var/www/wp-content/plugins/ http://downloads.wordpress.org/plugin/wp-recaptcha.zip -q
	unzip /var/www/wp-content/plugins/better-wp-security.zip -d /var/www/wp-content/plugins/
	unzip /var/www/wp-content/plugins/velvet-blues-update-urls.zip -d /var/www/wp-content/plugins/
	unzip /var/www/wp-content/plugins/all-in-one-seo-pack.zip -d /var/www/wp-content/plugins/
	unzip /var/www/wp-content/plugins/wp-recaptcha.zip -d /var/www/wp-content/plugins/
	rm -rf /var/www/wp-content/plugins/*.zip
	
fi





#...





echo " "
echo " "



read -p "Do you want an email with the details? (y/n) " SENDEMAILQ
	if [ "$SENDEMAILQ" = "y" ]; then
		read -e -p "Enter E-Mail Address:  " EMAIL
	fi
	
echo " "
#...






# Build E-Mail
EMAILMESSAGE="/var/log/$logfile"
SUBJECT="NEW RSC-INSTALLOMATIC RUN ON $HOSTNAME"
echo "NEW RSC-INSTALLOMATIC RUN ON $HOSTNAME" > $EMAILMESSAGE
echo "date: $DATE" >> $EMAILMESSAGE
echo "hostname: $HOSTNAME" >> $EMAILMESSAGE
echo "root_db_pwd: $SQLPWD" >> $EMAILMESSAGE
echo "postfix installed?: $POSTFIXQ" >> $EMAILMESSAGE
echo "postmaster/root alias: $POSTFIXALIAS" >> $EMAILMESSAGE
echo "webmin installed?: $WEBMINQ" >> $EMAILMESSAGE
	if [ "$WEBMINQ" = "y" ]; then
		echo "webmin address: https://$hostname:10000" >> $EMAILMESSAGE
	fi
echo "performance options enabled/installed?: $PERFEQ" >> $EMAILMESSAGE
	if [ "$PERFEQ" = "y" ]; then
		echo "apc script check: http://$hostname/$RAND.php" >> $EMAILMESSAGE
	fi
echo "latest wordpress installed?: $WORDPRESSQ" >> $EMAILMESSAGE
	if [ "$WORDPRESSQ" = "y" ]; then
		echo "FINISH YOUR WORDPRESS INSTALL: http://$hostname" >> $EMAILMESSAGE
		echo "New Wordpress Database: rsc_wordpress" >> $EMAILMESSAGE
	fi
# send an email using /bin/mail
if [ "$SENDEMAILQ" = "y" ]; then
	mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE
fi


echo "FINISHED!!!!"

# show results
# echo "your mysql pwd is $SQLPWD"
# echo "install webmin?- $WEBMINQ"
# echo "install postfix?- $POSTFIXQ"
# echo "your postfix alias is- $POSTFIXALIAS"
# echo "are we disabling local delivery for $HOSTNAME ? - $POSTFIXDDQ "









