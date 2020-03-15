#!/usr/bin/sh

#获取按物理位置排列的网口名
network_card_name_order_array=(`dmidecode -t 9 | grep 'Bus Address' | awk -F ':' '{ print "enp"strtonum("0x"$3)}' | tr "\n" " "`)
#echo ${network_card_name_order_array[@]}

#获取网卡名与NIC对应关系
eeupdate64e | grep 'Intel(R)' | awk '{ print "enp"$2"s0f"substr($4, 2,1)","$1}' | grep -v enp4 | sort -k 1 -t, > /workspace/tmp_data/enp-nic.csv

#生成网口名 nic 数据库id mac地址对应关系文件
rm -fr /workspace/tmp_data/enp-nic-sorted.csv
for i in "${!network_card_name_order_array[@]}";
do
    grep ${network_card_name_order_array[$i]} /workspace/tmp_data/enp-nic.csv >> /workspace/tmp_data/enp-nic-sorted.csv
done
paste -d, /workspace/tmp_data/enp-nic-sorted.csv /workspace/tmp_data/id_mac.data | sed 's/://g' > /workspace/tmp_data/enp-nic-id_mac.csv

#b遍历enp-nic-id_mac.csv文件，烧录mac
awk -F ',' '{ print "eeupdate64e /NIC="$2" /MAC="$4}' /workspace/tmp_data/enp-nic-id_mac.csv | sh
