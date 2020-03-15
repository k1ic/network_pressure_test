#!/usr/bin/bash

#获取网卡名与NIC对应关系
eeupdate64e | grep 'Intel(R)' | awk '{ print "enp"$2"s0f"substr($4, 2,1)","$1}' | grep -v enp4 | sort -k 1 -t, > /workspace/tmp_data/enp-nic.csv
