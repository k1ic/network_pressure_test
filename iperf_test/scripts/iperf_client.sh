#!/usr/bin/sh
#ip尾号偶数机器启动iperf client

transmit_time=$1
if [ -z $1 ]
then
    transmit_time=10
fi
sleep_time=`expr $transmit_time + 10`
#capacity=$2

#获取管理口ip尾号
manager_ip=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}'`
manager_ip_tail=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}' | awk -F '.' '{ print $4}'`

iperf_server_ip_tail=`expr $manager_ip_tail - 1`
iperf_server_ip_pre=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}' | awk -F '.' '{ print $1"."$2"."$3}'`
iperf_server_ip=$iperf_server_ip_pre"."$iperf_server_ip_tail

val=`expr $manager_ip_tail % 2`
if [ $val -ne 0 ]
then
    exit 0
fi

#计算网卡额定容量
#万兆
var=`lspci | grep Ethernet | grep -v ^04: | awk '{ print $10}' | uniq -c | awk '{ print $0}' | awk '{ print $2}'`
if [ $var = "10GbE" ]
then
    rated='2000'
fi
#千兆
var=`lspci | grep Ethernet | grep -v ^04: | awk '{ print $7}' | uniq -c | awk '{ print $0}' | awk '{ print $2}'`
if [ $var = "Gigabit" ]
then
    rated='900'
fi

#清除现有iperf client
ps -ef | grep iperf | grep -vE 'grep|iperf_client.sh' | awk '{ print "kill -9 "$2}' | sh

#启动iperf client
need_client_total=`wc -l /workspace/tmp_data/enp-nic-id_mac.csv | awk '{ print $1}'`

#执行 iperf client 命令
awk -F ',' '{ print "ifconfig "$1" | grep inet"}' /workspace/tmp_data/enp-nic-id_mac.csv | sh | awk '{ print $2}' | awk -v t_time=$transmit_time -F '.' '{ip_s=$1"."$2"."$3"."$4-1; ip_c=$0; print "nohup iperf -c "ip_s" -p "10000+NR" -B "ip_c" -f a -d  -i 1 -t "t_time" 2>&1 | grep -E '\''connected|0.0-"t_time".0'\'' | tr '\''\\n'\'' '\'' '\'' > /workspace/tmp_data/"10000+NR".log 2>&1 &"}' | sh

sleep $sleep_time
ps -ef | grep iperf | grep -vE 'grep|iperf_client.sh' | awk '{ print "kill -9 "$2}' | sh

#检查是否有不合格网口
defective_array=(`awk -v rated=$rated '{ if($18<rated) print $4}' /workspace/tmp_data/100*.log | tr "\n" " "`)
if [ ${#defective_array[@]} -gt 0 ]
then
    grep -E `awk -v rated=$rated '{ if($18<rated) print $4}' /workspace/tmp_data/100*.log | tr "\n" "|" | sed 's/|$//g'` /workspace/tmp_data/enp-ip.csv | awk -F ',' '{ print $1}' | tr "\n" "," | sed 's/,$//g' | awk -v manager_ip=$manager_ip -v iperf_server_ip=$iperf_server_ip '{ print "\033[33mServer:"iperf_server_ip" Client:"manager_ip" These Card Port Need Review "$0"\033[0m"}'
else
    echo "Server:"$iperf_server_ip" Client:"$manager_ip" All Card Port Test OK!"
fi

sed 's/$/\n/g' /workspace/tmp_data/100*.log | grep -v ^$ | awk '{ print $4":"$6" to "$9":"$11" "$25" "$26" Transfer:"$27" "$28" Bandwidth:"$29" "$30" | "$15":"$17" to "$20":"$22" "$33" "$34" Transfer:"$35" "$36" Bandwidth:"$37" "$38}'
