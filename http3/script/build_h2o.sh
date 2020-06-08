#!/bin/sh
  
cd `dirname "$0"`

apt -y install cmake build-essential openssl libssl-dev zlib1g zlib1g-dev pkg-config libuv1-dev libwslay-dev php php-fpm
ls /var/run/php|grep .sock
if [ $? -ne 0 ] ;
then
	echo "PHP not properly installed; verify install of all requirements was successful"
	exit 1
fi
mkdir ../src
cd  ../src
git clone https://github.com/h2o/h2o.git
cd h2o
cmake .
make 
if [ ! -e h2o ] ; then
	echo "Build failed.  See above"
	exit 1
fi
if [ -e /usr/bin/h2o -a ! -e /usr/bin/h2o.dist ] ; then
	mv /usr/bin/h2o /usr/bin/h2o.dist
fi
cp h2o /usr/bin/h2o
cd ../../script


