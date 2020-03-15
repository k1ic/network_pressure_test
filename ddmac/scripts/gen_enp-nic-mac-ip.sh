#!/usr/bin/bash

rm -rf /workspace/tmp_data/enp-nic.csv /workspace/tmp_data/enp-mac.csv /workspace/tmp_data/enp-ip.csv

#获取网卡名与NIC对应关系
eeupdate64e | grep 'Intel(R)' | awk '{ print "enp"$2"s0f"substr($4, 2,1)","$1}' | grep -v enp4 | sort -k 1 -t, > /workspace/tmp_data/enp-nic.csv

#获取网卡名与mac地址对应关系
for i in `netstat -i |  grep  -vE 'Iface|Kernel|lo|virbr|enp4s' | awk '{ print $1}'`; do ifconfig $i | grep -v inet6 | grep -E 'enp|ether' | tr "\n" " \n" | awk '{ print $1","$6}' | sed 's/:,/,/g'| sort -k 1 -t,;  done > /workspace/tmp_data/enp-mac.csv

#获取网卡名与ip地址对应关系
for i in `netstat -i |  grep  -vE 'Iface|Kernel|lo|virbr|enp4s' | awk '{ print $1}'`; do ifconfig $i | grep -v inet6 | grep -E 'enp|inet' | tr "\n" " \n" | awk '{ print $1","$6}' | sed 's/:,/,/g'| sort -k 1 -t,;  done > /workspace/tmp_data/enp-ip.csv


