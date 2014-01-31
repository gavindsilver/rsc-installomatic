rsc-installomatic
=================

version 1.0

rsc-installomatic is a heavily opinionated script to quickly deploy a production ready LAMP Stack environment on a standard Ubuntu 12.04 LTS Rackspace Cloud Server default instance.

This script started as an attempt to automate a routine duty required before deploying a new WordPress web project. It has grown a little bit since.

The script is capable of accomplishing:

- Setting your hostname if you didn't make the instance name = proposed hostname
- Full LAMP Stack with some sane defaults
- Postfix install allowing mail to be sent from server
	- Disables local delivery so messages going to "someone@yourwebserver.com" actually go out and check real MX records
- Webmin install for management (w/ SSL support)
- Key PHP extensions (gd, mail etc)
- Key Apache modules (rewrite, headers, expire)
- Auto updates, with update notifications
- A default install of the latest WordPress with a few key plugins 
- Performance pre-reqs for WordPress W3 Total Cache (APC Opcode, etc..)

IMPORTANT NOTE: Do not install Performance/Cache options if you are not installing WordPress with the script unless you know what you are doing and are familar with Alternative PHP Cache (http://us3.php.net/apc/)


Please use GitHub Issues for support

