#!/bin/bash

$(which chmod) 700 /etc/monit/monitrc

#CLEAR TMP FILES
/root/autoclean.sh

#ADD CRON
CRONFILE="/cronfile.final"
SYSTEMCRON="/cronfile.system"
USERCRON="/cronfile"

echo > $CRONFILE
if [ -f "$SYSTEMCRON" ]; then
	cat $SYSTEMCRON >> $CRONFILE
fi
if [ -f "$USERCRON" ]; then
	cat $USERCRON >> $CRONFILE
fi
/usr/bin/crontab $CRONFILE

#DECLARE/SET VARIABLES
PHPVERSION=`cat /PHP_VERSION 2>/dev/null`
if [ -z "$PHPVERSION" ]; then
    PHPVERSION=`php -v|grep --only-matching --perl-regexp "7\.\\d+" |head -n1`
fi

if [ -z "$PHPVERSION" ]; then
    PHPVERSION='7.3'
fi

echo > /etc/php/$PHPVERSION/fpm/env.conf
for i in `/usr/bin/env`; do
    PARAM=`echo $i |cut -d"=" -f1`
    VAL=`echo $i |cut -d"=" -f2`
    echo "env[$PARAM]=\"$VAL\"" >> /etc/php/$PHPVERSION/fpm/env.conf
done

#PUPULATE TEMPLATES
cp -f /etc/ssmtp/ssmtp.conf.template /etc/ssmtp/ssmtp.conf
sed -i 's/%MY_HOSTNAME%/'`/bin/hostname`'/g' /etc/ssmtp/ssmtp.conf

$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/monit/conf-enabled/php-fpm
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/pool.d/www.conf
$(which sed) -i 's/%PHP_VERSION%/'$PHPVERSION'/g' /etc/php/$PHPVERSION/fpm/php-fpm.conf


#START SERVICES
/usr/sbin/service cron restart
/usr/sbin/service php$PHPVERSION-fpm restart
sleep 1
/usr/sbin/service monit start

#KEEP CONTAINER ALIVE
/usr/bin/tail -f /var/log/php$PHPVERSION-fpm.log
