#!/bin/bash

set -e

if [ -n "$1" ]
then
	wget "$1" -O /usr/local/jdk.tar.gz
	mkdir -p /usr/local/jdk
	tar -zxvf /usr/local/jdk.tar.gz -C /usr/local/jdk --strip-components 1

	echo 'export JAVA_HOME=/usr/local/jdk'>>/etc/profile
	echo 'export PATH=$JAVA_HOME/bin:$PATH'>>/etc/profile
	echo 'export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar'>>/etc/profile

	source /etc/profile
	echo "JDK配置完毕，输入java -version可验证是否成功"
else
	echo "下载链接不能为空"
fi
