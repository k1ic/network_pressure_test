#!/usr/bin/sh

if [ -z $1 ]
then
    echo -e "\033[33mPlease Set The Test Duration In Seconds! For Example: ./do.sh 20\033[0m"
    exit 0
fi
test_duration=$1

#检查tester机器数量，必须为偶数台
tester_total=`wc -l /etc/ansible/hosts | awk '{ print $1}'`
server_tester_total=`expr $tester_total / 2`
client_tester_total=`expr $tester_total / 2`
val=`expr $tester_total % 2`
if [ $val -ne 0 ]
then
    echo -e "\033[33mFatal Error: Must have even number of machines, Now have "$tester_total" machines!\033[0m"
    exit 0
fi
echo -e "[1] Check Tester total OK!\n"

#检查每台tester是否能ping通
ping_success_total=`ansible all -m ping | grep SUCCESS -c`
if [ $tester_total -ne $ping_success_total ]
then
    ansible all -m ping | grep UNREACHABLE | awk '{ print "\033[33m"$1" "$3"\033[0m"}'
    exit 0
fi
echo -e "[2] Ping All Tester OK!\n"

################################设置待测网口ip start################################
#为每台的所有待测网口设置ip
#sleep 180
echo -e "[3-1-1] Begin to Set All Wait Test Network Card IP."
set_ip_total=`ansible all -m shell -a "sh set_wait_test_network_card_ip.sh chdir=/workspace/scripts" | grep -c SUCCESS`
sleep 3
set_ip_total=`ansible all -m shell -a "sh set_wait_test_network_card_ip.sh chdir=/workspace/scripts" | grep -c SUCCESS`
if [ $set_ip_total -ne $tester_total ]
then
    ansible all -m shell -a "sh set_wait_test_network_card_ip.sh chdir=/workspace/scripts" | grep FAILED | awk '{ print "\033[33m"$1" Run set_wait_test_network_card_ip.sh Failed!\033[0m"}'
    exit 0
fi
echo -e "[3-1-2] Set All Wait Test Network Card IP OK!"

#生成每台tester的enp、ip、mac、nic对应关系
echo -e "[3-2-1] Begin to Check All Tester's External Network Card IP."
sleep 9
gen_succ_total=`ansible all -m shell -a "sh ./gen_enp-nic-mac-ip.sh chdir=/workspace/scripts" | grep -c SUCCESS`
if [ $gen_succ_total -ne $tester_total ]
then
    ansible all -m shell -a "sh ./gen_enp-nic-mac-ip.sh chdir=/workspace/scripts" | grep FAILED | awk '{ print "\033[33m"$1" Run gen_enp-nic-mac-ip.sh Failed!\033[0m"}'
    exit 0
fi

#检查每台tester待测试网卡是否都有ip
tester_ip_not_full=`ansible all -m shell -a "sh check_wait_test_network_card_ip.sh chdir=/workspace/scripts" | sed 'N;s/\n/ /' | grep 'Fatal Error' -c`
if [ $tester_ip_not_full -gt 0 ]
then
    echo -e "\033[33m[3-2-2] Please Check These Tester's External Network Card IP!\033[0m"
    ansible all -m shell -a "sh check_wait_test_network_card_ip.sh chdir=/workspace/scripts" | sed 'N;s/\n/ /' | grep 'Fatal Error' | sed 's/| SUCCESS | rc=0 >> //g'
    exit 0
fi
echo -e "[3-2-2] Check All Tester's External Network Card IP OK!\n"
############################设置待测网口ip   end################################

################################进行iperf测试 start################################
echo -e "[4-1-1] Begin To Start Tester Iperf Server"
iperf_server_tester_total=`ansible all -m shell -a "sh iperf_server.sh $test_duration chdir=/workspace/scripts" | grep 'Iperf Server Start OK!' -c`
if [ $server_tester_total -ne $iperf_server_tester_total ]
then
    echo -e "\033[33m[4-1-2] These Tester's Iperf Server Start Failed! Please Check\033[0m"
    ansible all -m shell -a "sh iperf_server.sh chdir=/workspace/scripts" | grep 'Iperf Server Start Failed'
    exit 0
fi
echo -e "[4-1-2] Tester Iperf Server Start OK! Tester Iperf Server Total: "$server_tester_total"."

echo -e "[4-2-1] Begin To Start Tester Iperf Client"
cur_datetime=`date +%Y%m%d%H%m%S`
iperf_client_res_log='/workspace/tmp_data/iperf_client_res_'$cur_datetime'.log'
ansible all -m shell -a "sh iperf_client.sh $test_duration chdir=/workspace/scripts" | grep -v SUCCESS | grep -v ^$ > $iperf_client_res_log

#获取所有机器所有网口的ip mac对应关系
ip_mac_file='/workspace/tmp_data/ip_mac.csv'
ansible all -m shell -a "sh get_ip_mac.sh chdir=/workspace/scripts" | grep -vE 'SUCCESS|^$' > $ip_mac_file
awk -v iperf_client_res_log=$iperf_client_res_log -F ',' '{ print "sed -i '\''s/"$1"/("$2")"$1"/g'\'' "iperf_client_res_log }' $ip_mac_file | sh

echo -e "[4-2-2] The Following Is A Summary Of Iperf Client Test, For Detail Result See "$iperf_client_res_log
grep Server: $iperf_client_res_log
echo -e "[4-2-3] Iperf Client Test End."
################################进行iperf测试   end################################
