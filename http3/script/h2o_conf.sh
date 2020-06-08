#!/bin/sh
CMDFD='/opt/h2bench'
ENVFD="${CMDFD}/env"
ENVLOG="${ENVFD}/server/environment.log"
CUSTOM_WP="${ENVFD}/custom_wp"
SERVERACCESS="${ENVFD}/serveraccess.txt"
DOCROOT='/var/www/html'
NGDIR='/etc/nginx'
APADIR='/etc/apache2'
LSDIR='/usr/local/entlsws'
OLSDIR='/usr/local/lsws'
CADDIR='/etc/caddy'
HTODIR='/etc/h2o'
FPMCONF='/etc/php-fpm.d/www.conf'
USER=''
GROUP=''
CERTDIR='/etc/ssl'
MARIAVER='10.3'
PHP_P='7'
PHP_S='2'
REPOPATH=''
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
SERVER_LIST="apache lsws nginx openlitespeed caddy h2o"
DOMAIN_NAME='benchmark.com'
WP_DOMAIN_NAME='wordpress.benchmark.com'

echoY() {
    echo -e "\033[38;5;148m${1}\033[39m"
}
echoG() {
    echo -e "\033[38;5;71m${1}\033[39m"
}
echoR()
{
    echo -e "\033[38;5;203m${1}\033[39m"
}

check_os()
{
    OSTYPE=$(uname -m)
    MARIADBCPUARCH=
    if [ -f /etc/redhat-release ] ; then
        OSVER=$(cat /etc/redhat-release | awk '{print substr($4,1,1)}')
        if [ ${?} = 0 ] ; then
            OSNAMEVER=CENTOS${OSVER}
            OSNAME=centos
            rpm -ivh http://rpms.litespeedtech.com/centos/litespeed-repo-1.1-1.el${OSVER}.noarch.rpm >/dev/null 2>&1
        fi
    elif [ -f /etc/lsb-release ] ; then
        OSNAME=ubuntu
        wget -qO - http://rpms.litespeedtech.com/debian/enable_lst_debain_repo.sh | bash >/dev/null 2>&1
        UBUNTU_V=$(grep 'DISTRIB_RELEASE' /etc/lsb-release | awk -F '=' '{print substr($2,1,2)}')
        if [ ${UBUNTU_V} = 14 ] ; then
            OSNAMEVER=UBUNTU14
            OSVER=trusty
            MARIADBCPUARCH="arch=amd64,i386,ppc64el"
        elif [ ${UBUNTU_V} = 16 ] ; then
            OSNAMEVER=UBUNTU16
            OSVER=xenial
            MARIADBCPUARCH="arch=amd64,i386,ppc64el"
        elif [ ${UBUNTU_V} = 18 -o ${UBUNTU_V} = 19 ] ; then
            OSNAMEVER=UBUNTU18
            OSVER=bionic
            MARIADBCPUARCH="arch=amd64"
	elif [ ${UBUNTU_V} = 20 ] ; then
            OSNamever=UBUNTU20
	    OSVER=focal
	    MARIADBCPUARCH="arch=amd64"
        fi
    elif [ -f /etc/debian_version ] ; then
        OSNAME=debian
        wget -O - http://rpms.litespeedtech.com/debian/enable_lst_debain_repo.sh | bash
        DEBIAN_V=$(awk -F '.' '{print $1}' /etc/debian_version)
        if [ ${DEBIAN_V} = 7 ] ; then
            OSNAMEVER=DEBIAN7
            OSVER=wheezy
            MARIADBCPUARCH="arch=amd64,i386"
        elif [ ${DEBIAN_V} = 8 ] ; then
            OSNAMEVER=DEBIAN8
            OSVER=jessie
            MARIADBCPUARCH="arch=amd64,i386"
        elif [ ${DEBIAN_V} = 9 ] ; then
            OSNAMEVER=DEBIAN9
            OSVER=stretch
            MARIADBCPUARCH="arch=amd64,i386"
        elif [ ${DEBIAN_V} = 10 ] ; then
            OSNAMEVER=DEBIAN10
            OSVER=buster
        fi
    fi
    if [ "${OSNAMEVER}" = "" ] ; then
        echoR "Sorry, currently script only supports Centos(6-7), Debian(7-10) and Ubuntu(14,16,18,19,20)."
        exit 1
    else
        if [ "${OSNAME}" = "centos" ] ; then
            echoG "Current platform is ${OSNAME} ${OSVER}"
            if [ ${OSVER} = 8 ]; then
                echoR "Sorry, currently script only supports Centos(6-7), exit!!"
                ### Many package/repo are not ready for it.
                exit 1
            fi
        else
            export DEBIAN_FRONTEND=noninteractive
            echoG "Current platform is ${OSNAMEVER} ${OSNAME} ${OSVER}."
        fi
    fi
}

path_update(){
    if [ "${OSNAME}" = "centos" ] ; then
        USER='apache'
        GROUP='apache'
        REPOPATH='/etc/yum.repos.d'
        APACHENAME='httpd'
        APADIR='/etc/httpd'
        RED_VER=$(rpm -q --whatprovides redhat-release)
    elif [ "${OSNAME}" = 'ubuntu' ] || [ "${OSNAME}" = 'debian' ]; then
        USER='www-data'
        GROUP='www-data'
        REPOPATH='/etc/apt/sources.list.d'
        APACHENAME='apache2'
        FPMCONF="/etc/php/${PHP_P}.${PHP_S}/fpm/pool.d/www.conf"
    fi
}

prepare(){
    check_os
    path_update
}


prepare

if [ -e /etc/h2o/h2o.conf -a ! -e /etc/h2o/h2o.bak ]
then
	mv /etc/h2o/h2o.conf /etc/h2o/h2o.bak
fi
#sed -e 's=examples/h2o/server.crt=/etc/ssl/http2benchmark.crt=' -e 's=examples/h2o/server.key=/etc/ssl/http2benchmark.key=' -e 's/#listen:/listen:/' -e 's/#  <<:/  <<:/' -e 's/#  type: quic/  type: quic/'  < /usr/local/share/doc/h2o/examples/h2o/h2o.conf > /usr/local/etc/h2o.conf
# The PHP test was done during the build phase
PHP=`ls /var/run/php|grep .sock`
sed -e "s/php7.2-fpm.sock/$PHP/" -e 's=run/h2o.pid=tmp/h2o.pid=' -e "s/www-data/${USER}/g" -e '0,/listen:/! s/listen:/listen: \&ssl_listen/' -e 's/    cipher-suite: "ECDHE-ECDSA-AES128-GCM-SHA256"/    cipher-suite: "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256"/' -e '/neverbleed: OFF/ a\
\# The following three lines enable HTTP/3\
\listen:\
\  <<: *ssl_listen\
\  type: quic
' < ../../webservers/h2o/conf/h2o.conf > /etc/h2o/h2o.conf
