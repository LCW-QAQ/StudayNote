# Linux静态IP配置

1. 修改/etc/sysconfig/network-scripts/下的网卡配置, 看你用的那张网卡  
    列如: `/etc/sysconfig/network-scripts/ifcfg-ens33`
2. ONBOOT=YES 表示网卡随着系统启动
3. BOOTPROTO=static 表示使用静态IP
4. IPADDR=192.168.150.100 你的静态IP
5. NETMASK=255.255.255.0 默认掩码, 意思就是前面三位都直接映射
6. GATEWAY=192.168.150.2 这个要看VMware里配置的网关
6. DNS1=144.144.144.144
6. DNS2=8.8.8.8

重启服务器`reboot`或重启网卡`service network restart`