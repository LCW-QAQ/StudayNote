# Hadoop

> Hadoop是一个分布式系统基础架构。提供了HDFS分布式存储、MapReduce分布式计算、YARN分布式系统资源调度等功能。

## hadoop集群搭建

> 搭建这里坑很多，注意一下每个步骤都仔细一点就行。

首先记得配置静态IP和关闭防火墙，这个就不多解释了。

### 配置主机名

> 为每台服务器配置主机名，方便访问。
>
> 我的虚拟机网段是192.168.150.0，虚拟机网关是192.168.150.2。

这里演示三台服务器，三台主机的IP分别是`192.168.150.101`，`192.168.150.102`，`192.168.150.103`。

`vi /etc/hosts`更改hosts文件，加入以下内容：

注意hadoop不支持主机名包含空格、`.`、`_`

```
192.168.150.101 hadoop-1
192.168.150.102 hadoop-2
192.168.150.103 hadoop-3
```

配置完成后，使用`service network restart`重启网卡，没有该命令自己网上查询解决方案或者直接重启系统自动重启网卡。

使用`hostname`查看主机名是否配置成功。

### 配置ssh免密登录

> hadoop访问集群其他机器时需要使用

`ssh-keygen -t rsa`生成公钥私钥，默认会在`/root/.ssh`目录下生成`id_rsa`私钥与`id_rsa.pub`公钥。

公钥相当于锁，私钥就是钥匙。

`ssh-copy-id hostname`将公钥拷贝到其他需要登录服务器上即可。

在每台机器上配置免密登录

`ssh-keygen -t rsa`

`ssh-copy-id hadoop-1`

`ssh-copy-id hadoop-2`

`ssh-copy-id hadoop-3`

### 下载hadoop运行环境

hadoop官方下载链接https://hadoop.apache.org/releases.html

这里使用的是hadoop-3.3.3版本

