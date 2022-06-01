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
# zk默认选举，会让server.id最大的节点成为leader。（准确来说优先选举zxid事务id最大的，即数据最新的，然后myid更大的，详见选主讲解）
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

* ls [-w] [-s] path

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

## Watch机制

* watch机制一
    * 针对每个节点的操作，都会有一个监督者 -> watcher
    * 当监控的某个对象（znode）发生了变化，则触发watch事件
    * zk中的watch是一次性的，触发后立即销毁
* watch机制二
    * 父结点，子节点 增删改都能触发其watch
    * 针对不同类型的操作，触发的watch事件也不同
        * 节点创建事件
        * 结点删除事件
        * 点数据变化事件
        * 子节点数量更改
        * 监听器增删改时间

## 分布式一致性算法

### paxos

> paxos是一个分布式一致性算法，同时也是目前为止（2022/6/1）唯一的分布式一致性算法，其他算法都是paxos的变体与扩展。

转载至https://www.douban.com/note/208430424/?_i=4083776YDhWGr_

Paxos描述了这样一个场景，有一个叫做Paxos的小岛(Island)上面住了一批居民，岛上面所有的事情由一些特殊的人决定，他们叫做议员(Senator)。议员的总数(Senator Count)是确定的，不能更改。岛上每次环境事务的变更都需要通过一个提议(Proposal)，每个提议都有一个编号(PID)，这个编号是一直增长的，不能倒退。每个提议都需要超过半数((Senator Count)/2 +1)的议员同意才能生效。每个议员只会同意大于当前编号的提议，包括已生效的和未生效的。如果议员收到小于等于当前编号的提议，他会拒绝，并告知对方：你的提议已经有人提过了。这里的当前编号是每个议员在自己记事本上面记录的编号，他不断更新这个编号。整个议会不能保证所有议员记事本上的编号总是相同的。现在议会有一个目标：保证所有的议员对于提议都能达成一致的看法。

好，现在议会开始运作，所有议员一开始记事本上面记录的编号都是0。有一个议员发了一个提议：将电费设定为1元/度。他首先看了一下记事本，嗯，当前提议编号是0，那么我的这个提议的编号就是1，于是他给所有议员发消息：1号提议，设定电费1元/度。其他议员收到消息以后查了一下记事本，哦，当前提议编号是0，这个提议可接受，于是他记录下这个提议并回复：我接受你的1号提议，同时他在记事本上记录：当前提议编号为1。发起提议的议员收到了超过半数的回复，立即给所有人发通知：1号提议生效！收到的议员会修改他的记事本，将1号提议由记录改成正式的法令，当有人问他电费为多少时，他会查看法令并告诉对方：1元/度。

现在看冲突的解决：假设总共有三个议员S1-S3，S1和S2同时发起了一个提议:1号提议，设定电费。S1想设为1元/度, S2想设为2元/度。结果S3先收到了S1的提议，于是他做了和前面同样的操作。紧接着他又收到了S2的提议，结果他一查记事本，咦，这个提议的编号小于等于我的当前编号1，于是他拒绝了这个提议：对不起，这个提议先前提过了。于是S2的提议被拒绝，S1正式发布了提议: 1号提议生效。S2向S1或者S3打听并更新了1号法令的内容，然后他可以选择继续发起2号提议。


好，我觉得Paxos的精华就这么多内容。现在让我们来对号入座，看看在ZK Server里面Paxos是如何得以贯彻实施的。

小岛(Island)——ZK Server Cluster

议员(Senator)——ZK Server

提议(Proposal)——ZNode Change(Create/Delete/SetData…)

提议编号(PID)——Zxid(ZooKeeper Transaction Id)

正式法令——所有ZNode及其数据

貌似关键的概念都能一一对应上，但是等一下，Paxos岛上的议员应该是人人平等的吧，而ZK Server好像有一个Leader的概念。没错，其实Leader的概念也应该属于Paxos范畴的。如果议员人人平等，在某种情况下会由于提议的冲突而产生一个“活锁”（所谓活锁我的理解是大家都没有死，都在动，但是一直解决不了冲突问题）。Paxos的作者Lamport在他的文章”The Part-Time Parliament“中阐述了这个问题并给出了解决方案——在所有议员中设立一个总统，只有总统有权发出提议，如果议员有自己的提议，必须发给总统并由总统来提出。好，我们又多了一个角色：总统。

