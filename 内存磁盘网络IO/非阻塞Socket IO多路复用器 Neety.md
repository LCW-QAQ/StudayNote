[TOC]

# 非阻塞Socket IO多路复用器 Neety

## 阻塞式IO代码

```java
import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.CompletableFuture;

public class SocketDemo {
    static class Server {

        public static void main(String[] args) {
            new Server().run();
        }

        public void run() {
            ServerSocket serverSocket = null;

            try {
                serverSocket = new ServerSocket(8080);

                while (true) {
                    // 这里是阻塞的
                    Socket socket = serverSocket.accept();

                   	// 接受连接后交给其他线程处理
                    CompletableFuture.runAsync(() -> {
                        System.out.printf("client: (%s, %s)%n",
                                socket.getInetAddress().getHostAddress(),
                                socket.getPort());
                        InputStream is = null;
                        try {
                            is = socket.getInputStream();
                            byte[] buf = new byte[4096];
                            int len;
                            while ((len = is.read(buf)) != -1) {
                                System.out.println(new String(buf, 0, len));
                            }
                        } catch (IOException e) {
                            e.printStackTrace();
                        } finally {
                            if (is != null) {
                                try {
                                    is.close();
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                            }
                        }
                    });
                }
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if (serverSocket != null) {
                    try {
                        serverSocket.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    static class Client {

        public static void main(String[] args) {
            new Client().run();
        }

        public void run() {
            Socket socket = null;
            try {
                socket = new Socket("localhost", 8080);

                OutputStream os = socket.getOutputStream();
                BufferedReader is = new BufferedReader(new InputStreamReader(System.in));

                while (true) {
                    String str = is.readLine();
                    if (str != null && !str.isEmpty()) {
                        byte[] bytes = str.getBytes(StandardCharsets.UTF_8);
                        os.write(bytes);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if (socket != null) {
                    try {
                        socket.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }
}
```



## C10K 问题

C10K问题的本质上是操作系统的问题。早期操作系统都是以传统的同步阻塞I/O模型处理请求。当并发量上升后, 创建的连接或线程多了，数据拷贝频繁, 缓存I/O、内核将数据拷贝到用户进程空间、阻塞，进程/线程上下文切换消耗大， 导致操作系统崩溃

