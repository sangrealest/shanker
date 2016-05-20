#!/bin/bash
#Author:Shanker
#Time:20160511

#set -e
#set -x
#set -u


function usage(){
    cat <<EOF

usage:$0 [options] [pattern]
    -h  Help;
    -m  Master hostname or ip address;
    -s  Slave hostname or ip address;
    -n  Configure how many instances, if the port is 3306, n should be 1, port is 3307, n shoule be 2 and so on..;
    -p  Password to access your database;
    -f  Do not install mysql, only configre master-slave;
EOF
exit
}



function limitsConf(){
sed -i "/nproc/d"  /etc/security/limits.conf
sed -i "/nofile/d"  /etc/security/limits.conf
echo "*        soft    nproc           65535" >> /etc/security/limits.conf
echo "*        hard    nproc           65535" >> /etc/security/limits.conf
echo "*        soft    nofile           65535" >> /etc/security/limits.conf
echo "*        hard    nofile           65535" >> /etc/security/limits.conf

if [ -f /etc/security/limits.d/90-nproc.conf ]
then
  sed -i "/nproc/d"  /etc/security/limits.d/90-nproc.conf
  echo "*        soft    nproc           65535" >> /etc/security/limits.d/90-nproc.conf
  echo "*        hard    nproc           65535" >> /etc/security/limits.d/90-nproc.conf
fi
}

function setConf(){

sed  -i  "/\/usr\/local\/mysql${PORT}\/bin/"d /etc/profile

echo "export PATH=/usr/local/mysql${PORT}/bin:\$PATH ">> ~/.bashrc

/sbin/sysctl -p

cp -a  mysql.server /etc/init.d/mysqld${PORT}

sed -i "s#/usr/local/mysql#/usr/local/mysql${PORT}#" /etc/init.d/mysqld${PORT}

sed -i "s#/data/mysql/mysqldata/data#/data/mysql${PORT}/mysqldata/data#" /etc/init.d/mysqld${PORT}

}

function startMysql(){

chmod +x /etc/init.d/mysqld${PORT}
/sbin/chkconfig --add mysqld${PORT}
/sbin/chkconfig mysqld${PORT} on
/etc/init.d/mysqld${PORT} start

}

function secureMysql(){

if [ "$TYPE" == 'slave' ];then
    mysqldir=/usr/local/mysql${PORT}/bin
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock   -e "delete from mysql.user where user='';"
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock    -e "delete from mysql.user where host='';"
    $mysqldir/mysql -S /tmp/mysql${PORT}.sock    -e "grant all on *.* to root@'127.0.0.1' identified by '$PSWD'"
    $mysqldir/mysqladmin -S /tmp/mysql${PORT}.sock    password  $PSWD

    if [ "$PSWD" == '' ];then
        /usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock -e "use mysql"
        FLAG=$?
    else
        /usr/local/mysql${PORT}/bin/mysql -S /tmp/mysql${PORT}.sock  -uroot -p$PSWD  -e "use mysql"
        FLAG=$?
    fi

else
    mysqldir=/usr/local/mysql/bin
    $mysqldir/mysql  -e "delete from mysql.user where user='';"
    $mysqldir/mysql  -e "delete from mysql.user where host='';"
    $mysqldir/mysql  -e "grant all on *.* to root@'127.0.0.1' identified by '$PSWD'"
    $mysqldir/mysqladmin  password  $PSWD

    if [ "$PSWD" == '' ];then
        /usr/local/mysql${PORT}/bin/mysql   -e "use mysql"
        FLAG=$?
    else
        /usr/local/mysql${PORT}/bin/mysql  -uroot -p$PSWD  -e "use mysql"
        FLAG=$?
    fi

fi
}


NUM=''
PORT=''

while getopts ":t:n:p:t:h" opts
do
    case $opts in
        h)
            usage
            ;;
        t)
            TYPE=$OPTARG
            if ! [ "$TYPE" == 'master'  -o "$TYPE" == 'slave' ]
            then
                usage
            fi
            ;;
        n)
            NUM=$OPTARG
            ;;
        p)
            PSWD=$OPTARG
            ;;
        :)
            echo "No argument value for option $OPTARG"
            ;;
        *)
            echo "Unknow error while processing options"
            -$OPTARG unvalid
            usage
            ;;
    esac