总统——ZK Server Leader

又一个问题产生了，总统怎么选出来的？oh, my god! It’s a long story. 在淘宝核心系统团队的Blog上面有一篇文章是介绍如何选出总统的，有兴趣的可以去看看：http://rdc.taobao.com/blog/cs/?p=162（文章已经没了）

现在我们假设总统已经选好了，下面看看ZK Server是怎么实施的。

情况一：

屁民甲(Client)到某个议员(ZK Server)那里询问(Get)某条法令的情况(ZNode的数据)，议员毫不犹豫的拿出他的记事本(local storage)，查阅法令并告诉他结果，同时声明：我的数据不一定是最新的。你想要最新的数据？没问题，等着，等我找总统Sync一下再告诉你。

情况二：

屁民乙(Client)到某个议员(ZK Server)那里要求政府归还欠他的一万元钱，议员让他在办公室等着，自己将问题反映给了总统，总统询问所有议员的意见，多数议员表示欠屁民的钱一定要还，于是总统发表声明，从国库中拿出一万元还债，国库总资产由100万变成99万。屁民乙拿到钱回去了(Client函数返回)。

情况三：

总统突然挂了，议员接二连三的发现联系不上总统，于是各自发表声明，推选新的总统，总统大选期间政府停业，拒绝屁民的请求。

### zab

> zab协议是zookeeper提供的一种类似paxos的分布式一致性算法

转载至https://blog.csdn.net/qq_24313635/article/details/113941996

v整个ZAB协议一共定义了三个阶段：

- **发现**：要求zookeeper集群必须选举出一个 Leader 进程，同时 Leader 会维护一个 Follower 可用客户端列表。将来客户端可以和这些 Follower节点进行通信。
- **同步**：Leader 要负责将本身的数据与 Follower 完成同步，做到多副本存储。这样也是提现了CAP中的高可用和分区容错。Follower将队列中未处理完的请求消费完成后，写入本地事务日志中
- **广播**：Leader 可以接受客户端新的事务Proposal请求，将新的Proposal请求广播给所有的 Follower。

三个阶段执行完为一个周期，在Zookeeper集群的整个生命周期中，这三个阶段会不断进行，如果Leader崩溃或因其它原因导致Leader缺失，ZAB协议会再次进入阶段一。



Zab协议的核心：**定义了事务请求的处理方式**

1. 所有的事务请求必须由一个全局唯一的服务器来协调处理，这样的服务器被叫做 **Leader服务器**。其他剩余的服务器则是 **Follower服务器**。
2. Leader服务器 负责将一个客户端事务请求，转换成一个 **事务Proposal**，并将该 Proposal 分发给集群中所有的 Follower 服务器，也就是向所有 Follower 节点发送数据广播请求（或数据复制）
3. 分发之后Leader服务器需要等待所有Follower服务器的反馈（Ack请求），**在Zab协议中，只要超过半数的Follower服务器进行了正确的反馈**后（也就是收到半数以上的Follower的Ack请求），那么 Leader 就会再次向所有的 Follower服务器发送 Commit 消息，要求其将上一个 事务proposal 进行提交。

Zab 协议包括两种基本的模式：**崩溃恢复** 和 **消息广播**

**崩溃恢复**

**一旦 Leader 服务器出现崩溃或者由于网络原因导致 Leader 服务器失去了与过半 Follower 的联系，那么就会进入崩溃恢复模式。**

前面我们说过，崩溃恢复具有两个阶段：**Leader 选举与初始化同步**。当完成 Leader 选 举后，此时的 Leader 还是一个准 Leader，其要经过初始化同步后才能变为真正的 Leader。


## Java Client Demo

