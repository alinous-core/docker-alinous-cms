#!/bin/bash

# Variables
DATA_DIR=/var/lib/pgsql/data

#start postgreSQL
echo "starting postgreSQL ... "

su postgres -c "pg_ctl -D $DATA_DIR -l ${DATA_DIR}/logfile start"

echo "started postgreSQL"

# setup Alinous and Tomcat
export ALINOUS_HOME=/opt/work/ALINOUS_HOME/
cd /usr/local/tomcat/bin/ && ./startup.sh

function tomcat_ready {
  ret=1;
  while [ $ret -ne 0 ]
  do
    ret=$(curl -k http://localhost:8080/install/install.html)
    
    if [ -z $ret ]
    then
      ret=1
    fi
  done
}

tomcat_ready


# sshd
/usr/sbin/sshd -D &

# keep the stdin
/bin/bash



