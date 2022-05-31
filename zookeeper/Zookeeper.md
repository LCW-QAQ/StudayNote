# Zookeeper

> zookeeper是一个分布式协调服务，提供功能包括：配置维护、域名服务、分布式同步、组服务等。使用起来很简单，提供一系列原子操作命令。

## 部署

### Jar包部署

配置文件

zoo.cfg

```properties
dataDir=/data
dataLogDir=/datalog
# 心跳间隔
tickTime=2000
# 厨师延迟，leader节点可以等待一个follower节点initLimit * tickTime毫秒的初始延迟
initLimit=5
# 同步延迟，leader节点向follower节点发送同步命令的时候，有syncLimit * tickTime毫秒的超时时间
syncLimit=2
autopurge.snapRetainCount=3
autopurge.purgeInterval=0
# 最大客户端连接数
maxClientCnxns=60
# 单机模式
standaloneEnabled=true
admin.enableServer=true
# 集群配置
# 3888端口负责投票选主，2888端口负责集群间，leader正常情况下的通信
# 需要在zk data文件夹下创建myid文件，myid文件中的数字表示server.id
# zk默认选举，会让server.id最大的节点成为leader
server.1=localhost:2888:3888;2181
```

创建data目录下的myid文件

```
1
```

集群中的每台zk服务都有一个唯一id

在zk的数据目录下新建一个myid文件，myid文件中存放的数字就是服务器的server.id，对应配置文件中的server.1。

zk默认选举会从配置的server.id中，选择server.id最大的作为leader。



配置完成后直接运行bin目录下的`zkServer.sh`脚本启动zk即可。

### Docker部署

#### 单节点

```yaml
version: '3.1'

services:
  zoo1:
    container_name: zoo1
    image: zookeeper:3.8.0
    hostname: zoo1
    ports:
      - 2181:2181
    environment:
      ZOO_MY_ID: 1
    volumes:
      - ./zoo1/zoo.cfg:/conf/zoo.cfg
```

#### 集群

```yaml
version: '3.1'

services:
  zoo1:
    container_name: zoo1
    image: zookeeper:3.8.0
    hostname: zoo1
    ports:
      - 2181:2181
    environment:
      ZOO_MY_ID: 1
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181 server.4=zoo4:2888:3888;2181
    volumes:
      - ./zoo1/data:/data
      - ./zoo1/datalog:/datalog
  zoo2:
    container_name:  zoo2
    image: zookeeper:3.8.0
    hostname: zoo2
    ports:
      - 2182:2181
    environment:
      ZOO_MY_ID: 2
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181 server.4=zoo4:2888:3888;2181
    volumes:
      - ./zoo2/data:/data
      - ./zoo2/datalog:/datalog

  zoo3:
    container_name:  zoo3
    image: zookeeper:3.8.0
    hostname: zoo3
    ports:
      - 2183:2181
    environment:
      ZOO_MY_ID: 3
      ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181 server.4=zoo4:2888:3888;2181
    volumes:
      - ./zoo3/data:/data
      - ./zoo3/datalog:/datalog

  zoo4:
      container_name:  zoo4
      image: zookeeper:3.8.0
      hostname: zoo4
      ports:
        - 2184:2181
      environment:
        ZOO_MY_ID: 4
        ZOO_SERVERS: server.1=zoo1:2888:3888;2181 server.2=zoo2:2888:3888;2181 server.3=zoo3:2888:3888;2181 server.4=zoo4:2888:3888;2181
      volumes:
        - ./zoo4/data:/data
        - ./zoo4/datalog:/datalog
```

## 常用命令

* help

    * 显示所有命令

* ls path

    * 查看当前znode的子节点
    * -w 监听子节点变化
    * -s 显示附加信息

* create [-s] [-e] [-c] [-t ttl] path [data] [acl]

    * 创建节点 
    * -s 创建带自增的序列的节点
    * -e 创建临时节点
    * -c 创建容器节点
        * 容器节点指的是当子节点数量为0时容器节点和持久节点相似，但区别是ZK启动时有单独线程扫描所有容器节点，当发现容器节点的子节点数量为 0 时，会自动删除该节点。-c 和 -s -e -t 参数都是互斥，不能同时执行get path。
    * -t 设置节点过期时间
        * TTL节点实际上就是设置一个有存活时间的节点，过了存活时间的节点会自动删除。-t 和 -e 参数是互斥的，不能同时执行。

    * 获取指定znode的值
    * -w 监听子节点变化
    * -s 显示附加信息

* set path value

    * 更改znode的值

* set [-s] [-v version] path data

    * -s 显示附加信息
    * -v 指定版本号，用于乐观锁

