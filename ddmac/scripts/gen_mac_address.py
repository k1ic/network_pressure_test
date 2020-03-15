#run at py27
def intToMac(intMac):
    if len(hex(intMac)) % 2 != 0:
        hexStr = '0{0:X}'.format(intMac)
    else:
        hexStr = '{0:X}'.format(intMac)

    i = 0
    ret = ""

    while i <= len(hexStr) - 2:
        if ret == "":
            ret = hexStr[i:(i + 2)]
        else:
            ret = "".join([ret, ":", hexStr[i:(i + 2)]])
        i = i + 2
    return ret

def macToInt(mac):
    mac = mac.replace(":", "")
    return int(mac, 16)

start = macToInt('68:91:d0:00:00:00')
end = macToInt('68:91:d0:ff:ff:ff')

mac_int_list = range(start, end)
for i, val in enumerate(mac_int_list):
    with open('./mac_addr.csv', 'a') as f:
        f.writelines(str(i) + ',' + intToMac(val) + ',0,0,'','',0\n')
        f.close()
