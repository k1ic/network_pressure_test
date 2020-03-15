#!/usr/bin/sh
for i in `netstat -i |  grep  -vE 'Iface|Kernel|lo|virbr|enp4s' | awk '{ print $1}'`; do ifconfig $i | grep -v inet6 | grep -E 'inet|ether' | tr "\n" " \n" | awk '{ print $2","$8}' | sed 's/:,/,/g'| sort -k 1 -t,;  done
