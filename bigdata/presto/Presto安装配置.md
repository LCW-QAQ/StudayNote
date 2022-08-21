### 一、Presto安装配置

- 集群规划（一主两从集群）

  |               | hadoop01 | hadoop02 |
  | ------------- | -------- | -------- |
  | 主coordinator | yes      | no       |
  | 从worker      | yes      | yes      |

- java8版本安装

  ```shell
  #可以手动安装oracle JDK
  
  #也可以使用yum在线安装 openjDK
  yum install java-1.8.0-openjdk* -y
  
  #安装完成后，查看jdk版本：
  java -version
  ```

- 上传解压Presto安装包

  ```shell
  #创建安装目录
  mkdir -p /export/server
  
  #yum安装上传文件插件lrzsz
  yum install -y lrzsz
  
  #上传安装包到hadoop01的/export/server目录
  presto-server-0.245.1.tar.gz
  
  #解压、重命名
  tar -xzvf presto-server-0.245.1.tar.gz
  mv presto-server-0.245.1 presto
  
  #创建配置文件存储目录
  mkdir -p /export/server/presto/etc
  ```

- 添加配置文件

  - hadoop01配置

    - etc/config.properties

      ```properties
      cd /export/server/presto
      
      vim etc/config.properties
      
      #---------添加如下内容
      coordinator=true
      node-scheduler.include-coordinator=true
      http-server.http.port=8090
      query.max-memory=6GB
      query.max-memory-per-node=2GB
      query.max-total-memory-per-node=2GB
      discovery-server.enabled=true
      discovery.uri=http://192.168.88.80:8090
      #---------end
      
      #参数说明
      coordinator:是否为coordinator节点，注意worker节点需要写false
      node-scheduler.include-coordinator:coordinator在调度时是否也作为worker
      discovery-server.enabled:Discovery服务开启功能。presto通过该服务来找到集群中所有的节点。每一个Presto实例都会在启动的时候将自己注册到discovery服务；  注意：worker节点不需要配 
      discovery.uri:Discovery server的URI。由于启用了Presto coordinator内嵌的Discovery服务，因此这个uri就是Presto coordinator的uri。
      ```

    - etc/jvm.config

      ```shell
      vim etc/jvm.config
      
      -server
      -Xmx3G
      -XX:+UseG1GC
      -XX:G1HeapRegionSize=32M
      -XX:+UseGCOverheadLimit
      -XX:+ExplicitGCInvokesConcurrent
      -XX:+HeapDumpOnOutOfMemoryError
      -XX:+ExitOnOutOfMemoryError
      ```

    - etc/node.properties

      ```properties
      mkdir -p /export/data/presto
      vim etc/node.properties
      
      node.environment=cdhpresto
      node.id=presto-cdh01
      node.data-dir=/export/data/presto
      ```

    - etc/catalog/hive.properties

      ```properties
      mkdir -p etc/catalog
      vim etc/catalog/hive.properties
      
      connector.name=hive-hadoop2
      hive.metastore.uri=thrift://192.168.88.80:9083
      ```

- scp安装包到其他节点

  ```shell
  #在hadoop02创建文件夹
  mkdir -p /export/server
  
  #在hadoop01远程cp安装包
  cd /export/server
  scp -r presto hadoop02:$PWD
  
  #ssh的时候如果没有配置免密登录 需要输入密码scp  密码：123456
  ```

- hadoop02配置修改

  - etc/config.properties

    ```properties
    cd /export/server/presto
    vim etc/config.properties
    
    #----删除之前的内容 替换为以下的内容
    coordinator=false
    http-server.http.port=8090
    query.max-memory=6GB
    query.max-memory-per-node=2GB
    query.max-total-memory-per-node=2GB
    discovery.uri=http://192.168.88.80:8090
    ```

  - etc/jvm.config

    > 和coordinator保持一样，不需要修改

    ```shell
    vim etc/jvm.config
    
    -server
    -Xmx3G
    -XX:+UseG1GC
    -XX:G1HeapRegionSize=32M
    -XX:+UseGCOverheadLimit
    -XX:+ExplicitGCInvokesConcurrent
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:+ExitOnOutOfMemoryError
    ```

  - etc/node.properties

    ```properties
    mkdir -p /export/data/presto
    vim etc/node.properties
    
    node.environment=cdhpresto
    node.id=presto-cdh02
    node.data-dir=/export/data/presto
    ```

  - etc/catalog/hive.properties

    ```properties
    vim etc/catalog/hive.properties
    
    connector.name=hive-hadoop2
    hive.metastore.uri=thrift://192.168.88.80:9083
    ```

-----

### 二、Presto服务启停

> 注意，每台机器都需要启动

- 前台启动

  ```shell
  [root@hadoop01 ~]# cd ~
  [root@hadoop01 ~]# /export/server/presto/bin/launcher run
  
  
  [root@hadoop02 ~]# cd ~
  [root@hadoop02 ~]# /export/server/presto/bin/launcher run
  
  
  #如果出现下面的提示 表示启动成功
  2021-09-15T18:24:21.780+0800    INFO    main    com.facebook.presto.server.PrestoServer ======== SERVER STARTED ========
  
  #前台启动使用ctrl+c进行服务关闭
  ```

- 后台启动

  ```shell
  [root@hadoop01 ~]# cd ~
  [root@hadoop01 ~]# /export/server/presto/bin/launcher start
  Started as 89560
  
  [root@hadoop02 ~]# cd ~
  [root@hadoop02 ~]# /export/server/presto/bin/launcher start
  Started as 92288
  
  
  #查看进程是否启动成功
  PrestoServer
  
  #后台启动使用jps 配合kill -9命令 关闭进程
  ```

- web UI页面

  http://192.168.88.80:8090/ui/

- 启动日志

  ```shell
  #日志路径：/export/data/presto/var/log/
  
  http-request.log
  launcher.log
  server.log
  ```

----

### 三、Presto CLI命令行客户端

- 下载CLI客户端

  ```shell
  presto-cli-0.241-executable.jar
  ```

- 上传客户端到Presto安装包

  ```shell
  #上传presto-cli-0.245.1-executable.jar到/export/server/presto/bin
  
  mv presto-cli-0.245.1-executable.jar presto
  chmod +x presto
  ```

- CLI客户端启动

  ```shell
  /export/server/presto/bin/presto --server localhost:8090 --catalog hive --schema default
  ```

### 四、Presto Datagrip JDBC访问

- JDBC 驱动：presto-jdbc-0.245.1.jar
- JDBC 地址：jdbc:presto://192.168.88.80:8090/hive





















