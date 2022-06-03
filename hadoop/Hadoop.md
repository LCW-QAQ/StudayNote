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

#### 拷贝/etc/hosts

`scp /etc/hosts root@hadoop-2:/etc/hosts`

`scp /etc/hosts root@hadoop-3:/etc/hosts`

拷贝完成后使用工具，将`service network restart`分发到所有服务器，重启网卡。

### 初始化NameNode

在NameNode上（这个历史hadoop-1），执行`hadoop namenode -foramt`初始化。

**!!!一定要注意，初始化只能初始化一次**

**每次初始化会产生新的集群id，多次初始化会导致NameNode与DataNode的集群id不一致，需要删除所有机器的data和log目录，再次初始化才能正常运行**

### 启动hadoop

分别启动hdfs与yarn

脚本路径在hadoop目录下的sbin中

start-all.sh启动yarn与hdfs

### 启动MapReduce历史记录

`mapred --daemon start historyserver`

### 集群启动/停止方式总结

* hdfs与yarn全部启动
    * `start-all.sh` ``start-all.sh``
* hdfs与yarn单独启动
    * `start-dfs.sh` `stop-dfs.sh`
    * `start-yarn.sh` `stop-yarn.sh`
* 组件单独启动
    * `hdfs --daemon start/stop namenode/datanode/secondarynamenode`
    * `yarn --daemon start/stop resourcemanager/nodemanager`

## hadoop常用端口号

| Hadoop版本 | NameNode内部通信端口 | NameNode Web端口 | Yarn任务运行情况 | Mapreduce历史服务器端口 |
| ---------- | -------------------- | ---------------- | ---------------- | ----------------------- |
| hadoop3.x  | 8020/9000/9820       | 9870             | 8088             | 19888                   |
| hadoop2.x  | 8020/9000            | 50070            | 8088             | 19888                   |

## hadoop常用配置文件

| Hadoop版本 | 配置文件                                                     |
| ---------- | ------------------------------------------------------------ |
| hadoop3.x  | core-site.xml、hdfs-site.xml、yarn-site.xml、mapred-site.xml、wokers |
| hadoop2.x  | core-site.xml、hdfs-site.xml、yarn-site.xml、mapred-site.xml、slaves |

## Hadoop Shell

> hadoop控制台命令

### copyFromLocal

本地文件拷贝到hdfs

`hadoop fs -copyFromLocal 本地文件 hdfs路径`

### moveFromLocal

本地文件移动到hdfs

`hadoop fs -moveFromLocal 本地文件 hdfs路径`

### put

同copyFromLocal

`hadoop fs -copyFromLocal 本地文件 hdfs路径`

### appendToFile

将本地文件追加到hdfs的文件中

`hadoop fs -appendToFile 本地文件 hdfs路径`

### copyToLocal

将hdfs文件拷贝到本地，可拷贝文件夹

`hadoop fs -copyToLocal hdfs路径 本地文件`

### get

同copyToLocal

`hadoop fs -get hdfs路径 本地文件`

### setrep

设置hdfs的副本数量

`hadoop fs -setrep 副本数量 hdfs路径`

### 同linux用法的命令

1. ls
2. cat
3. chgrp、chmod、chown
4. mkdir
5. mv
6. cp
7. tail
8. rm
9. du

## JavaClient

客户端使用hdfs依赖与hadoop/bin目录下的脚本

在windwos上使用时，需要自己建立一个hadoop/bin目录将脚本拷贝到该目录下，并添加`HADOOP_HOME`与`HADOOP_HOME/bin`环境变量。

