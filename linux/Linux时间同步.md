# Linux时间同步

## Chrony

查看系统是否自带chronyd

```shell
systemctl status chronyd
```

没有chronyd使用yum安装

```
yum install -y chrony
```

配置

`/etc/chrony.conf`

```shell
# 配置阿里云ntp
server ntp.aliyun.com iburst
server ntp1.aliyun.com iburst
server ntp2.aliyun.com iburst
server ntp3.aliyun.com iburst
# 运行其他服务器同步时间
allow 192.168.150.111/16
```

重启

```shell
# 重启chronyd
systemctl restart chronyd
# 查看状态
systemctl status chronyd
# 查看时间
date
```

集群内其他机器，配置从主时间节点同步时间

同样需要安装chrony

配置

```shell
# 配置从主时间节点同步时间
server cdh1 iburst
```