```java
public class Main {
    public static void main(String[] args) {
        zkContext(zk -> {
            try {
                final List<String> children = zk.getChildren("/services", null);
                System.out.println("_____" + children);
                final String bPath = zk.create("/services/b", "b data".getBytes(StandardCharsets.UTF_8),
                        Stream.of(new ACL(ZooDefs.Perms.ALL, ZooDefs.Ids.ANYONE_ID_UNSAFE))
                                .collect(Collectors.toList()),
                        CreateMode.EPHEMERAL);
                System.out.println("_____" + bPath);
                // -1 表示不带version字段
                Stat stat = zk.setData("/services/a", "a content".getBytes(StandardCharsets.UTF_8),
                        -1);
                System.out.println("_____" + stat);
                stat = new Stat();
                // watch为true表示将default watch注册
                // default watch是new Zookeeper()时，传入的watch
                final byte[] aData = zk.getData("/services/a", true, stat);
                System.out.println("_____" + new String(aData, StandardCharsets.UTF_8) + ", " + stat);
                zk.getData("/services/a", true, new AsyncCallback.DataCallback() {
                    @Override
                    public void processResult(int rc, String path, Object ctx, byte[] data, Stat stat) {
                        System.out.println("------ zk async data callback BEGIN ------");
                        System.out.printf("rc: %d, path: %s, ctx: %s, data: %s, stat: %s%n",
                                rc, path, ctx,
                                new String(data, StandardCharsets.UTF_8),
                                stat);
                        System.out.println("------ zk async data callback END ------");
                    }
                }, null);
            } catch (KeeperException | InterruptedException e) {
                e.printStackTrace();
            }
        });
    }

    public static void zkContext(Consumer<ZooKeeper> zkRunner) {
        CountDownLatch latch = new CountDownLatch(1);
        try (final ZooKeeper zk = new ZooKeeper(
                "localhost:2181,localhost:2182,localhost:2183,localhost:2184",
                3000,
                new Watcher() {
                    @Override
                    public void process(WatchedEvent event) {
                        final Event.EventType eventType = event.getType();
                        switch (eventType) {
                            case None:
                                System.out.printf("EventType is %s%n", "None");
                                break;
                            case NodeCreated:
                                System.out.printf("EventType is %s%n", "NodeCreated");
                                break;
                            case NodeDeleted:
                                System.out.printf("EventType is %s%n", "NodeDeleted");
                                break;
                            case NodeDataChanged:
                                System.out.printf("EventType is %s%n", "NodeDataChanged");
                                break;
                            case NodeChildrenChanged:
                                System.out.printf("EventType is %s%n", "NodeChildrenChanged");
                                break;
                            case DataWatchRemoved:
                                System.out.printf("EventType is %s%n", "DataWatchRemoved");
                                break;
                            case ChildWatchRemoved:
                                System.out.printf("EventType is %s%n", "ChildWatchRemoved");
                                break;
                            case PersistentWatchRemoved:
                                System.out.printf("EventType is %s%n", "PersistentWatchRemoved");
                                break;
                            default:
                                break;
                        }

                        final Event.KeeperState keeperState = event.getState();
                        switch (keeperState) {
                            case Unknown:
                                System.out.printf("KeeperState is %s%n", "Unknown");
                                break;
                            case Disconnected:
                                System.out.printf("KeeperState is %s%n", "Disconnected");
                                break;
                            case NoSyncConnected:
                                System.out.printf("KeeperState is %s%n", "NoSyncConnected");
                                break;
                            case SyncConnected:
                                System.out.printf("KeeperState is %s%n", "SyncConnected");
                                latch.countDown();
                                break;
                            case AuthFailed:
                                System.out.printf("KeeperState is %s%n", "AuthFailed");
                                break;
                            case ConnectedReadOnly:
                                System.out.printf("KeeperState is %s%n", "ConnectedReadOnly");
                                break;
                            case SaslAuthenticated:
                                System.out.printf("KeeperState is %s%n", "SaslAuthenticated");
                                break;
                            case Expired:
                                System.out.printf("KeeperState is %s%n", "Expired");
                                break;
                            case Closed:
                                System.out.printf("KeeperState is %s%n", "Closed");
                                break;
                            default:
                                break;
                        }
                    }
                }
        );) {
            // zk 客户端连接是异步的，如果不阻塞可能会显示CONNECTING连接中，利用CountDownLatch，连接后在继续，状态为CONNECTED已连接
            latch.await();
            final ZooKeeper.States zkState = zk.getState();
            switch (zkState) {
                case CONNECTING:
                    System.out.printf("ZkState is %s%n", "CONNECTING");
                    break;
                case ASSOCIATING:
                    System.out.printf("ZkState is %s%n", "ASSOCIATING");
                    break;
                case CONNECTED:
                    System.out.printf("ZkState is %s%n", "CONNECTED");
                    break;
                case CONNECTEDREADONLY:
                    System.out.printf("ZkState is %s%n", "CONNECTEDREADONLY");
                    break;
                case CLOSED:
                    System.out.printf("ZkState is %s%n", "CLOSED");
                    break;
                case AUTH_FAILED:
                    System.out.printf("ZkState is %s%n", "AUTH_FAILED");
                    break;
                case NOT_CONNECTED:
                    System.out.printf("ZkState is %s%n", "NOT_CONNECTED");
                    break;
                default:
                    break;
            }
            zkRunner.accept(zk);
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }
    }
}
```

