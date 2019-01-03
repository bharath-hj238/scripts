#!/bin/bash -x
# $Header$
# Usage: sh setup_new_machine.sh <bo|fo>
# This script is to be run by root on a new machine that does not have the usual users.
# The script creates users and directories.

EXPECTED_ARGS=1

if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: sh `basename $0` <bo|fo> "
  echo "bo = back office, fo = front office"
  exit 1
fi


case "$1" in

bo)  echo "Setting up a back office machine"
     my_user=pin
     my_id="502"
    ;;
fo)  echo "Setting up a front office machine"
     my_user=mozilla
     my_id="550"
    ;;
*) echo "Not valid: bo = back office, fo = front office"
   exit 1
   ;;
esac

### Create accounts and groups

        grep engineering /etc/group
        if [ $? -ne 0 ];then
                echo "Adding engineering group"
                /usr/sbin/groupadd -g 200 engineering;
        fi

        grep testlabs /etc/passwd
        if [ $? -ne 0 ];then
                echo "Adding testlabs account"
                /usr/sbin/useradd -g 200 -u 501 -m -c "Test Labs user" -d /home/testlabs -s /bin/bash testlabs;
                echo "Replacing testlabs account password"
                sed -i "s/^testlabs:.*$/testlabs:\$1\$PnJHKwW\/\$hQ70YfiKf9VsjHYK7G0yn\.:14813::::::/" /etc/shadow;
                echo "
Defaults:testlabs !requiretty
testlabs   ALL=(ALL) NOPASSWD: ALL
nagios   ALL=(root) NOPASSWD: /etc/init.d/nagios
" >> /etc/sudoers
        fi

        grep viewer /etc/group
        if [ $? -ne 0 ];then
                echo "Adding viewer group"
                /usr/sbin/groupadd -g 7001 viewer;
        fi

        grep viewer /etc/passwd
        if [ $? -ne 0 ];then
                echo "Adding viewer account"
                /usr/sbin/useradd -g 7001 -u 7001 -m -c "Read Only user" -d /home/viewer -s /bin/bash viewer;
                echo "Replacing viewer account password"
                sed -i "s/^viewer:.*$/viewer:\$1$HvajB7SK$DiFONe\/a\/DGf7EDsQpU\.31:14860::::::/" /etc/shadow;
        fi

        grep $my_user /etc/group
        if [ $? -ne 0 ];then
                echo "Adding $my_user group"
                /usr/sbin/groupadd -g $my_id $my_user;
        fi

        grep $my_user /etc/passwd
        if [ $? -ne 0 ];then
                echo "Adding $my_user user"
                /usr/sbin/useradd -g $my_id -u $my_id -m -c "Application user" -d /home/$my_user -s /bin/bash $my_user;
                echo "Replacing $my_user user account password"
                sed -i "s/^$my_user:.*$/$my_user:\$1\$oHIdmVRV$Z1eazz0CN4WN595m7nBO5\/:14519::::::/" /etc/shadow;
        fi

# Creating qa directories
if [ -d /app/qa/installers ]; then
   echo "/app/qa/installers already exists"
else
  echo " Creating the QA directory /app/qa/installers"
  mkdir -p /app/qa/installers
  chmod 777 -R /app/qa
fi

# Creating application directories
if [ -d /app/symc ]; then
   echo "/app/symc already exists"
else
  echo " Creating the application directory /app/symc"
  mkdir -p /app/symc
fi
  chown -R $my_user:$my_user /app/symc

# Creating logs directory
if [ -d /app/logs/ ]; then
   echo "/app/logs already exists"
else
  echo " Creating the logs directory /app/logs"
  mkdir -p /app/logs
fi
  chown -R $my_user:$my_user /app/logs

# Creating data directory
if [ $1 = fo ]; then
 if [ -d /app/data/ ]; then
   echo "/app/data already exists"
 else
  echo " Creating the data directory /app/data"
  mkdir -p /app/data
 fi
  chown -R $my_user:$my_user /app/data
fi

# Setup passwordless access for the user running the script to testlabs1/2
# Assuming the machine has openssh
if [ -d /home/$my_user/.ssh ]; then
   echo "/home/$my_user/.ssh  already exists"
