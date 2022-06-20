# CDH

>由于Hadoop深受客户欢迎，许多公司都推出了各自版本的Hadoop，也有一些公司则围绕Hadoop开发产品。在Hadoop生态系统中，规模最大、知名度最高的公司则是Cloudera。 
>
>Cloudera 的定位在于 **Bringing Big Data to the Enterprise with Hadoop**
>
>Cloudera 为了让 [Hadoop](http://www.oschina.net/p/hadoop) 的配置标准化，可以帮助企业安装，配置，运行 hadoop 以达到大规模企业数据的处理和分析。
>
>说白了就是部署好以后，你安装大数据组件就像在手机安装应用一样简单，商业版还提供了动态扩容的能力

> 由于cdh本身是收费产品，现在官网貌已经没有新版本的下载链接（2022/6）
>
> 这是一个提供CDH产品的镜像网站：http://ro-bucharest-repo.bigstepcloud.com/cloudera-repos/
>
> 参考文章https://blog.csdn.net/qq_36488175/article/details/109130446

## 部署

### 基本准备工作

> 下面为三台虚拟机部署CDH环境
>
> 静态ip、关闭防火墙、ssh免密登录、java环境等就不演示了（详见hadoop部署的准备工作）
>
> NTP时钟服务，我并没有配置，使用的虚拟机有连接公网，自动同步时间。
>
> 这边有人说java环境要选择oracle的jdk，我下面使用的是Alibaba Dragonwell 8.x版本也能正常运行，主要是jdk版本一定要选择8.0，至少是6.2.0的版本如此，不容易出错。（hadoop上使用jdk11也有坑，还是老老实实用jdk8吧）

配置集群主机名

**以后配置主机名都不要再加`_`或`-`等特殊符号了，框架可能不支持，这里使用下划线**

```
192.168.150.110 cdh1
192.168.150.111 cdh2
192.168.150.112 cdh3
```

xsync脚本（就是简单封装一下rsync，方便集群内分发文件）

我使用的是注意centos7系统，自带的是python2.7，无法使用f-str等python3语法。

```python
#!/bin/env python
import os
import sys

hosts = ["cdh{}".format(x) for x in range(1,4)]

if len(sys.argv) != 3:
	print("must has two arguments!!!")
else:
	for host in hosts:
        os.system("rsync -av {} root@{}:{}".format(sys.argv[1], host, sys.argv[2]))
```

**这里还有一个坑，cdh默认使用`/usr/java`下的jdk，如果不想更改配置，请将jdk装在`/usr/java`下，并重命名为`default`**

jdk装在其他地方的，也可以使用软连接，只要能在`/usr/java`下有`default`jdk目录就行

### 部署mysql

上面的基础操作做完后，首先启动一个mysql，用于存储cdh所需的元数据信息。

这里为了方便，我在wsl的docker上部署mysql（懒得在linux折腾mysql了）



mysql8.0 docker启动命令：`docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag`

执行：`$ docker run --name mysql8 -e MYSQL_ROOT_PASSWORD=tiger -d mysql:8.0`



创建cdh所需的数据库

```sql
create database cmserver default charset utf8 collate utf8_general_ci;
# 如果你只是开发测试使用，所有用户都是root，那么这里就不需要分配用户权限了
grant all on cmserver.* to 'cmserveruser'@'%' identified by 'root';

create database metastore default charset utf8 collate utf8_general_ci;
grant all on metastore.* to 'hiveuser'@'%' identified by 'root';

create database amon default charset utf8 collate utf8_general_ci;
grant all on amon.* to 'amonuser'@'%' identified by 'root';

create database rman default charset utf8 collate utf8_general_ci;
grant all on rman.* to 'rmanuser'@'%' identified by 'root';
```

### 安装CM组件

> cdh主要有server（即cm，cloudera manager）和agent端，server端就是主要的管理节点也是web页面的访问节点。
>
> agent端就是所有需要被cdh监控与管理的节点。

将cm相关rpm包，上传至虚拟机准备安装。

相关文件大概有：

* cloudera-repos-6.2.0
    * 存放cdh的server、agent、daemons等rpm包，我们要安装的就是这些rpm。
* parcel-6.2.0
    * 离线存放cdh的组件，例如hadoo、hive、spark等。
* jdk与msyql5.7
    * jdk与mysql不多做介绍

#### 安装离线包

我们将cdh1作为管理的主节点，需要安装三个包。

**注意有安装顺序要求，（server依赖于daemons包，按照下面的顺序安装就行）**

```shell
yum localinstall -y cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm 
yum localinstall -y cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
yum localinstall -y cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
```

其他节点只需要安装两个

```shell
yum localinstall -y cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm 
yum localinstall -y cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
```

#### 上传组件包

安装成功后，将parcel-6.2.0文件夹中的大数据组件包，上传至`/opt/cloudera/parcel-repo`

这里我在做测试，`cloudera`**可能是根据rpm包的位置**，来选择安装位置的，我将rpm包上传到`/opt`下，再使用`yum localinstall`安装后，`cloudera`的安装位置就是`/opt/cloudera`。（安装时注意一下就行了）

#### 配置

cdh1主节点配置

`/etc/cloudera-scm-server/db.properties`

```properties
com.cloudera.cmf.db.type=mysql
# 这里注意一下，mysql是不是配置在虚拟机里或者端口不是3306，踩了个小坑
com.cloudera.cmf.db.host=domain:3336
# 对应前面创建的数据库名，存储cloudera manager的元数据信息
com.cloudera.cmf.db.name=cmserver
com.cloudera.cmf.db.user=root
com.cloudera.cmf.db.setupType=EXTERNAL
com.cloudera.cmf.db.password=tiger
```

其他节点，只需配置主节点地址即可

`/etc/cloudera-scm-agent/config.ini`

```properties
server_host=cdh1
```

#### 启动CM与CDH集群

```shell
# 启动CM
systemctl start cloudera-scm-server
# 查看CM状态
systemctl status cloudera-scm-server
```

```shell
# 启动agent
systemctl start cloudera-scm-agent
# 查看agent状态
systemctl status cloudera-scm-agent
```

```shell
# 停止server与agent
systemctl stop cloudera-scm-server
systemctl stop cloudera-scm-agent
```



这里如果查看状态显示启动失败，注意观察日志即可，日志位置默认在`/var/log/cloudera*`

启动失败并且日志没有数据，很可能是没有配置`/usr/java`下的`default`jdk，重新配置一下，如果jdk在其他位置，创建一个软连接即可（记得软连接全部用绝对路径，linux小白容易被坑）。

常见错误还有数据库没连接上、数据库没找到等问题，查看日志逐一解决即可，没连上数据库就去查看数据连接是否有问题，是不是`db.properts`里的mysql host配置有问题，数据库没找到看看是不是连错了或者没有创建数据库。



访问web页面`http://cdh1:7180/cmf/login`即可，默认登录名与密码都是`admin`

启动cdh服务后，重启虚拟机，cdh服务也会自动启动，需要彻底关闭cdh服务，尝试使用`systemctl disable`系列命令（我也没试过，真经人谁关闭自动启动啊）