# Zookeeper 实现分布式锁

> 使用10个线程分别去获取锁, 并打印线程名, 释放锁
>
> - 获取锁
>     - 每个线程都去zookeeper创建一个带序列的lock节点, 然后通过CountDownLatch阻塞住
>     - 回调string callback
>         - 创建成功后, 再去获取其他的锁节点
>     - 回调children callback
>         - 每个子节点都可以看到其他锁, 但是锁并不是有序的, 所以需要排序
>         - 判断自己的节点path, 是否是第一个(第一把锁, 是否轮到我干活了)
>             - true
>                 - countDown(); 轮到自己干活了, 停止阻塞, 继续运行
>             - false
>                 - 监控前一把锁节点, 是否被删除
>                     - 被删除后, 再次获取其他锁节点重复children callback过程

ZKUtils 工具类

```java
public class ZKUtils {
    private static final String ADDRESS =
            "192.168.150.100:2181,192.168.150.101:2181,192.168.150.102:2181,192.168.150.103:2181/testLock";

    public static ZooKeeper getZK() {
        ZooKeeper zk = null;
        try {
            DefaultWatcher.INSTANCE.latchInit();
            zk = new ZooKeeper(ADDRESS, 1000, DefaultWatcher.INSTANCE);
            DefaultWatcher.INSTANCE.cdl.await();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
        return zk;
    }
}
```

WatchCallBack 集合回调类

```java
public class WatchCallBack implements Watcher,
        AsyncCallback.StringCallback,
        AsyncCallback.Children2Callback,
        AsyncCallback.StatCallback {
    ZooKeeper zk;

    String threadName;

    String pathName;

    CountDownLatch cdl = new CountDownLatch(1);

    public void setZk(ZooKeeper zk) {
        this.zk = zk;
    }

    public void setThreadName(String threadName) {
        this.threadName = threadName;
    }

    public void setPathName(String pathName) {
        this.pathName = pathName;
    }

    public void troyLock() {
        try {
            zk.create("/lock", threadName.getBytes(StandardCharsets.UTF_8),
                    ZooDefs.Ids.OPEN_ACL_UNSAFE, CreateMode.EPHEMERAL_SEQUENTIAL, this, null);
            cdl.await();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    public void unlock() {
        try {
            zk.delete(pathName, -1);
        } catch (InterruptedException | KeeperException e) {
            e.printStackTrace();
        }
    }

    // watcher
    @Override
    public void process(WatchedEvent watchedEvent) {
        Event.EventType type = watchedEvent.getType();
        switch (type) {
            case None:
            case NodeCreated:
            case NodeDataChanged:
            case NodeChildrenChanged:
            case DataWatchRemoved:
            case ChildWatchRemoved:
                break;
            case NodeDeleted:
                zk.getChildren("/", false, this, null);
                break;
        }
    }

    // string callback
    @Override
    public void processResult(int i, String s, Object o, String s1) {
        if (s1 != null) {
            System.out.println(threadName + " create node: " + s1);
            pathName = s1;
            zk.getChildren("/", false, this, null);
        }
    }

    // children callback
    @Override
    public void processResult(int i, String s, Object o, List<String> list, Stat stat) {
        list.sort(Comparator.naturalOrder());
        int idx = list.indexOf(pathName.substring(1));
        if (idx == 0) {
            System.out.println(threadName + " get lock, i'm first");
            try {
                zk.setData("/", threadName.getBytes(StandardCharsets.UTF_8), -1);
                cdl.countDown();
            } catch (KeeperException | InterruptedException e) {
                e.printStackTrace();
            }
        } else {
            zk.exists("/".concat(list.get(idx - 1)), this, this, null);
        }
    }

    // stat callback
    @Override
    public void processResult(int i, String s, Object o, Stat stat) {
    }
}
```

```java
public class TestLock {
    ZooKeeper zk;

    @Before
    public void conn() {
        zk = ZKUtils.getZK();
    }

    @After
    public void close() {
        try {
            zk.close();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void lock() {
        for (int i = 0; i < 10; i++) {
            new Thread(() -> {
                WatchCallBack watchCallBack = new WatchCallBack();
                watchCallBack.setZk(zk);
                watchCallBack.setThreadName(Thread.currentThread().getName());
                watchCallBack.troyLock();
                System.out.println(Thread.currentThread().getName() + " working...");
                watchCallBack.unlock();
            }).start();
        }
        while (true) ;
    }
}
```