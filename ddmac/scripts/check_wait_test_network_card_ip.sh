#!/usr/bin/sh

enp_nic_total=`wc -l /workspace/tmp_data/enp-nic.csv | awk '{ print $1}'`
enp_ip_total=`awk -F ',' '{ print $2}' /workspace/tmp_data/enp-ip.csv | grep -v ^$ | uniq -c |wc -l`

if [ "$enp_nic_total" != "$enp_ip_total" ]
then
    echo "Fatal Error: All Tester Network Port Must Have IP! (Network Port Total: ${enp_nic_total}, IP Total: ${enp_ip_total})"
    exit 0
fi
