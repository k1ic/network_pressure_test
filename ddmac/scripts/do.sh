#!/usr/bin/sh
b_running=`ps -ef | grep dddo.sh | grep -v ^$ grep | wc -l`
if [ $b_running_status -eq 1 ]
then 
    exit 0
fi

#检查tester机器数量，必须大于0
tester_total=`wc -l /etc/ansible/hosts | awk '{ print $1}'`
if [ $tester_total -eq 0 ]
then
    echo -e "\033[33mFatal Error: Must have greater than 0 machines, Now have "$tester_total" machines!\033[0m"
    exit 0
fi
echo -e "[1] Check Worker Total OK!\n"

#检查每台tester是否能ping通
ping_success_total=`ansible all -m ping | grep SUCCESS -c`
if [ $tester_total -ne $ping_success_total ]
then
    ansible all -m ping | grep UNREACHABLE | awk '{ print "\033[33m"$1" "$3"\033[0m"}'
    exit 0
fi
echo -e "[2] Ping All Worker OK!\n"

################################设置待测网口mac地址 start################################
#生成enp nic对应关系
gen_enp_nic_total=`ansible all -m shell -a "sh gen_enp-nic.sh chdir=/workspace/scripts" | grep SUCCESS -c`
if [ $tester_total -ne $gen_enp_nic_total ]
then
    echo -e "\033[33m[3-1] Generate Worker's enp-nic.csv Failed!\033[33m"
    exit 0
fi
echo -e "[3-1] Generate Worker's enp-nic.csv OK!"

#计算需要获取的mac地址总数
need_mac_total=`ansible all -m shell -a "wc -l /workspace/tmp_data/enp-nic.csv" | grep enp-nic.csv | awk '{ c+=$1; } END { print c}'`

#计算每台测试机需要多少mac地址
each_tester_mac_total=`expr $need_mac_total / $tester_total`