## zk实现的分布式锁

> 下面是zk实现一个简单的分布式锁
>
> 由于zk的会话特性，我们不需要向redis一样担心宕机后锁没被释放，zk也提供了ttl机制来实现过期时间。
>
> 本身zk就是为了分布式锁、分布式协调服务而生，因此相比Redis锁模型更加健壮。

> zk分布式锁实现原理简介：
>
> 分布式锁的会遇到的几个问题：
>
> 1. 争抢锁，只有一个人能抢到锁
>     - 利用原子自增序列，序号最小的就是抢到锁的
> 2. 抢到锁的人出问题（宕机），如何处理
>     - 利用会话临时节点，宕机后自动删除，也可以使用znode tll设置过期时间
> 3. 释放锁
> 4. 锁被释放删除，别人如何知晓
>     - 心跳轮询，延迟高，性能低
>     - watch父节点，监听子节点删除事件。但是这样压力也很大，会通知所有子节点。
>     - 自增序列节点watch前一个节点，前一个节点被删除时自己就抢到锁了

```java
/**
 * @author liuchongwei
 * @email lcwliuchongwei@qq.com
 * @date 2022-06-01
 * zk客户端工具类
 */
@Data
@Accessors(chain = true)
@Slf4j
public class ZkUtils {

    private String connectStr = "localhost:2181,localhost:2182,localhost:2183,localhost:2184";

    private String rootPath = "";

    private int sessionTimeout = 1000;

    private Watcher defaultWatcher = new DefaultWatch();

    @Getter(AccessLevel.NONE)
    @Setter(AccessLevel.NONE)
    private final CountDownLatch latch = new CountDownLatch(1);

    public class DefaultWatch implements Watcher {
        @Override
        public void process(WatchedEvent event) {
            log.info("DefaultWatch event: " + event);
            switch (event.getState()) {
                case SyncConnected:
                    latch.countDown();
                    break;
                default:
                    break;
            }
        }
    }

    public void zkContext(Consumer<ZooKeeper> zkRunner) {
        try (ZooKeeper zk = new ZooKeeper(String.format("%s%s", connectStr, rootPath),
                sessionTimeout, defaultWatcher)) {
            latch.await();
            zkRunner.accept(zk);
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

```java
/**
 * @author liuchongwei
 * @email lcwliuchongwei@qq.com
 * @date 2022-06-01
 */
@Slf4j
public class TestCase {

    public static ZkUtils zkUtils;