windows还需要下载一个winutils，在https://github.com/steveloughran/winutils下载发行版，解压到windows上的hadoop/bin目录下。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>my.lcw.hadoop.javaclient</groupId>
    <artifactId>hadoop_java_client</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>11</maven.compiler.source>
        <maven.compiler.target>11</maven.compiler.target>
    </properties>

    <dependencies>
        <!-- https://mvnrepository.com/artifact/org.apache.hadoop/hadoop-client -->
        <dependency>
            <groupId>org.apache.hadoop</groupId>
            <artifactId>hadoop-client</artifactId>
            <version>3.3.3</version>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.junit.jupiter/junit-jupiter-api -->
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter-api</artifactId>
            <version>5.8.2</version>
            <scope>test</scope>
        </dependency>
        <!-- https://mvnrepository.com/artifact/org.slf4j/slf4j-reload4j -->
        <dependency>
            <groupId>org.slf4j</groupId>
            <artifactId>slf4j-reload4j</artifactId>
            <version>1.7.36</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
</project>
```

如果需要看日志，在resource目录下配置log4j.properties

```properties
log4j.rootLogger=INFO, stdout
log4j.appender.stdout=org.apache.log4j.ConsoleAppender
log4j.appender.stdout.layout=org.apache.log4j.PatternLayout
log4j.appender.stdout.layout.ConversionPattern=%d %p [%c] - %m%n
log4j.appender.logfile=org.apache.log4j.FileAppender
log4j.appender.logfile.File=target/spring.log
log4j.appender.logfile.layout=org.apache.log4j.PatternLayout
log4j.appender.logfile.layout.ConversionPattern=%d %p [%c] - %m%n
```

```java
public class HdfsUtils {

