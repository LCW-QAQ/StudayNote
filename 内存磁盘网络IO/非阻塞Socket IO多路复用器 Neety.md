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
6. epoll, 使用时间处理模型, 不同于轮询, 只会通知发生了IO事件的fd, 实际上是事件驱动的, 相当于复杂度降到了O(1)
    - 优点
        - epoll 并发限制, 连接数与内存大小有关
        - 不需要轮询, 只需要处理触发事件的fd, 通过回调函数处理
        - 有两种触发模式
            - EPOLLLT
                - 默认模式, 只要fd还有数据可以读, 每次epoll_wait, 都会返回fd的读取事件, 提醒用户去操作
            - EPOLLET
                - 边缘触发模式, 只会提示一次, 直到再有数据流入之前都不会再提示, 无论fd中是否还有数据可读, 一次把buffer读光
                - 如果系统中有我们不关心的fd, 每次epoll_wait都触发, 大幅降低检索fd的性能, 当被监控的fd上发生IO事件时, 再去通知程序读写, 系统中不会充满我们不关心的就绪fd
        - epoll 只会关心活跃的连接和连接数无关, 提升检索连接性能, 性能远高于select poll
        - IO使用mmap
            - 跨过了页缓存, 减少数据从用户态到内核态的拷贝次数, 提高文件读写效率
            - 用户态到内核态高效交互, 两者的修改直接反映在自己的局域内, 及时被对方捕捉

### IO多路复用器 Java代码

#### 服务端代码

##### 单线程

```java
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.*;
import java.util.Iterator;
import java.util.Set;

public class SocketMultiplexingSingleThread {

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
                while (selector.select(5000) > 0) {
                    // 所有有状态的fd
                    Set<SelectionKey> keys = selector.selectedKeys();
                    for (Iterator<SelectionKey> it = keys.iterator(); it.hasNext(); ) {
                        SelectionKey key = it.next();
                        // 这里一定要删除, 不然会重复循环 !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                        // 相当于在linux fd红黑树中删除
                        it.remove();
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
                    while (buf.hasRemaining()) {
                        clientChannel.write(buf);
                    }
                    // 清除buf数据
                    buf.clear();
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

    public static void main(String[] args) {
        new SocketMultiplexingSingleThread().run();
    }
}
```

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