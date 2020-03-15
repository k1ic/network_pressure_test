#!/usr/bin/sh
#ip尾号奇数机器启动iperf server

#获取管理口ip尾号
manager_ip=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}'`
manager_ip_tail=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}' | awk -F '.' '{ print $4}'`

#ip尾号偶数机器直接退出
val=`expr $manager_ip_tail % 2`
if [ $val -eq 0 ]
then
    exit 0
fi

#清除现有iperf server
ps -ef | grep iperf | grep -vE 'grep|iperf_server.sh' | awk '{ print "kill -9 "$2}' | sh

#启动iperf server
need_server_total=`wc -l /workspace/tmp_data/enp-nic-id_mac.csv | awk '{ print $1}'`
awk -F ',' '{ print "ifconfig "$1" | grep inet"}' /workspace/tmp_data/enp-nic-id_mac.csv | sh | awk '{ print "nohup iperf -s -p "10000+NR" -B "$2" -f M > /dev/null 2>&1 &"}' | sh

sleep 1s
running_server_total=`ps -ef | grep 'iperf -s' | grep -v grep | awk '{ if($3==1) print $0}' | awk '{ print $11}' | sort | uniq -c | wc -l`

if [ $running_server_total -eq $need_server_total ]
then
    echo "Tester:("$manager_ip") Iperf Server Start OK!"
else
    echo "Tester:("$manager_ip") Iperf Server Start Failed! Running Iperf Server Total:"$running_server_total"."
fi