done

if [[ $NUM != '' ]];then
    PORT=`expr 3305 + $NUM`
fi

#before install mysql, clear potential folders
rm -rf /etc/init.d/mysqld${PORT}
rm -rf /data/mysql${PORT}
rm -rf /usr/local/mysql${PORT}

grep mysql /etc/passwd >/dev/null

if [ "$?" -ne 0 ];then
    useradd mysql
fi

if [ ! -d /usr/loal/mysql${PORT} ];then

        mkdir /usr/local/mysql${PORT}
fi

for i in redolog slowquery binlog relaylog
do
    mkdir -p /data/mysql${PORT}/mysqllog/$i
done

for j in data ibdata
do
    mkdir -p /data/mysql${PORT}/mysqldata/$j
done


MYSQLFILE=$(ls |grep *.tar.gz)
MYSQLDIR=$(echo $MYSQLFILE|sed 's/.tar.gz//')

if [ ! -d "$MYSQLDIR" ];then
        tar xvf $MYSQLFILE
fi
mv -f $MYSQLDIR/* /usr/local/mysql${PORT}
rm -rf $MYSQLDIR


FREEMEM1=$(awk 'NR==1{print int($2/1024*0.2)}' /proc/meminfo)
INNODB_BUTTER_POOL_SIZE_SLAVE=$(echo $FREEMEM1|awk '{if($1 > 1024) {printf "%d%s" ,int($1/1024),"G" } else {printf "%d%s",($1),"M"} }')

FREEMEM2=$(awk 'NR==1{print int($2/1024*0.2)}' /proc/meminfo)
INNODB_BUTTER_POOL_SIZE_MASTER=$(echo $FREEMEM2|awk '{if($1 > 1024) {printf "%d%s" ,int($1/1024),"G" } else {printf "%d%s",($1),"M"} }')



if [ "$TYPE" == 'slave' ]
then
    cp -a myconfile /usr/local/mysql${PORT}/my.cnf
    sed -i '/^server-id/ c server-id = 2' /usr/local/mysql${PORT}/my.cnf
    sed -i "s#/var/log/mysql#/data/mysql${PORT}#" /usr/local/mysql${PORT}/my.cnf
    sed -i "/^socket/ c socket     = /tmp/mysql${PORT}.sock" /usr/local/mysql${PORT}/my.cnf
    sed -i "/^port/ c port =  ${PORT}"  /usr/local/mysql${PORT}/my.cnf
    sed -i "/^innodb_buffer_pool_size/ c innodb_buffer_pool_size = ${INNODB_BUTTER_POOL_SIZE_SLAVE}" /usr/local/mysql${PORT}/my.cnf

    setConf

elif [ "$TYPE" == 'master' ]

then
    cp -a myconfile /etc/my.cnf
    sed -i "/^innodb_buffer_pool_size/ c innodb_buffer_pool_size = ${INNODB_BUTTER_POOL_SIZE_MASTER}" /etc/my.cnf
    sed -i "s#/var/log#/data#" /etc/my.cnf

    setConf

fi

chown -R mysql:mysql /usr/local/mysql${PORT}
chown -R mysql:mysql /data/mysql${PORT}

/usr/local/mysql${PORT}/scripts/mysql_install_db  --basedir=/usr/local/mysql${PORT} --datadir=/data/mysql${PORT}/mysqldata/data  --user=mysql

limitsConf

startMysql

secureMysql

if [ "$FLAG" -eq 0  ]
then
    echo -e "\033[35m finished installation Mysql \033[0m"
    echo -e "\033[35m 1. already set chkconfig mysqld on \033[0m"
    echo -e "\033[35m 2. usage /etc/init.d/mysqld${PORT} {start|stop|restart|reload|force-relad|status} \033[0m"
    echo -e "\033[35m 3. the path of mysql /usr/loca/mysql${PORT}/bin/mysql \033[0m"
    echo -e "\033[35m 4. open a new session use mysql -S /tmp/mysql${PORT}.sock -uroot -p enter mysql. \033[0m"
    echo -e "\033[35m 5. the password of root :$PSWD \033[0m"
else
    echo -e "\033[31m \033[05m failed to install mysql \033[0m"
    exit 1
fi