    public static void hadoopFsContext(Consumer<FileSystem> hadoopFsRunner) {
        final URI uri = URI.create("hdfs://hadoop-1:9000");
        final Configuration config = new Configuration();
        /*
        可以再resource目录下配置hdfs-site.xml等配置文件，更改客户端默认配置，也可以在代码里配置config。
        优先级：代码配置 > 客户端resource目录下的配置 > hadoop服务器HADOOP_HOME/etc/hadoop下的配置 > hadoop默认配置
         */
        // config.set("dfs.replication", "1");
        String userName = "root";
        try (final FileSystem fs = FileSystem.get(uri, config, userName)) {
            hadoopFsRunner.accept(fs);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class HdfsClientTest {
    @Test
    public void testMkdir() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                System.out.println(fs.mkdirs(new Path("/xiyou/huaguoshan")));
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testPut() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                // 第一个参数：是否删除源文件
                // 第二个参数：是否覆盖，值为false时，如果文件已存在会报错
                fs.copyFromLocalFile(false, true,
                        new Path(".\\src\\test\\java\\my\\lcw\\hadoop\\javaclient\\sunwukong.txt"),
                        new Path("/xiyou/huaguoshan"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testGet() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                // 第一个参数：是否删除源文件
                // 第二个参数：是否不使用crc文件校验，默认是false即开启校验
                fs.copyToLocalFile(false,
                        new Path("/xiyou/huaguoshan/"),
                        new Path("./huaguoshan"),
                        false);
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testRm() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                // 第一个参数：要删除的路径
                // 第二个参数：是否递归删除
                fs.delete(new Path("/itheima/install.sh"), false);
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testMv() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                // 更改文件名称同时支持移动文件
                fs.rename(new Path("/itheima/wordcount2"), new Path("/wordcount"));
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testLs() {
        HdfsUtils.hadoopFsContext(fs -> {
            final RemoteIterator<LocatedFileStatus> it;
            try {
                it = fs.listFiles(new Path("/"), true);
                while (it.hasNext()) {
                    System.out.println("------------------------");
                    final LocatedFileStatus fileStatus = it.next();
                    System.out.println(fileStatus);
                    System.out.println(Arrays.toString(fileStatus.getBlockLocations()));
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    @Test
    public void testFileStatus() {
        HdfsUtils.hadoopFsContext(fs -> {
            try {
                final FileStatus[] fileStatuses = fs.listStatus(new Path("/"));
                System.out.println(Arrays.toString(fileStatuses));
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }
}
```

## 面试题

### 为什么块大小能设置太小也不能设置太大

- 如果块太小，会导致文件被分成大量的块，极大增加寻址时间。
- 如果块太大会影响磁盘传输时间
- 块大小由存储介质的IO速度决定

### HDFS写入流程

![Hadoop上传流程](Hadoop.assets/Hadoop上传流程.png)

1. hadoop会先向NameNode请求上传文件
2. NameNode判断文件是否可以创建，这里会涉及权限检查、目录检查
3. NameNode响应可以创建文件，客户端请求上传一个数据块
4. NameNode选择节点，再有三个副本时，默认在当前机器上保存一份，然后其他机架保存一份，第三份副本保存第二份副本的另一个节点，这里还会考虑到负载均衡。
5. NameNode选择完节点后，返回节点信息。
6. 客户端获取节点信息，向一个节点（DataNode01）上传文件
7. DataNode01不是阻塞上传，上传的过程中会将文件加载到数据中并行传输给其他节点

### HDFS读取流程

![Hadoop读取流程](Hadoop.assets/Hadoop读取流程.png)

读取流程相比写入会简单一些

1. 想NameNode请求下载文件
2. NameNode判断是否可以读取，涉及权限判断、文件是否存在等
3. 允许读取，返回元数据（存储在哪些节点上）
4. 根据节点距离与负载均衡，选择最近且负载均衡的节点下载文件，文件分块存储在多个节点上就会与多个节点建立传输通道下载文件

### NameNode工作机制

首先思考NameNode将数据存储到哪里？

| 存储方式                            | 优点                                   | 缺点     |
| ----------------------------------- | -------------------------------------- | -------- |
| 内存                                | 高性能                                 | 可靠性差 |
| 硬盘                                | 可靠性高                               | 性能低   |
| 硬盘 + 内存（通过特殊日志方式实现） | 兼顾性能与可靠性（类似Redis的RDB+AOF） | 更加复杂 |

hdfs使用fsimage存储数据，使用edits存储追加操作，定时将edits文件中的操作，同步到fsimage中即可。

服务器启动时会将fsimage与edits加载到内存中，服务器关闭时就会将edits同步到fsimage中，辅助节点会定时将edits同步到fsimage中。

详细流程：

1. 服务器启动将fsimage与edits加载到内存中
2. 客户端进行crud
3. 记录操作日志到edits中，当前的操作的文件一般以`edits_inprogress_001`方式命名。（有点类似于redis的aof）
4. 辅助节点默认一个小时，将edits数据同步到fsimage。如果edits数据满了（默认记录达到100w次），也会触发同步操作。
5. 当辅助节点请求合并，NameNode同意后，滚动正在写入的edits。`edits_inprogress_001`变成`edits_001`，并生成新的`edits_inprogress_002`，新的操作会记录在`edits_inprogress_002`中
6. 辅助节点会拉取NameNode中的fsimage与edits，将NameNode与edits加载到内存
7. 辅助节点合并edits与fsimage，生成新的`fsimage.checkpoint`
8. 辅助节点将新的`fsimage.checkpoint`拷贝到NameNode，并重命名为fsimage



Fsimage、Edits、seen_txid、VERSION等文件存储在数据目录中

#### Fsimage

> Fsimage是HDFS文件系统元数据信息的一个**永久性检查点**，包含HDFS文件系统的所有目录和文件inode的序列化信息

Fsimage在NameNode与SecondaryNameNode都有可能有

使用`hdfs oiv -p 文件类型 -i 镜像文件 -o 转换后输出文件名`将Fsimage转换成指定格式。

`hdfs oiv -p XML -i fsimage_0000000000000001390 -o /root/fsimage.xml`生成XML

#### Edits

> Edits存放HDFS文件系统的所有的更新操作信息（类似Redis的AOF），HDFS文件系统的写入操作都会先存储在Edits中

使用`hdfs oev -p 文件类型 -i 镜像文件 -o 转换后输出文件名`将edits转换成指定格式。

### seen_txid

> 该文件保存的是一个数字，值得是最后一个（即inprogress的edits）edits_的数字

### VERSION

> 记录了集群ID、创建时间、命名空间等