参考 [http://www.kegel.com/c10k.html](http://www.kegel.com/c10k.html)

并发量提升后传统的阻塞式IO无法应对, 因此非阻塞式IO模型开始被人们重视



## 非阻塞Socket代码

单线程同步非阻塞

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.LinkedList;

public class SocketNIO {
    public static void main(String[] args) throws IOException {
        LinkedList<SocketChannel> clients = new LinkedList<>();

        ServerSocketChannel serverChannel = ServerSocketChannel.open();
        serverChannel.bind(new InetSocketAddress(8080));
        serverChannel.configureBlocking(false); // 服务端非阻塞

        while (true) {
            // 上面设置了非阻塞后, accpect将会立即返回, 不用等待, 如果没有连接他会返回null
            SocketChannel clientChannel = serverChannel.accept();
            // !null 获取到了连接
            // null 没有连接
            if (clientChannel != null) {
                // 客户端非阻塞
                clientChannel.configureBlocking(false);
                System.out.printf("client: %s%n", clientChannel.socket().getPort());
                // 将连接句柄添加到链表中, 后面需要遍历
                clients.add(clientChannel);
            }
            ByteBuffer buf = ByteBuffer.allocate(4096);
            // 遍历所有连接句柄, 如果有数据进行处理
            for (SocketChannel c : clients) {
                // 上面设置了客户端也是非阻塞
                int num = c.read(buf);
                // num > 0 就是有数据
                if (num > 0) {
                    buf.flip();
                    byte[] bytes = new byte[buf.limit()];
                    buf.get(bytes);
                    System.out.println(c.socket().getPort() + " : " + new String(bytes));
                    buf.clear();
                }
            }
        }
    }
}
```



## IO多路复用器

1. 每个socket线程在读取文件的候, 线程都是阻塞的, 这个时期的IO是blocking-io
2. 线程在读取文件时不再阻塞, 线程循环, 观察是否读取完毕, 发现读取完毕后进行处理
    - 优点
        - 同步非阻塞 NIO
        - 非阻塞IO, 可以竟可能的利用CPU资源, 不会因IO阻塞浪费CPU资源
    - 缺点
        - 循环观察发生在用户空间, 性能低
        - 消耗的空间大, 1000个fd, 就需要1000个线程处理
3. 读取文件的操作由select来完成, 遍历所有fd, 看那个能够进行IO, 然后进行处理
    - 优点
        - select多路复用
        - 一个线程监视, 多个scoket的IO请求
        - 不需要在创建N个线程处理
    - 缺点
        - 只需要一个线程, 但是单线程可监视的fd有限
        - 有IO事件发生了, 但是不知道是哪个fd, 所以每次都需要遍历所有fd, 线性查找, 效率低
4. poll, 本质上和select是一样的, 区别就是poll使用的是链表存储fd, 没有监视数量限制
    - 优点
        - 同select
        - 没有连接数即监视fd数量上的限制, 使用链表存储
    - 缺点
        - 同样使用轮询, 线性查找, 效率低
        - 水平触发, 收到了fd消息后, 若没有被处理, 下次还会报告该fd
5. select 和 poll 只触发了一次系统调用, 由内核来完成遍历
6. epoll, 使用事件处理模型, 不同于轮询, 只会通知发生了IO事件的fd, 实际上是事件驱动的, 相当于复杂度降到了O(1)
    - 优点
        - epoll 并发限制, 连接数与内存大小有关
        - 不需要轮询, 只需要处理触发事件的fd, 通过回调函数处理
        - 有两种触发模式
            - EPOLLLT
                - 默认模式, 水平触发模式, 只要epoll实例中有就绪的fd, 每次epoll_wait, 都会返回就绪fd，哪怕就绪的fd上没有发生新的IO事件
            - EPOLLET
                - 边缘触发模式, 只会提示一次, 直到再有数据流入之前都不会再提示. 
                - 由于只提醒一次，所以使用时无论fd中是否还有数据可读，一次把buffer读光更好，不然容易出现问题。
                - 使用select与poll, 只要有就绪的fd, 每次epoll_wait都会获取所有就绪fd, 大幅降低检索fd的性能. 而epoll尽当被监控的fd上发生新的IO事件时, 才去通知, 系统中不会充满我们不关心的就绪fd
            - EPOLLONESHOT
              - 该模式保证fd的IO事件只会被处理一次，也就是epoll_wait获取一次，如果想要继续监听其IO事件，需要再次调用epoll_ctl注册
              - 边缘模式虽然性能更高，但是我们需要一次性读取完数据不然可能出现死等待后超时，并且在多个线程(或进程，下同)处理同一个fd的多个事件时，一个线程监听到IO事件正在处理数据，此时又有新的IO事件被另一个线程处理，这是我们不希望出现的竟态条件。此时就可以使用EPOLLONESHOT，保证socket在任意时刻只被一个线程处理，如果想要继续处理，在处理结束时再次通过epoll_ctl注册即可。
        - epoll 只会关心活跃的连接和连接数无关, 提升检索连接性能, 性能远高于select poll
        - IO使用mmap
            - 跨过了页缓存, 减少数据从用户态到内核态的拷贝次数, 提高文件读写效率
            - 用户态到内核态高效交互, 两者的修改直接反映在自己的局域内, 及时被对方捕捉

### IO多路复用器 Java代码

#### 客户端代码

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.channels.SocketChannel;

public class C10K {
    public static void main(String[] args) {
        InetSocketAddress serverAddr = new InetSocketAddress("192.168.150.100", 8080);
        for (int i = 10000; i < 65535; i++) {
            try {
                // 测试就不关流了
                SocketChannel channel1 = SocketChannel.open();
                channel1.bind(new InetSocketAddress("192.168.150.1", i));
                channel1.connect(serverAddr);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
```



#### 服务端代码

##### 单线程 - 读写事件合并

> 单线程中线性处理

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;
import java.util.Set;

public class SocketMultiplexingSingleThread_1 {

    ServerSocketChannel serverChannel;

    // 多路复用器
    Selector selector;

    public void init() {
        try {
            serverChannel = ServerSocketChannel.open();
            // 非阻塞
            serverChannel.configureBlocking(false);
            serverChannel.bind(new InetSocketAddress(8080));

            // 创建多路复用器对象, linux默认epoll
            // 对应linux中的epoll_create 创建多路复用器
            selector = Selector.open();

            // 注册当前server的fd
            // 对应linux中的epoll_ctl(fd, ADD, OP_EPOLL)
            serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void run() {
        init();
        try {
            for (; ; ) {
                // 对应linux中的epoll_wait
                while (selector.select(100) > 0) {
                    // 所有有状态的fd
                    Set<SelectionKey> keys = selector.selectedKeys();
                    for (Iterator<SelectionKey> it = keys.iterator(); it.hasNext(); ) {
                        SelectionKey key = it.next();
                        // 这里一定要删除, 不然会重复循环 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        // 不是在linux fd红黑树中删除, 在jvm维护的结果集中删除, it.getClass(), 底层是一个HashMap, it是map的迭代器
                        it.remove();
                        // 接受一个新的连接
                        if (key.isAcceptable()) {
                            acceptHandler(key);
                        } else if (key.isReadable()) {
                            readHandler(key);
                        } else if (key.isWritable()) {

                        } else if (key.isConnectable()) {

                        } else if (key.isValid()) {

                        }
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理接受连接事件
    public void acceptHandler(SelectionKey key) {
        try {
            ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
            SocketChannel client = serverChannel.accept();
            // 一定记得要把client设为非阻塞
            client.configureBlocking(false);
            ByteBuffer buf = ByteBuffer.allocate(4096);
            // 将新连接注册为读事件
            // 有数据从连接过来时, 可以捕获到读取事件
            client.register(selector, SelectionKey.OP_READ, buf);
            System.out.println("----------------------------");
            System.out.println("新的客户端: " + client.getRemoteAddress());
            System.out.println("----------------------------");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理读取事件
    // 这个方法实际上即处理了读事件也处理了写入
    public void readHandler(SelectionKey key) {
        SocketChannel clientChannel = (SocketChannel) key.channel();
        // 获取附件, 这里可以是任何对象, 上面处理连接时, 使用的是ByteBuffer, 这里直接强转
        ByteBuffer buf = (ByteBuffer) key.attachment();
        buf.clear();
        // 是否读取到数据
        int num;
        try {
            for (; ; ) {
                // 读取数据到buf里
                num = clientChannel.read(buf);
                // 如果有客户端有发送数据
                if (num > 0) {
                    // 反转后可以写入
                    buf.flip();
                    // 只要还有数据就继续写入
                    // 处理写入
                    while (buf.hasRemaining()) {
                        clientChannel.write(buf);
                    }
                    // 清楚buf数据
                    buf.clear();
                } else if (num == 0) {
                    break;
                } else {
                    // 四次分手, 服务端需要响应断开, 如果不close客户端channel, 服务端会出现close_wat, 客户端会出现FIN_WAIT2
                    clientChannel.close();
                    break;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        new SocketMultiplexingSingleThread_1().run();
    }
}
```

##### 单线程 - 读写事件分离

> 单线程中线性处理

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;
import java.util.Set;

public class SocketMultiplexingSingleThread_1_1 {

    ServerSocketChannel serverChannel;

    // 多路复用器
    Selector selector;

    public void init() {
        try {
            serverChannel = ServerSocketChannel.open();
            // 非阻塞
            serverChannel.configureBlocking(false);
            serverChannel.bind(new InetSocketAddress(8080));

            // 创建多路复用器对象, linux默认epoll
            // 对应linux中的epoll_create 创建多路复用器
            selector = Selector.open();

            // 注册当前server的fd
            // 对应linux中的epoll_ctl(fd, ADD, OP_EPOLL)
            serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void run() {
        init();
        try {
            for (; ; ) {
                // 对应linux中的epoll_wait
                while (selector.select(100) > 0) {
                    // 所有有状态的fd
                    Set<SelectionKey> keys = selector.selectedKeys();
                    for (Iterator<SelectionKey> it = keys.iterator(); it.hasNext(); ) {
                        SelectionKey key = it.next();
                        // 这里一定要删除, 不然会重复循环 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        // 不是在linux fd红黑树中删除, 在jvm维护的结果集中删除, it.getClass(), 底层是一个HashMap, it是map的迭代器
                        it.remove();
                        // 接受一个新的连接
                        if (key.isAcceptable()) {
                            acceptHandler(key);
                        } else if (key.isReadable()) {
                            readHandler(key);
                        } else if (key.isWritable()) {
                            writeHandler(key);
                        } else if (key.isConnectable()) {

                        } else if (key.isValid()) {

                        }
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理接受连接事件
    public void acceptHandler(SelectionKey key) {
        try {
            ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
            SocketChannel client = serverChannel.accept();
            // 一定记得要把client设为非阻塞
            client.configureBlocking(false);
            ByteBuffer buf = ByteBuffer.allocate(4096);
            // 将新连接注册为读事件
            // 有数据从连接过来时, 可以捕获到读取事件
            client.register(selector, SelectionKey.OP_READ, buf);
            System.out.println("----------------------------");
            System.out.println("新的客户端: " + client.getRemoteAddress());
            System.out.println("----------------------------");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理读取事件
    public void readHandler(SelectionKey key) {
        System.out.println("read handler");
        SocketChannel clientChannel = (SocketChannel) key.channel();
        // 获取附件, 这里可以是任何对象, 上面处理连接时, 使用的是ByteBuffer, 这里直接强转
        ByteBuffer buf = (ByteBuffer) key.attachment();
        buf.clear();
        // 是否读取到数据
        int num;
        try {
            for (; ; ) {
                num = clientChannel.read(buf);
                if (num > 0) {
                    // 需要写入, 注册写事件, 具体如何写入, 有writeHandler控制
                    clientChannel.register(selector, SelectionKey.OP_WRITE, buf);
                } else if (num == 0) {
                    break;
                } else {
                    clientChannel.close();
                    break;
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理写事件
    public void writeHandler(SelectionKey key) {
        System.out.println("write handler");
        SocketChannel clientChannel = (SocketChannel) key.channel();
        ByteBuffer buf = (ByteBuffer) key.attachment();
        // 翻转buf, 需要读取buf里的内容
        buf.flip();
        // 还有剩余的就写到客户端那边去
        while (buf.hasRemaining()) {
            try {
                clientChannel.write(buf);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        // 读取完后记得clear, 转回写入模式
        buf.clear();
        try {
            clientChannel.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        new SocketMultiplexingSingleThread_1_1().run();
    }
}
```

##### 多线程

> 多线程处理, 但是必须调用key.cancel(), cancel会涉及到system call, 影响性能

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.Iterator;
import java.util.Set;
import java.util.concurrent.CompletableFuture;

public class SocketMultiplexingSingleThread_2 {

    ServerSocketChannel serverChannel;

    // 多路复用器
    Selector selector;

    public void init() {
        try {
            serverChannel = ServerSocketChannel.open();
            // 非阻塞
            serverChannel.configureBlocking(false);
            serverChannel.bind(new InetSocketAddress(8080));

            // 创建多路复用器对象, linux默认epoll
            // 对应linux中的epoll_create 创建多路复用器
            selector = Selector.open();

            // 注册当前server的fd
            // 对应linux中的epoll_ctl(fd, ADD, OP_EPOLL)
            serverChannel.register(selector, SelectionKey.OP_ACCEPT);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void run() {
        init();
        try {
            for (; ; ) {
                // 对应linux中的epoll_wait
                while (selector.select(100) > 0) {
                    // 所有有状态的fd
                    Set<SelectionKey> keys = selector.selectedKeys();
                    for (Iterator<SelectionKey> it = keys.iterator(); it.hasNext(); ) {
                        SelectionKey key = it.next();
                        // 这里一定要删除, 不然会重复循环 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        // 不是在linux fd红黑树中删除, 在jvm维护的结果集中删除, it.getClass(), 底层是一个HashMap, it是map的迭代器
                        it.remove();
                        // 接受一个新的连接
                        if (key.isAcceptable()) {
                            acceptHandler(key);
                        } else if (key.isReadable()) {
                            // 调用linux中epoll_ctl(del), 这个才是真的从内核的fd红黑树中删除
                            key.cancel();
                            /*
						  如果没有调用key.cancel(), key仍然存在于linux内核的fd红黑树中
						  下面的handler方法已经不是阻塞的了
						  运行readHandler后, while循环继续判断, key仍存在内核fd红黑树中, key的事件也仍然存在, 就在这个时差内
						  while 循环selector.select, 会继续获取到key的事件, 然而此时key的事件其实已经被其他线程正在处理
						  导致handler重复处理, key.cancel() 删除后, 就不会重复select了
                            */
                            readHandler(key);
                        } else if (key.isWritable()) {
                            // 调用linux中epoll_ctl(del), 这个才是真的从内核的fd红黑树中删除
                            key.cancel();
                            writeHandler(key);
                        } else if (key.isConnectable()) {

                        } else if (key.isValid()) {

                        }
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    // 处理接受连接事件
    public void acceptHandler(SelectionKey key) {
        CompletableFuture.runAsync(() -> {
            try {
                ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
                SocketChannel client = serverChannel.accept();
                // 一定记得要把client设为非阻塞
                client.configureBlocking(false);
                ByteBuffer buf = ByteBuffer.allocate(4096);
                // 将新连接注册为读事件
                // 有数据从连接过来时, 可以捕获到读取事件
                client.register(selector, SelectionKey.OP_READ, buf);
                System.out.println("----------------------------");
                System.out.println("新的客户端: " + client.getRemoteAddress());
                System.out.println("----------------------------");
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    // 处理读取事件
    public void readHandler(SelectionKey key) {
        CompletableFuture.runAsync(() -> {
            System.out.println("read handler");
            SocketChannel clientChannel = (SocketChannel) key.channel();
            // 获取附件, 这里可以是任何对象, 上面处理连接时, 使用的是ByteBuffer, 这里直接强转
            ByteBuffer buf = (ByteBuffer) key.attachment();
            buf.clear();
            // 是否读取到数据
            int num;
            try {
                for (; ; ) {
                    num = clientChannel.read(buf);
                    if (num > 0) {
                        // 需要写入, 注册写事件, 具体如何写入, 有writeHandler控制
                        clientChannel.register(selector, SelectionKey.OP_WRITE, buf);
                    } else if (num == 0) {
                        break;
                    } else {
                        clientChannel.close();
                        break;
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    // 处理写事件
    public void writeHandler(SelectionKey key) {
        CompletableFuture.runAsync(() -> {
            System.out.println("write handler");
            SocketChannel clientChannel = (SocketChannel) key.channel();
            ByteBuffer buf = (ByteBuffer) key.attachment();
            // 翻转buf, 需要读取buf里的内容
            buf.flip();
            // 还有剩余的就写到客户端那边去
            while (buf.hasRemaining()) {
                try {
                    clientChannel.write(buf);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            // 读取完后记得clear, 转回写入模式
            buf.clear();
            try {
                clientChannel.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
    }

    public static void main(String[] args) {
        new SocketMultiplexingSingleThread_2().run();
    }
}
```

## linux epol系列函数讲解
1. 调用epoll_create创建epoll实例
2. 将需要处理IO事件的fd利用epoll_ctl注册到epoll实例上
3. 通过epoll_wait函数获取IO事件并进行处理
### 利用epoll读取stdin
```c
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <unistd.h>

const int MAX_EP_EVENTS = 10;
const int BUF_SIZE = 1024;

int main(int argc, const char **argv) {
  int fd;
  if ((fd = open("/dev/stdin", O_RDONLY)) == -1) {
    fprintf(stderr, "open /dev/stdin error: %s\n", strerror(errno));
    return 1;
  }
  // 创建epoll实例
  int epfd = epoll_create1(EPOLL_CLOEXEC);

  // 创建需要注册到epoll实例上的事件
  struct epoll_event ev;
  // 设置监听的fd
  ev.data.fd = fd;
  /*
    设置监听的事件类型, EPOLLIN表示读取时间, EPOLLPRI表示重要的读取事件,
    详细可以查询带外数据
    (传输层提供的一种可以紧急处理数据的方式，各种协议的处理都不一样)
    EPOLLET表示边缘触发，即只有当fd上的IO有新的输入输出时才会返回，否则之前哪怕数据没有读取完成也不会返回
    如果不设置EVENT为EPOLLET默认是EPOLLLT水平出发，只要有就绪的fd就返回，哪怕fd上面没有任何IO
  */
  // ev.events = EPOLLIN | EPOLLPRI;
  ev.events = EPOLLIN | EPOLLPRI | EPOLLET;
  // 将时间注册到epoll实例上
  epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);

  // 创建用于接收epoll事件的数组
  struct epoll_event ep_events[MAX_EP_EVENTS];

  char buf[BUF_SIZE];

  while (1) {
    printf("----------\n");
    // 等待IO时间
    int ready = epoll_wait(epfd, ep_events, MAX_EP_EVENTS, 5000);
    // -1 表示错误
    if (ready == -1) {
      fprintf(stderr, "epoll_wait error: %s\n", strerror(errno));
      return 1;
    }
    // ready为0表示没有就绪的文件描述符(即没有任何IO时间)
    if (ready == 0) {
      printf("epoll_wait timeout\n");
    }
    printf("ready: %d\n", ready);
    for (int i = 0; i < ready; i++) {
      // 处理读取事件
      if (ep_events[i].events & EPOLLIN) {
        // 初始化buf
        memset(buf, 0, BUF_SIZE);
        int read_cnt = read(ep_events[i].data.fd, buf, BUF_SIZE);
        if (read_cnt == -1) {
          fprintf(stderr, "read_cnt error: %s", strerror(errno));
        } else if (read_cnt > 0) {
          // 输出读取到buf中的数据
          buf[read_cnt] = '\0';
          printf("%s", buf);
        } else if (read_cnt == 0) {
          close(ep_events[i].data.fd);
          ep_events[i].events = 0;
        }
      }
    }
  }

  return 0;
}
```

### 利用epoll处理tcp流
```c
#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <netinet/in.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#define bool char
#define true 1
#define false 0

const int MAX_EP_EVENT = 1024;
const int BUFFER_SIZE = 1024;
static int listen_fd;

/**
 * @brief 将给定fd设置为非阻塞
 *
 * @param fd fd
 * @return int 之前的fl options设置
 */
int setnonblocking(int fd) {
  int old_ops = fcntl(fd, F_GETFL);
  fcntl(fd, F_SETFL, old_ops | O_NONBLOCK);
  return old_ops;
}

/**
 * @brief 注册fd事件
 *
 * @param epfd epoll实例fd
 * @param fd 被注册的fd
 * @param enable_et 是否开启et边缘触发
 */
void register_fd(int epfd, int fd, bool enable_et) {
  setnonblocking(fd);
  struct epoll_event ev;
  bzero(&ev, sizeof(ev));
  ev.data.fd = fd;
  ev.events = EPOLLIN | EPOLLPRI;
  if (enable_et) {
    ev.events |= EPOLLET;
  }
  epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
}

void et_process(struct epoll_event* ep_events, int ready_num, int epfd,
                int listen_fd) {
  char buf[BUFFER_SIZE];
  for (int i = 0; i < ready_num; i++) {
    int sockfd = ep_events[i].data.fd;
    // 特殊处理server fd
    if (sockfd == listen_fd) {
      // struct sockaddr client_addr;
      struct sockaddr_in client_addr;
      socklen_t client_socklen = sizeof(client_addr);
      int conn_fd = accept(listen_fd, (struct sockaddr*)&client_addr, &client_socklen);
      register_fd(epfd, conn_fd, true);
    } else if (ep_events[i].events & EPOLLIN) {
      // 处理读取事件
      // 边缘触发，由于其机制我们需要巨额宝一次性读取完，当前流中的数据，不然可能出现死等待后超时
      printf("et process EPOLLIN\n");
      while (true) {
        memset(buf, '\0', BUFFER_SIZE);
        int read_cnt = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
        if (read_cnt == -1) {
          // 这里体现了边缘触发与水平触发处理上的区别
          /*
            在边缘触发模式下，如果错误类型是EAGAIN或者EWOULDBLOCK
            那么表示数据已经全部读取完毕，之后epoll_wait可以再次监听到当前sockfd上的EPOLLIN事件
            所以这是不做关闭操作的
          */
          if (errno == EAGAIN || errno == EWOULDBLOCK) {
            printf("read later\n");
            break;
          }
          fprintf(stderr, "recv error: %s\n", strerror(errno));
          close(sockfd);
          break;
        } else if (read_cnt == 0) {
          close(sockfd);
          break;
        } else {
          printf("get %d bytes from buf, content: %s\n", read_cnt, buf);
        }
      }
    }
  }
}

void lt_process(struct epoll_event* ep_events, int ready_num, int epfd,
                int listen_fd) {
  char buf[BUFFER_SIZE];
  for (int i = 0; i < ready_num; i++) {
    int sockfd = ep_events[i].data.fd;
    // 对tcp流的fd即server的fd特殊处理
    if (sockfd == listen_fd) {
      struct sockaddr client_addr;
      socklen_t client_socklen = sizeof(client_addr);
      int conn_fd = accept(listen_fd, &client_addr, &client_socklen);
      register_fd(epfd, conn_fd, false);
    } else if (ep_events[i].events & EPOLLIN) {
      // 处理读取事件
      memset(buf, '\0', BUFFER_SIZE);
      int read_cnt = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
      if (read_cnt <= 0) {  // 异常与流关闭
        // 返回-1表示异常，返回0表示没有数据需要读取了请关闭流。
        if (read_cnt == -1) {
          fprintf(stderr, "recv error: %s\n", strerror(errno));
        }
        close(sockfd);
        printf("closed sockfd\n");
        continue;
      } else {
        printf("get %d bytes from buf, content: %s\n", read_cnt, buf);
      }
    }
  }
}

void sigint_handler(int sig) {
  printf("sig: %d, listen_fd: %d, sigint handler run...\n", sig, listen_fd);
  close(listen_fd);
}

int main(int argc, char** argv) {
  /*if (argc <= 2) {
    fprintf(stderr, "usage: %s ip_address port_number\n", basename(argv[0]));
  }*/

  /*const char* ip = argv[1];
  int port = atoi(argv[2]);*/
  const char* ip = "localhost";
  int port = 8080;
  struct sockaddr_in addr;
  // 初始化socket addr对象
  memset(&addr, 0, sizeof(addr));
  // 设置ipv4通信
  addr.sin_family = AF_INET;
  // 将`ip`10进制字符串以ipv4方式格式化称二进制数据，存入addr对象的sin_addr中
  inet_pton(AF_INET, ip, &addr.sin_addr);
  // 网路通信中使用的是大端, htons可以加个port转换为网络传输中需要的大端
  addr.sin_port = htons(port);

  // 创建tcp流
  /*
    posix系统规范规定设置地址时使用AF_INET，创建套接字时使用PF_INET
    AF_INET与PF_INET都表示ipv4，在大多数系统中他们的值都会一样的
    SOCK_STREAM表示tcp协议
  */
  listen_fd = socket(PF_INET, SOCK_STREAM, 0);
  int on = 1;
  if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)) == -1) {
    fprintf(stderr, "setsockopt error: %s\n", strerror(errno));
    return 1;
  }
  if (listen_fd == -1) {
    fprintf(stderr, "socket create error: %s\n", strerror(errno));
    return 1;
  }
  // 绑定监听地址
  int status = bind(listen_fd, (struct sockaddr*)&addr, sizeof(addr));
  if (status == -1) {
    fprintf(stderr, "bind error: %s\n", strerror(errno));
    return 1;
  }
  // 开始监听，1024参数表示最大可以接受的连接数量，后续连接会被拒绝
  status = listen(listen_fd, 1024);
  if (status == -1) {
    fprintf(stderr, "listen error: %s\n", strerror(errno));
    return 1;
  }

  int epfd = epoll_create1(EPOLL_CLOEXEC);
#ifdef EPOLLET_ENABLED
  register_fd(epfd, listen_fd, true);
#else
  register_fd(epfd, listen_fd, false);
#endif

  struct epoll_event ep_evnets[MAX_EP_EVENT];

  // 注册SIGINT信号处理器, 在ctrl c终止信号后关闭IO流
  signal(SIGINT, sigint_handler);

  while (true) {
    int ready = epoll_wait(epfd, ep_evnets, MAX_EP_EVENT, -1);
    if (ready == -1) {
      fprintf(stderr, "epoll_wait error: %s\n", strerror(errno));
      return 1;
    }

#ifdef EPOLLET_ENABLED
    et_process(ep_evnets, ready, epfd, listen_fd);
#else
    lt_process(ep_evnets, ready, epfd, listen_fd);
#endif
  }
  // 关闭tcp流
  close(listen_fd);
  return 0;
}
```

### epoll多线程处理tcp流 
```c
#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <netinet/in.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <sys/socket.h>
#include <unistd.h>

#define bool char
#define true 1
#define false 0

const int MAX_EP_EVENT = 1024;
const int BUFFER_SIZE = 1024;
static int listen_fd;

struct woker_process_param {
  int epfd;
  int sockfd;
};

void woker_process(void* arg) {
  struct woker_process_param* param = (struct woker_process_param*)arg;
  int epfd = param->epfd;
  int sockfd = param->sockfd;
  char buf[BUFFER_SIZE];
  memset(buf, '\0', BUFFER_SIZE);
  while (true) {
    int read_cnt = recv(sockfd, buf, BUFFER_SIZE - 1, 0);
    if (read_cnt == -1) {
      // EAGAIN与EWOULDBLOCK的值是一样，事实上只判断其中一个就足够了
      if (errno == EAGAIN || errno == EWOULDBLOCK) {
        reset_oneshot(epfd, sockfd);
        printf("read later\n");
        break;
      }
    } else if (read_cnt == 0) {
      close(sockfd);
      printf("close sockfd: %d\n", sockfd);
      break;
    } else {
      printf("get %d bytes from buf, content: %s\n", read_cnt, buf);
      sleep(5);  // 模拟处理时间，一遍观察多线程下的处理效果
    }
  }
  printf("end of thread woker processing data on sockfd: %d\b", sockfd);
}

/**
 * @brief 将给定fd设置为非阻塞
 *
 * @param fd fd
 * @return int 之前的fl options设置
 */
int setnonblocking(int fd) {
  int old_ops = fcntl(fd, F_GETFL);
  fcntl(fd, F_SETFL, old_ops | O_NONBLOCK);
  return old_ops;
}

/**
 * @brief 注册fd事件
 *
 * @param epfd epoll实例fd
 * @param fd 被注册的fd
 * @param enable_oneshot
 * 是否开启EPOLLONESHOT，开启后每次只能处理一个IO事件，新的IO事件发生时需要再次epoll_ctl注册才能处理
 */
void register_fd(int epfd, int fd, bool enable_oneshot) {
  setnonblocking(fd);
  struct epoll_event ev;
  bzero(&ev, sizeof(ev));
  ev.data.fd = fd;
  // 默认ET边缘触发
  ev.events = EPOLLIN | EPOLLPRI | EPOLLET;
  if (enable_oneshot) {
    ev.events |= EPOLLONESHOT;
  }
  epoll_ctl(epfd, EPOLL_CTL_ADD, fd, &ev);
}

/**
 * @brief 将fd重置为EPOLLONESHOT，以便继续处理fd的IO事件
 * 
 * @param epfd 
 * @param fd 
 */
void reset_oneshot(int epfd, int fd) {
  struct epoll_event ev;
  ev.data.fd = fd;
  ev.events = EPOLLIN | EPOLLPRI | EPOLLONESHOT;
  // 注意这里使用的是EPOLL_CTL_MOD，之前已经添加过了这里只需要更改即可
  epoll_ctl(epfd, EPOLL_CTL_MOD, fd, &ev);
}

void sigint_handler(int sig) {
  printf("sig: %d, listen_fd: %d, sigint handler run...\n", sig, listen_fd);
  close(listen_fd);
}

int main(int argc, char** argv) {
  /*if (argc <= 2) {
    fprintf(stderr, "usage: %s ip_address port_number\n", basename(argv[0]));
  }*/

  /*const char* ip = argv[1];
  int port = atoi(argv[2]);*/
  const char* ip = "localhost";
  int port = 8080;
  struct sockaddr_in addr;
  // 初始化socket addr对象
  memset(&addr, 0, sizeof(addr));
  // 设置ipv4通信
  addr.sin_family = AF_INET;
  // 将`ip`10进制字符串以ipv4方式格式化称二进制数据，存入addr对象的sin_addr中
  inet_pton(AF_INET, ip, &addr.sin_addr);
  // 网路通信中使用的是大端, htons可以加个port转换为网络传输中需要的大端
  addr.sin_port = htons(port);

  // 创建tcp流
  /*
    posix系统规范规定设置地址时使用AF_INET，创建套接字时使用PF_INET
    AF_INET与PF_INET都表示ipv4，在大多数系统中他们的值都会一样的
    SOCK_STREAM表示tcp协议
  */
  listen_fd = socket(PF_INET, SOCK_STREAM, 0);
  int on = 1;
  if (setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on)) == -1) {
    fprintf(stderr, "setsockopt error: %s\n", strerror(errno));
    return 1;
  }
  if (listen_fd == -1) {
    fprintf(stderr, "socket create error: %s\n", strerror(errno));
    return 1;
  }
  // 绑定监听地址
  int status = bind(listen_fd, (struct sockaddr*)&addr, sizeof(addr));
  if (status == -1) {
    fprintf(stderr, "bind error: %s\n", strerror(errno));
    return 1;
  }
  // 开始监听，1024参数表示最大可以接受的连接数量，后续连接会被拒绝
  status = listen(listen_fd, 1024);
  if (status == -1) {
    fprintf(stderr, "listen error: %s\n", strerror(errno));
    return 1;
  }

  int epfd = epoll_create1(EPOLL_CLOEXEC);
  // 注册server fd, 且不适用EPOLLONESHOT, server fd我们需要长期监听
  register_fd(epfd, listen_fd, false);

  struct epoll_event ep_evnets[MAX_EP_EVENT];

  // 注册SIGINT信号处理器, 在ctrl c终止信号后关闭IO流
  signal(SIGINT, sigint_handler);

  while (true) {
    int ready = epoll_wait(epfd, ep_evnets, MAX_EP_EVENT, -1);
    if (ready == -1) {
      fprintf(stderr, "epoll_wait error: %s\n", strerror(errno));
      return 1;
    }

    for (int i = 0; i < ready; i++) {
      int sockfd = ep_evnets[i].data.fd;
      if (sockfd == listen_fd) {
        struct sockaddr client_addr;
        socklen_t client_socklen = sizeof(client_addr);
        int conn_fd = accept(listen_fd, &client_addr, &client_socklen);
        register_fd(epfd, conn_fd, true);
      } else if (ep_evnets[i].events & EPOLLIN) {
        // 开辟新线程处理读取事件
        pthread_t thread;
        struct woker_process_param param;
        param.epfd = epfd;
        param.sockfd = sockfd;
        pthread_create(&thread, NULL, (void* (*)(void*))woker_process,
                       (void*)&param);
      }
    }
  }
  // 关闭tcp流
  close(listen_fd);
  return 0;
}
```