else
 echo "Setup ssh for $my_user"
 mkdir /home/$my_user/.ssh
 chmod 700 /home/$my_user/.ssh
 touch /home/$my_user/.ssh/authorized_keys
 cd /home/$my_user/.ssh
 echo "Copying buildman@ztrain-lnx public key (assuming it has not changed)"
 echo "ssh-dss AAAAB3NzaC1kc3MAAACBAMyFWQssvpIdEmz8zt1AIcqqzNPu3gxjQT2rAtZWa79Kw+80XvM/STteMmklxtQdUZQRHzCt7Hn3Wucsk0WxPB5p1tXD/1Z9jIFBcShRPvsrmNXdAIFVrbAF2GmluHHFIvPHX7WLrW5vnW1CYGAKdSqhH0t2SGBgRhBiXl/6U40RAAAAFQD6rGxndqWDfIKBdUhL5LNC49B0fQAAAIEAy6Yy64Rnhtu/NSDSEk9qMpeTbDBw3vyVB9ABzkBjkoMh1e4Y0ijUmGI19airtyzrfKCnBpiDp0TdYyCFfJA+6tNd11XcMCweBc0brMjB1Q5bvrG4pdz0GZhgoWCKcD5u1RWGtr2SGgeEynoOo1HiRqzT7Q9WdSwkHIQI8gTurjsAAACAUXOHjmRw6DnSCYOvGNzvnX/CegHJu48MvbGxDQEerFMGuXMECEeLNAy4pddbPWbZK+6z2dcrckk3FQzfam57bn9GtNjg1+O5C3pkTHozac1df7XUIIAyToR/YgHV8uvUqyaXDhveUbW10F9Wce1Iuc4HphdeanB7oUGqZyKDQck= buildman@ztrain-lnx" > ztrain-lnx.id_dsa.pub
 cat ztrain-lnx.id_dsa.pub >> authorized_keys
 chown -R $my_user:$my_user /home/$my_user/.ssh
 echo "Generating ssh key for $my_user - leave pass phrase empty"
 sudo -u $my_user ssh-keygen -t dsa
 cat id_dsa.pub >> authorized_keys
 chmod 600 *

# Copying to testlabs
 if [ -d /home/testlabs/.ssh/ ]; then
   echo "/home/testlabs/.ssh  already exists"
 else
   echo "Creating /home/testlabs/.ssh"
   mkdir -p /home/testlabs/.ssh
   chmod 700 /home/testlabs/.ssh
 fi
 cat /home/$my_user/.ssh/ztrain-lnx.id_dsa.pub >> /home/testlabs/.ssh/authorized_keys
 chown -R testlabs:200 /home/testlabs/.ssh
 chmod 600 /home/testlabs/.ssh/authorized_keys

# Copying to root
 if [ -d /root/.ssh/ ]; then
   echo "/root/.ssh  already exists"
 else
   echo "Creating /root/.ssh"
   mkdir -p /root/.ssh
   chmod 700 /root/.ssh
 fi
 cat /home/$my_user/.ssh/ztrain-lnx.id_dsa.pub >> /root/.ssh/authorized_keys
 chown -R root:root /root/.ssh
 chmod 600 /root/.ssh/authorized_keys
fi

echo "BO: /usr/sbin/rhnreg_ks --activationkey=1-centos-6-2017-9-01 --serverUrl=http://swp1bo-m1-inf.ssoqa-bo.mtv1.vrsn.com/XMLRPC --force"
echo "FO: /usr/sbin/rhnreg_ks --activationkey=1-centos-6-2017-9-01 --serverUrl=http://swp2fo-m1-inf.ssoqa-fo.mtv1.vrsn.com/XMLRPC --force"
echo "yum update -y"
echo "reboot"
echo "/opt/quest/bin/vastool -u VLABS_account_name unjoin"
echo "/opt/quest/bin/vastool -u VLABS_account_name join -f -c OU=ux_feature_test,OU=EDCSILO,OU=MTV,DC=VLABS,DC=ldap,DC=vrsn,DC=com vlabs.ldap.vrsn.com"
echo "/opt/quest/bin/vastool configure vas libvas smb-dialect-range 2.1-3"
echo "/opt/quest/bin/vgptool apply"
echo "Copy over logdir-cleanup and logdir-cleanup.pl"

