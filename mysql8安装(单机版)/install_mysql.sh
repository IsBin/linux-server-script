#!/bin/bash
set -e

for tmp in `rpm -qa | grep mysql`
do
	rpm -e $tmp
	echo "删除$tmp"
done

download_url=https://cdn.mysql.com/archives/mysql-8.0/mysql-8.0.31-linux-glibc2.12-x86_64.tar.xz

wget $download_url -O /usr/local/mysql.tar.xz

mkdir -p /usr/local/mysql
tar -xvf /usr/local/mysql.tar.xz -C /usr/local/mysql --strip-components 1

set +e
groups mysql
set -e

if test $? -eq 1
then
	echo "不存在组和用户，新建中..."
	groupadd mysql && useradd -r -g mysql mysql
else
	echo "已存在mysql用户和组"
fi

mkdir -p /data/mysql
chown mysql:mysql -R /data/mysql

mycnf_content="\
[mysqld]\n\
bind-address=0.0.0.0\n\
port=3306\n\
user=mysql\n\
basedir=/usr/local/mysql\n\
datadir=/data/mysql\n\
socket=/tmp/mysql.sock\n\
lower_case_table_names = 0\n\
\n\
#character config\n\
character_set_server=utf8mb4\n\
symbolic-links=0\n\
explicit_defaults_for_timestamp=true\n\
\n\
[mysqld_safe]\n\
log-error=/data/mysql/mysql.err\n\
pid-file=/data/mysql/mysql.pid\n\
"


echo -e $mycnf_content > /etc/my.cnf

cd /usr/local/mysql/bin/
./mysqld --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql/ --datadir=/data/mysql/ --user=mysql --initialize

cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
echo "启动MySQL服务中..."
service mysql start

sed -i '/\[mysqld\]/a\skip-grant-tables' /etc/my.cnf
echo "重启MySQL服务中..."
service mysql restart

echo "数据库安装成功，等待重置root密码"

mysql_password=$1
if [ -n "$mysql_password" ]
then
	echo "密码为$1"
else
	echo "用户没有设置密码，初始化密码为123456"
	mysql_password=123456
fi

echo "use mysql;UPDATE mysql.user SET authentication_string='' where User='root' and Host='localhost';FLUSH PRIVILEGES;" | /usr/local/mysql/bin/mysql -uroot -p11

sed  -i "s/^.*skip-grant-tables/#&/g" /etc/my.cnf
echo "重启MySQL服务中..."
service mysql restart

echo "请按下回车键继续"
echo "use mysql;ALTER  User 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '$mysql_password';FLUSH PRIVILEGES;" | /usr/local/mysql/bin/mysql -uroot -p 

echo "重置密码成功，密码为$mysql_password"
