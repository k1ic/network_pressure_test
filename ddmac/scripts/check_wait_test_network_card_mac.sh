#!/usr/bin/sh

manager_ip=`ifconfig enp4s0f0 | grep 'inet ' | awk '{ print $2}'`

#写入前的mac
awk -F ',' '{ print $4}' /workspace/tmp_data/enp-nic-id_mac.csv > /workspace/tmp_data/mac_set.tmp

#获取按物理位置排列的网口名
network_card_name_order_array=(`awk -F ',' '{ print $1}' /workspace/tmp_data/enp-nic-sorted.csv`)
#echo ${network_card_name_order_array[@]}

#按网卡物理顺序读取mac地址
rm -fr /workspace/tmp_data/mac_got.tmp
for i in "${!network_card_name_order_array[@]}";
do
    ifconfig ${network_card_name_order_array[$i]} | grep ether | awk '{ print toupper($2)}' | sed 's/://g' >> /workspace/tmp_data/mac_got.tmp
done

#对比mac
md5_set=`md5sum /workspace/tmp_data/mac_set.tmp | awk '{ print $1}'`
md5_got=`md5sum /workspace/tmp_data/mac_got.tmp | awk '{ print $1}'`
if [ $md5_set != $md5_got ]
then
    echo "Fatal Error: Tester("$manager_ip") External Network Card Mac Address Set Error!"
    exit 0
fi

#删除临时文件
rm -fr /workspace/tmp_data/mac_got.tmp /workspace/tmp_data/mac_got.tmp

#更新到数据库
current=`date "+%Y-%m-%d %H:%M:%S"`
time_stamp=`date -d "$current" +%s`

awk -v mip=$manager_ip -v now_tp=$time_stamp -F ',' '{ print "update mac_address_use_record set mac_addr_use_status = 1, tester_ip = '\''"mip"'\'', network_card_name = '\''"$1"'\'', updatetime = "now_tp" where id = "$3";"}' /workspace/tmp_data/enp-nic-id_mac.csv > /workspace/tmp_data/update.sql

timeout 9 mysql -h192.168.0.4 -P3306 -uroot -p1qaz2wsx network_card_test -N --batch -e "`cat /workspace/tmp_data/update.sql`" 2>&1 | grep ERROR -c | awk -v mip=$manager_ip '{ if($1>0) {print "Fatal Error: Tester("$manager_ip") External Network Card Mac Address Update DB Failed!"} else {print "Update DB OK!"} }'

