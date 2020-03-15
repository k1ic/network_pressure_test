#!/usr/bin/sh

#获取管理口ip
manager_ip_tail=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}' | awk -F '.' '{ print $4}'`

ip_head=$manager_ip_tail
val=`expr $manager_ip_tail % 2`
if [ $val -eq 0 ]
then
    ip_head=`expr $manager_ip_tail - 1`
fi
ip_tail=$manager_ip_tail

#获取按物理位置排列的网口名
network_card_name_order_array=(`dmidecode -t 9 | grep 'Bus Address' | awk -F ':' '{ print "enp"strtonum("0x"$3)}' | tr "\n" " "`)
#echo ${network_card_name_order_array[@]}

for i in "${!network_card_name_order_array[@]}";
do
    real_index=`expr $i + 1`
    #for j in `netstat -i | grep ${network_card_name_order_array[$i]} | awk '{ print $1}'`; do echo "ip addr add "$ip_head"."$real_index"."${j: -1}"."$ip_tail"/24 dev "$j" valid_lft 86400 preferred_lft 86400;" ; done | sh
    for j in `netstat -i | grep ${network_card_name_order_array[$i]} | awk '{ print $1}'`; do echo "ifconfig "$j" "$ip_head"."$real_index"."${j: -1}"."$ip_tail" netmask 255.255.255.0;" ; done | sh
done