* delete [-v version] path

    * 删除znode
    * -v 指定版本号，用于乐观锁

* deleteall path [-b batch size]

    * 删除znode，包括其子节点
    * -b 没用过，不知道。

* rmr path

    * 3.5.3之前的版本，删除znode，包括其子节点。



权限管理命令

增删改查节点权限：getAcl、setAcl

在前面使用create命令的时候，有一个acl参数是设置节点权限的，那么我们应该怎么设置？

举个例子：`create /testAcl demo world:anyone:crwda`

这行命令的意思是，创建 testAcl 这个节点，节点值为demo，其权限策略是所有人都可以执行 crwda 操作。那么接下来，咱们先看下 ACL 是什么东东？

ACL 全称是`Access Control List`，也就是访问控制列表，ACL可以设置节点的操作权限。那么控制权限的粒度是怎样呢？

对于节点 ACL 权限控制，是通过使用：`scheme:id:perm` 来标识（也就是例子中的格式 -> world:anyone:crwda），其含义是：

1. 权限模式（Scheme）：授权的策略
2. 授权对象（ID）:授权的对象
3. 权限（Permission）：授予的权限

Scheme 有哪些授权策略？

> **world**：默认方式，相当于所有人都能访问
>  **auth**：授权的用户才能访问
>  **digest**：账号密码都正确鉴权的用户才能访问
>  **ip**：指定某ip的才能访问

ID 授权对象有哪些？

> **IP：**具体的 IP 地址或 IP 段
>  **World：**只有“anyOne”这一个Id
>  **Digest：**自定义，格式为 `username:BASE64(SHA-1(username:password))`

Permission 权限有哪些？

> **CREATE：** c 可以创建子节点
>  **DELETE：** d 可以删除子节点（仅下一级节点）
>  **READ：** r 可以读取节点数据及显示子节点列表
>  **WRITE：** w 可以设置节点数据
>  **ADMIN：** a 可以设置节点访问控制列表权限

根据上面的参数可知，我们可以通过给所有人、特定的账号密码、特定的 ip 设置节点权限，这样能够更加方面地管理节点的访问。

值得注意的是，节点可以设置多种授权策略，但对于上下节点而言，权限的设置只对当前节点有效。换言之，权限不存在继承关系，即使节点被设置权限，但不会影响上下节点原来的权限！

上面执行了 create /testAcl demo world:anyone:crwda 命令给节点设置权限，那怎么看节点的权限咧？

很简单，执行`getAcl 节点路径`就可以查看对应节点的权限，比如 getAcl /testAcl，执行结果如下



```csharp
[zk: localhost:2181(CONNECTED) 25] getAcl /testAcl
'world,'anyone
: cdrwa
```

除了在执行create命令创建节点的时候设置权限，还可以通过`setAcl`指定节点设置权限，比如我想指定/testAcl这个节点只可以通过特定 IP操作，并且限制执行权限为crdw，那么可以执行 `setAcl /testAcl ip:127.0.0.1:crwd`，再次执行 getAcl /testAcl 结果如下：

```csharp
[zk: localhost:2181(CONNECTED) 27] getAcl /testAcl
'ip,'127.0.0.1
: cdrw
```

## stat结构

> `cud：create update delete`，注意新的zk客户端连接时和断开时也会自增zxid，zk集群会保存与客户端的连接`session id`，连接和断开时会删除session id因此会自增zxid。
>
> zk有一个zxid全局事务id，每次执行cud操作都会导致全局事务id变化。
>
> zxid是一个64位的数，例如0x100000002，后32位每次cud操作都会自增，前32位表示纪元，说白了就是选举leader的次数（重启zk集群也会导致重新选举leader，从而更新纪元）。

* cZxid：这是创建znode时的事务ID。
* mZxid：这是最后修改znode时的事务ID。
* pZxid：这是用于添加或删除znode的子节点时的事务ID。
* ctime：表示从1970-01-01T00:00:00Z开始以毫秒为单位的znode创建时间。
* mtime：表示从1970-01-01T00:00:00Z开始以毫秒为单位的znode最近修改时间。
* dataVersion：表示对该znode的数据所做的更改次数，可用于乐观锁。
* cversion：这表示对此znode的子节点进行的更改次数。
* aclVersion：表示对此znode的ACL进行更改的次数。
* ephemeralOwner：如果znode是ephemeral类型节点，则这是znode所有者的会话id，如果znode不是ephemeral节点，则该字段为0。
* dataLength：这是znode数据字段的长度。
* numChildren：这表示znode的子节点的数量。