    @Test
    public void testDistributedLock() {
        zkUtils = new ZkUtils()
                .setRootPath("/TestLock");
        zkUtils.zkContext(zk -> {
            for (int i = 0; i < 10; i++) {
                new Thread(() -> {
                    final LockCallBack lockCallBack = new LockCallBack(zk, "LockKey");
                    lockCallBack.setThreadName(Thread.currentThread().getName());
                    try {
                        // 3 8 0 9 4 5 1 7 6 2
                        lockCallBack.lock();
                        log.info("{}线程抢到锁，开始运行运行", Thread.currentThread().getName());
                        try {
                            Thread.sleep(100);
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                    } finally {
                        lockCallBack.unLock();
                    }
                }).start();
            }
            LockSupport.park();
        });
    }
}
```

```java
/**
 * @author liuchongwei
 * @email lcwliuchongwei@qq.com
 * @date 2022-06-01
 * 分布式锁zk回调类
 */
@RequiredArgsConstructor
@Slf4j
public class LockCallBack implements
        Watcher,
        AsyncCallback.StringCallback,
        AsyncCallback.ChildrenCallback {

    private final ZooKeeper zk;

    private final String lockKey;

    /**
     * 锁节点的name，只包含名称不是路径
     */
    private String pathName;

    @Setter
    private String threadName;

    private final CountDownLatch latch = new CountDownLatch(1);

    /**
     * 分布式锁-加锁
     * 利用自增序列来表示新的线程进入阻塞队列，序列数值最小的就是抢到锁的。
     * 利用zk Session临时节点机制在宕机时自动释放锁，也可以使用zk节点的ttl机制设置锁的过期时间
     */
    public void lock() {
        try {
            zk.create("/" + lockKey, threadName.getBytes(StandardCharsets.UTF_8),
                    List.of(new ACL(ZooDefs.Perms.ALL, ZooDefs.Ids.ANYONE_ID_UNSAFE)),
                    CreateMode.EPHEMERAL_SEQUENTIAL,
                    this, null);
            // 等待前一个节点被删除后latch.countDown()放行
            latch.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    /**
     * 分布式锁-解锁
     */
    public void unLock() {
        try {
            // 解锁就是删除节点
            // 最好还是给VoidCallback，处理成功或失败情况，这里就不做处理了
            zk.delete(pathName, -1);
        } catch (InterruptedException | KeeperException e) {
            e.printStackTrace();
        }
    }

    /**
     * watch callback，监听节点的删除事件，节点删除时通知子节点（再次获取子节点即可）
     *
     * @param event 监听事件
     */
    @Override
    public void process(WatchedEvent event) {
        switch (event.getType()) {
            case NodeDeleted:
                log.info("{}节点被删除，重新获取子节点", event.getPath());
                // 再次触发获取子节点的回调（重复解锁或监听前一个节点等待解锁的动作）
                // 不需要watch，现在不关注子节点事件（关注子节点删除事件实在会调用进行的）
                zk.getChildren("/", false, this, null);
                break;
            default:
                break;
        }
    }

    /**
     * string callback，临时序列节点（锁节点）创建成功的回调
     *
     * @param rc   返回码
     * @param path 被创建的节点路径
     * @param ctx  自定义上下文信息
     * @param name 被创建的节点名称
     */
    @Override
    public void processResult(int rc, String path, Object ctx, String name) {
        log.info("{}线程创建锁节点：{}", threadName, name);
        // 后面回调需要监听当前pathName节点的前一个节点
        pathName = name;
        // watch是false，我们现在只需要获取子节点，排序后解锁序列最小的线程
        zk.getChildren("/", false, this, null);
    }

    /**
     * children callback，获取子节点的回调
     * 获取的子节点是无序的，对子节点排序后，监听自己的前一个节点是否被删除（被删除latch发行即可）
     * 如果当前pathName是第一个直接latch放行
     *
     * @param rc       返回码
     * @param path     子节点的父节点路径
     * @param ctx      自定义上下文信息
     * @param children 所有子节点
     */
    @Override
    public void processResult(int rc, String path, Object ctx, List<String> children) {
        log.info("获取子节点信息: {}", children);
        Collections.sort(children);

        // 注意返回的children列表中的节点名称没有 /，pathName需要截取一下
        int index = children.indexOf(pathName.substring(1));

        if (index == 0) {
            // 当前线程是第一个放行
            log.info("{}线程抢到锁，锁节点：{}", threadName, pathName);
            latch.countDown();
        } else {
            // 监听前一个节点，需要watch节点事件，现在关心前一个节点的删除事件
            // StatCallback应该也要处理，看是否成功了，这边就不做处理了
            zk.exists("/" + children.get(index - 1), this, null, null);
        }
    }
}
```