#获取id,mac
#id_mac_array=(`mysql -uroot network_card_test -N -e "select id,mac_addr from mac_address_use_record where mac_addr_use_status = 0 order by id asc limit $need_mac_total;" | tr "\t" "," | grep -v ^$| tr "\n" " "`)
id_mac_array=(`mysql -uroot network_card_test -N -e "select id,mac_addr from mac_address_use_record where mac_addr_use_status = 0 and mac_addr >= '68:91:d0:00:00:00' and mac_addr <= '68:91:d0:ff:ff:ff' order by id asc limit $need_mac_total;" | tr "\t" "," | grep -v ^$| tr "\n" " "`)
if [ $need_mac_total -ne ${#id_mac_array[@]} ]
then
    echo -e "\033[33m[3-1-1] Get Mac Address Failed! Need Mac Total:"$need_mac_total", Queried Mac Total:"${#id_mac_array[@]}".\033[33m"
    exit 0
fi

#获取tester ip数组
tester_ip_array=(`cat /etc/ansible/hosts | tr "\n" " "`)

#生成本地文件
rm -fr /workspace/tmp_data/*.data
for i in "${!id_mac_array[@]}";
do
    tmp_str="$tmp_str $id_mac_total"
    ip_index=`expr $i / $each_tester_mac_total`
    echo ${id_mac_array[$i]} >> /workspace/tmp_data/${tester_ip_array[$ip_index]}.data
done

#scp到目标机器
echo -e "[3-2-1] Begin to scp id_mac.data to Worker."
for i in "${!tester_ip_array[@]}"
do
    echo "scp /workspace/tmp_data/${tester_ip_array[$i]}.data root@${tester_ip_array[$i]}:/workspace/tmp_data/id_mac.data" | sh > /dev/null 2>&1
done
echo -e "[3-2-2] Scp id_mac.data to Worker OK!"

arr=(`echo ${id_mac_array[0]} | tr ',' ' '`)
start_mac=${arr[-1]}
arr=(`echo ${id_mac_array[-1]} | tr ',' ' '`)
end_mac=${arr[-1]}

##烧录mac
echo -e "[3-3-1] Begin to Set Worker's External Network Card Mac Address, Start_Mac:("$start_mac"), End_Mac:("$end_mac"), Mac_Total:"${#id_mac_array[@]}"."
write_succ_mac_total=`ansible all -m shell -a "sh set_wait_test_network_card_mac.sh chdir=/workspace/scripts" | grep Updating | grep -c 'Mac Address'`
if [ $need_mac_total -ne $write_succ_mac_total ]
then
    echo -e "\033[33m[3-3-2] Set Worker's External Network Card Mac Address Failed!\033[33m"
Server:192.168.0.11 Client:192.168.0.12 These Card Port Need Review enp10s0f0,enp129s0f0
11.1.0.12:45750 to 11.1.0.11:10001 0.0-300.0 sec Transfer:70.0 GBytes Bandwidth:2.01 Gbits/sec | 11.1.0.12:10001 to 11.1.0.11:60246 0.0-300.0 sec Transfer:74.1 GBytes Bandwidth:2.12 Gbits/sec
11.1.1.12:59024 to 11.1.1.11:10002 0.0-300.0 sec Transfer:67.6 GBytes Bandwidth:1.94 Gbits/sec | 11.1.1.12:10002 to 11.1.1.11:39592 0.0-300.0 sec Transfer:68.1 GBytes Bandwidth:1.95 Gbits/sec
11.1.2.12:41572 to 11.1.2.11:10003 0.0-300.0 sec Transfer:69.1 GBytes Bandwidth:1.98 Gbits/sec | 11.1.2.12:10003 to 11.1.2.11:43866 0.0-300.0 sec Transfer:69.3 GBytes Bandwidth:1.98 Gbits/sec
11.1.3.12:38668 to 11.1.3.11:10004 0.0-300.0 sec Transfer:69.9 GBytes Bandwidth:2.00 Gbits/sec | 11.1.3.12:10004 to 11.1.3.11:48488 0.0-300.0 sec Transfer:73.5 GBytes Bandwidth:2.11 Gbits/sec
11.2.0.12:55974 to 11.2.0.11:10005 0.0-300.0 sec Transfer:71.8 GBytes Bandwidth:2.06 Gbits/sec | 11.2.0.12:10005 to 11.2.0.11:58078 0.0-300.0 sec Transfer:69.6 GBytes Bandwidth:1.99 Gbits/sec
11.2.1.12:53744 to 11.2.1.11:10006 0.0-300.0 sec Transfer:72.4 GBytes Bandwidth:2.07 Gbits/sec | 11.2.1.12:10006 to 11.2.1.11:51712 0.0-300.0 sec Transfer:70.8 GBytes Bandwidth:2.03 Gbits/sec
11.2.2.12:43076 to 11.2.2.11:10007 0.0-300.0 sec Transfer:70.4 GBytes Bandwidth:2.01 Gbits/sec | 11.2.2.12:10007 to 11.2.2.11:48548 0.0-300.0 sec Transfer:73.6 GBytes Bandwidth:2.11 Gbits/sec
11.2.3.12:51872 to 11.2.3.11:10008 0.0-300.0 sec Transfer:72.9 GBytes Bandwidth:2.09 Gbits/sec | 11.2.3.12:10008 to 11.2.3.11:49048 0.0-300.0 sec Transfer:72.0 GBytes Bandwidth:2.06 Gbits/sec
11.3.0.12:10009 to 11.3.0.11:10009   Transfer:  Bandwidth:  | sec:GBytes to :   Transfer:  Bandwidth:
11.3.1.12:47248 to 11.3.1.11:10010 0.0-300.0 sec Transfer:65.8 GBytes Bandwidth:1.88 Gbits/sec | 11.3.1.12:10010 to 11.3.1.11:34446 0.0-300.0 sec Transfer:72.4 GBytes Bandwidth:2.07 Gbits/sec
11.3.2.12:37294 to 11.3.2.11:10011 0.0-300.0 sec Transfer:69.6 GBytes Bandwidth:1.99 Gbits/sec | 11.3.2.12:10011 to 11.3.2.11:35632 0.0-300.0 sec Transfer:72.6 GBytes Bandwidth:2.08 Gbits/sec
11.3.3.12:59586 to 11.3.3.11:10012 0.0-300.0 sec Transfer:66.6 GBytes Bandwidth:1.91 Gbits/sec | 11.3.3.12:10012 to 11.3.3.11:33122 0.0-300.0 sec Transfer:70.8 GBytes Bandwidth:2.03 Gbits/sec
11.4.0.12:36094 to 11.4.0.11:10013 0.0-300.0 sec Transfer:65.7 GBytes Bandwidth:1.88 Gbits/sec | 11.4.0.12:10013 to 11.4.0.11:41164 0.0-300.0 sec Transfer:71.0 GBytes Bandwidth:2.03 Gbits/sec
11.4.1.12:42120 to 11.4.1.11:10014 0.0-300.0 sec Transfer:68.5 GBytes Bandwidth:1.96 Gbits/sec | 11.4.1.12:10014 to 11.4.1.11:54250 0.0-300.0 sec Transfer:74.3 GBytes Bandwidth:2.13 Gbits/sec
11.4.2.12:38482 to 11.4.2.11:10015 0.0-300.0 sec Transfer:69.2 GBytes Bandwidth:1.98 Gbits/sec | 11.4.2.12:10015 to 11.4.2.11:55532 0.0-300.0 sec Transfer:73.8 GBytes Bandwidth:2.11 Gbits/sec
11.4.3.12:52892 to 11.4.3.11:10016 0.0-300.0 sec Transfer:66.9 GBytes Bandwidth:1.92 Gbits/sec | 11.4.3.12:10016 to 11.4.3.11:60800 0.0-300.0 sec Transfer:66.9 GBytes Bandwidth:1.92 Gbits/sec
11.5.0.12:10017 to 11.5.0.11:10017   Transfer:  Bandwidth:  | sec:GBytes to :   Transfer:  Bandwidth:
11.5.1.12:53786 to 11.5.1.11:10018 0.0-300.0 sec Transfer:65.7 GBytes Bandwidth:1.88 Gbits/sec | 11.5.1.12:10018 to 11.5.1.11:33356 0.0-300.0 sec Transfer:68.5 GBytes Bandwidth:1.96 Gbits/sec
11.5.2.12:51156 to 11.5.2.11:10019 0.0-300.0 sec Transfer:68.4 GBytes Bandwidth:1.96 Gbits/sec | 11.5.2.12:10019 to 11.5.2.11:40676 0.0-300.0 sec Transfer:73.2 GBytes Bandwidth:2.10 Gbits/sec
11.5.3.12:52526 to 11.5.3.11:10020 0.0-300.0 sec Transfer:69.9 GBytes Bandwidth:2.00 Gbits/sec | 11.5.3.12:10020 to 11.5.3.11:40754 0.0-300.0 sec Transfer:72.1 GBytes Bandwidth:2.06 Gbits/sec
11.6.0.12:51000 to 11.6.0.11:10021 0.0-300.0 sec Transfer:68.0 GBytes Bandwidth:1.95 Gbits/sec | 11.6.0.12:10021 to 11.6.0.11:41796 0.0-300.0 sec Transfer:75.3 GBytes Bandwidth:2.16 Gbits/sec
11.6.1.12:44914 to 11.6.1.11:10022 0.0-300.0 sec Transfer:67.0 GBytes Bandwidth:1.92 Gbits/sec | 11.6.1.12:10022 to 11.6.1.11:54740 0.0-300.0 sec Transfer:71.9 GBytes Bandwidth:2.06 Gbits/sec
11.6.2.12:50238 to 11.6.2.11:10023 0.0-300.0 sec Transfer:65.8 GBytes Bandwidth:1.88 Gbits/sec | 11.6.2.12:10023 to 11.6.2.11:42570 0.0-300.0 sec Transfer:70.7 GBytes Bandwidth:2.02 Gbits/sec
11.6.3.12:43660 to 11.6.3.11:10024 0.0-300.0 sec Transfer:65.5 GBytes Bandwidth:1.88 Gbits/sec | 11.6.3.12:10024 to 11.6.3.11:47480 0.0-300.0 sec Transfer:73.9 GBytes Bandwidth:2.11 Gbits/sec
    exit 0
fi
echo -e "[3-3-2] Set Worker's External Network Card Mac Address OK!"

#重启所有Worker以便mac地址生效
echo -e "[3-4-1] Begin to Reabooting All Worker."
ansible all -m shell -a "reboot" > /dev/null 2>&1 

#等待所有Worker重启
echo -e "[3-4-2] Reabooting All Worker, waiting..."
while [ `ansible all -m ping | grep SUCCESS -c` -ne $tester_total ]
do
    pang_total=`ansible all -m ping | grep SUCCESS -c`
    if [ $tester_total -eq $pang_total ]
    then
        sleep 20s
        break
    fi
    sleep 2s
done
echo -e "[3-4-3] Reabooting All Worker OK!"

#校验mac地址并更新数据库
echo -e "[3-4-4] Begin To Check Mac Address and Update to DB."
update_db_total=`ansible all -m shell -a "sh check_wait_test_network_card_mac.sh chdir=/workspace/scripts" | grep -c 'Fatal Error'`
if [ $update_db_total -gt 0 ]
then
    ansible all -m shell -a "sh check_wait_test_network_card_mac.sh chdir=/workspace/scripts" | grep 'Fatal Error' | awk '{ print "\033[33m"$0"\033[0m"}'
    exit 0
fi
echo -e "[3-4-5] Check Mac Address and Update to DB OK, Mac Address Set Success!\n"
#################################设置待测网口mac地址   end################################