hadoop是jvm平台软件，我们还需要安装jdk，这里使用[open-jdk-11](https://jdk.java.net/java-se-ri/11)

### 配置环境变量

向`/etc/profile`中追加：

```bash
export JAVA_HOME=/opt/jdk-11
export HADOOP_HOME=/opt/hadoop-3.3.3
export PATH=$PATH:$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
```

`source /etc/profile`刷新环境变量

### Hadoop配置

> 配置很重要，hadoop启动报错多半是配置有问题。出现问题尝试查看hadoop日志获取相关信息。

* core-site.xml
    * hadoop核心配置
* hdfs-site.xml
    * hdfs配置
* mapred-site.xml
    * mapreduce配置
* yarn-site.xml
    * yarn资源调度配置
* wokers
    * hadoop集群主机名

#### core-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <!-- 设置默认的文件系统，偶人hadoop支持file、HDFS、GFS以及aliyun、Amazone云文件系统 -->
  <property>
      <name>fs.defaultFS</name>
      <value>hdfs://hadoop-1:9000</value>
  </property>

  <!-- hadoop本地保存数据的路径 -->
  <property>
      <name>hadoop.tmp.dir</name>
      <value>/export/hadoop/data</value>
  </property>

  <!-- 设置HDFS web ui 用户身份 -->
  <property>
      <name>hadoop.http.staticuser.user</name>
      <value>root</value>
  </property>

  <!-- 整合hive用户代理设置 -->
  <property>
      <name>hadoop.proxyuser.root.hosts</name>
      <value>*</value>
  </property>

  <property>
      <name>hadoop.proxyuser.root.groups</name>
      <value>*</value>
  </property>

  <!-- 文件系统垃圾桶保存时间 -->
  <property>
      <name>fs.trash.interval</name>
      <value>1440</value>
  </property>
</configuration>
```

#### hdfs-site.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <!-- 设置SNN辅助节点，运行机器信息 -->
  <property>
    <name>dfs.namenode.secondary.http-address</name>
    <value>hadoop-2:9868</value>
  </property>
</configuration>
```

#### mapred-site.xml

```xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <!-- 设置Mapreduce程序，运行模式，yarn集群模式、ocal本地模式 -->
  <property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>

  <!-- MR程序历史服务地址 -->
  <property>
    <name>mapreduce.jobhistory.address</name>
    <value>hadoop-1:10020</value>
  </property>

  <!-- MR程序历史服务web地址 -->
  <property>
    <name>mapreduce.jobhistory.webapp.address</name>
    <value>hadoop-1:19888</value>
  </property>

  <property>
    <name>yarn.app.mapreduce.am.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>

  <property>
    <name>mapreduce.map.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>

  <property>
    <name>mapreduce.reduce.env</name>
    <value>HADOOP_MAPRED_HOME=${HADOOP_HOME}</value>
  </property>

</configuration>
```

#### yarn-site.xml

```xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>

  <!-- Site specific YARN configuration properties -->
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>hadoop-1</value>
  </property>

  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>

  <!-- 是否对容器实施物理内存限制 -->
  <property>
    <name>yarn.nodemanager.pmem-check-enabled</name>
    <value>false</value>
  </property>

  <!-- 是否对容器实施虚拟内存限制 -->
  <property>
    <name>yarn.nodemanager.vmem-check-enabled</name>
    <value>false</value>
  </property>

  <!-- 开启日志采集 -->
  <property>
    <name>yarn.log-aggregation-enable</name>
    <value>true</value>
  </property>

  <!-- 设置yarn历史服务器地址 -->
  <property>
    <name>yarn.log.server.url</name>
    <value>http://hadoop-1:19888/jobhistroy/logs</value>
  </property>

  <!-- 历史服务器保存时间，单位秒 -->
  <property>
    <name>yarn.log-aggregation.retain-seconds</name>
    <value>604800</value>
  </property>
</configuration>
```

#### wokers

```
hadoop-1
hadoop-2
hadoop-3
```

### 将环境分发到其他服务器

#### 拷贝hadoop与jdk

使用`scp`命令将hadoop与jdk拷贝到其他服务器。

-r 参数表示递归拷贝（拷贝文件夹）

`scp -r /opt/hadoop-3.3.3 root@hadoop-2:/opt/hadoop-3.3.3`

`scp -r /opt/jdk-11 root@hadoop-2:/opt/jdk-11`

`scp -r /opt/hadoop-3.3.3 root@hadoop-3:/opt/hadoop-3.3.3`

`scp -r /opt/jdk-11 root@hadoop-3:/opt/jdk-11`



可以使用`rsync`命令，rsync是做同步，相比scp在更改数据后拷贝性能更高，只会拷贝有变化的文件，同时还支持拷贝软连接等。

- -a 包含-rtplgoD参数选项
- -r 同步目录时要加上，类似cp时的-r选项
- -v 同步时显示一些信息，让我们知道同步的过程
- -l 保留软连接
    - 若是拷贝的原目录里面有一个软链接文件，那这个软链接文件指向到了另外一个目录下
    - 在加上-l，它会把软链接文件本身拷贝到目标目录里面去
- -L 加上该选项后，同步软链接时会把源文件给同步
- -p 保持文件的权限属性
- -o 保持文件的属主
- -g 保持文件的属组
- -D 保持设备文件信息

`rsync -av /opt/hadoop-3.3.3 root@hadoop-2:/opt/hadoop-3.3.3`

`rsync -av /opt/jdk-11 root@hadoop-2:/opt/jdk-11`

`rysnc -av /opt/hadoop-3.3.3 root@hadoop-3:/opt/hadoop-3.3.3`

`rsync -av /opt/jdk-11 root@hadoop-3:/opt/jdk-11`

#### 拷贝/etc/profile

`scp /etc/profile root@hadoop-2:/etc/profile`

`scp /etc/profile root@hadoop-3:/etc/profile`

拷贝完成后使用工具，将`source /etc/profile`分发到所有服务器，刷新环境变量。

### 初始化NameNode

在NameNode上（这个历史hadoop-1），执行`hadoop namenode -foramt`初始化。

**!!!一定要注意，初始化只能初始化一次**

**每次初始化会产生新的集群id，多次初始化会导致NameNode与DataNode的集群id不一致，需要删除所有机器的data和log目录，再次初始化才能正常运行**

### 启动hadoop

分别启动hdfs与yarn

脚本路径在hadoop目录下的sbin中

start-all.sh启动yarn与hdfs