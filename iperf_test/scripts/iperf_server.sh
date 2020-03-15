#!/usr/bin/sh
#ip尾号奇数机器启动iperf server

transmit_time=$1
if [ -z $1 ]
then
    transmit_time=10
fi
sleep_time=`expr $transmit_time + 5`

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
network_card_name_order_array=(`dmidecode -t 9 | grep 'Bus Address' | awk -F ':' '{ print "enp"strtonum("0x"$3)}' | tr "\n" " "`)

#获取网卡名与NIC对应关系
eeupdate64e | grep 'Intel(R)' | awk '{ print "enp"$2"s0f"substr($4, 2,1)","$1}' | grep -v enp4 | sort -k 1 -t, > /workspace/tmp_data/enp-nic.csv

#生成网口名 nic 数据库id mac地址对应关系文件
rm -fr /workspace/tmp_data/enp-nic-sorted.csv
for i in "${!network_card_name_order_array[@]}";
do
    grep ${network_card_name_order_array[$i]} /workspace/tmp_data/enp-nic.csv >> /workspace/tmp_data/enp-nic-sorted.csv
done
paste -d, /workspace/tmp_data/enp-nic-sorted.csv /workspace/tmp_data/id_mac.data | sed 's/://g' > /workspace/tmp_data/enp-nic-id_mac.csv

#启动iperf server
need_server_total=`wc -l /workspace/tmp_data/enp-nic-id_mac.csv | awk '{ print $1}'`
awk -F ',' '{ print "ifconfig "$1" | grep inet"}' /workspace/tmp_data/enp-nic-id_mac.csv | sh | awk -v t_time=$transmit_time '{ print "nohup iperf -s -p "10000+NR" -B "$2" -f b 2>&1 | grep -E '\''connected|0.0-"t_time".0'\'' | tr '\''\\n'\'' '\'' '\'' > /workspace/tmp_data/"10000+NR".log 2>&1 &"}' | sh

sleep 1s
running_server_total=`ps -ef | grep 'iperf -s' | grep -v grep | awk '{ if($3==1) print $0}' | awk '{ print $11}' | sort | uniq -c | wc -l`

if [ $running_server_total -eq $need_server_total ]
then
    echo "Tester:("$manager_ip") Iperf Server Start OK!"
else
    echo "Tester:("$manager_ip") Iperf Server Start Failed! Running Iperf Server Total:"$running_server_total"."
fi
