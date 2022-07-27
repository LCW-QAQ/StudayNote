# Netty

Java对IO多路复用做了封装，使其在任何平台上使用统一接口。

默认情况下，JVM会选择当前平台最优的方案，在支持epoll的linux系统中，默认使用epoll。

## NioDemo

### 单线程单selector

```java
public class NioSingleThreadDemo {
    public static void main(String[] args) {
        final SingThreadServer server = new SingThreadServer();
        server.serveForever();
    }

    public static class SingThreadServer {
        private ServerSocketChannel serverChannel;

        private Selector selector;

        public SingThreadServer() {
            init();
        }

        public void init() {
            try {
                // server socket
                this.serverChannel = ServerSocketChannel.open();
                // 设置非阻塞
                this.serverChannel.configureBlocking(false);
                this.serverChannel.bind(new InetSocketAddress("0.0.0.0", 8000));
                // 初始化IO多路复用器
                this.selector = Selector.open();
                // 注册Accept事件
                serverChannel.register(selector, SelectionKey.OP_ACCEPT);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        public void serveForever() {
            while (true) {
                try {
                    while (selector.select(10) > 0) {
                        // 对应select函数, 由内核遍历后返回有IO事件的fd
                        final Set<SelectionKey> selectionKeys = selector.selectedKeys();
                        final Iterator<SelectionKey> it = selectionKeys.iterator();
                        while (it.hasNext()) {
                            final SelectionKey key = it.next();
                            // 一定要删除，Java提供的Api需要手动删除，不然会重复处理
                            it.remove();
                            // 判断具体的事件类型
                            if (key.isAcceptable()) {
                                handleAccept(key);
                            } else if (key.isReadable()) {
                                handleRead(key);
                            } else if (key.isWritable()) {
                                handleWrite(key);
                            }
                        }
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        /**
         * 接受连接
         */
        public void handleAccept(SelectionKey key) {
            final ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
            try {
                final SocketChannel clientChannel = serverChannel.accept();
                // 非阻塞IO
                clientChannel.configureBlocking(false);
                System.out.printf("%s connect%n", clientChannel.getRemoteAddress());
                final ByteBuffer buf = ByteBuffer.allocateDirect(4096);
                clientChannel.register(key.selector(), SelectionKey.OP_READ, buf);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        /**
         * 处理读取事件
         */
        public void handleRead(SelectionKey key) {
            final SocketChannel clientChannel = (SocketChannel) key.channel();
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            try {
                // 读取前清空buffer
                buf.clear();
                while (true) {
                    final int readN = clientChannel.read(buf);
                    if (readN > 0) {
                        clientChannel.read(buf);
                    } else if (readN == 0) {
                        break;
                    } else {
                        clientChannel.close();
                        key.cancel();
                        break;
                    }
                }
                clientChannel.register(selector, SelectionKey.OP_WRITE, buf);
            } catch (IOException e) {
                e.printStackTrace();
                key.cancel();
            }
        }

        /**
         * 处理写入事件
         */
        public void handleWrite(SelectionKey key) {
            final SocketChannel clientChannel = (SocketChannel) key.channel();
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            buf.flip();
            final byte[] bytes = new byte[buf.limit()];
            // Buffer#slice方法会拷贝一份Buffer, 在拷贝的Buffer上操作不会影响原Buffer
            buf.slice().get(bytes);
            String msg = new String(bytes, StandardCharsets.UTF_8);
            System.out.printf("%s", msg);
            try {
                while (buf.hasRemaining()) {
                    clientChannel.write(buf);
                }
                // 写入事件在send-queue不为空时会一直触发
                // 重新注册读取事件, 防止重复触发写入事件(这样就不需要key.cancel()了) 
                clientChannel.register(selector, SelectionKey.OP_READ, buf);
                // key.cancel();
            } catch (IOException e) {
                e.printStackTrace();
                key.cancel();
            }

        }
    }
}
```

### 多线程单selector

```java
public class NioMultiThreadDemo {
    public static void main(String[] args) {
        final MultiThreadServer server = new MultiThreadServer();
        server.serveForever();
    }

    public static class MultiThreadServer {
        private ServerSocketChannel serverChannel;

        private Selector selector;

        private ExecutorService executor;

        public MultiThreadServer() {
            init();
        }

        public void init() {
            try {
                // server socket
                this.serverChannel = ServerSocketChannel.open();
                // 设置非阻塞
                this.serverChannel.configureBlocking(false);
                this.serverChannel.bind(new InetSocketAddress("0.0.0.0", 8000));
                // 初始化多路复用器
                this.selector = Selector.open();
                // 注册Accept事件
                serverChannel.register(selector, SelectionKey.OP_ACCEPT);
                // 创建用于读写的线程池
                this.executor = Executors.newWorkStealingPool();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        public void serveForever() {
            while (true) {
                try {
                    // !!! 这里一定要设置超时时间, 详见javadoc
                    // !!! selector#select方法会永久阻塞, 直到线程被中断, 超时或有其他线程调用了selector的wakeup方法
                    // !!! 所以这里必须给定超时时间, 不然就需要在其他线程调用selector#wakeup
                    while (selector.select(10) > 0) {
                        final Set<SelectionKey> selectionKeys = selector.selectedKeys();
                        final Iterator<SelectionKey> it = selectionKeys.iterator();
                        while (it.hasNext()) {
                            final SelectionKey key = it.next();
                            it.remove();
                            if (key.isAcceptable()) {
                                handleAccept(key);
                            } else if (key.isReadable()) {
                                key.cancel();
                                executor.submit(() -> {
                                    handleRead(key);
                                });
                            } else if (key.isWritable()) {
                                key.cancel();
                                executor.submit(() -> {
                                    handleWrite(key);
                                });
                            }
                        }
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        /**
         * 接受连接
         */
        public void handleAccept(SelectionKey key) {
            final ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
            try {
                final SocketChannel clientChannel = serverChannel.accept();
                // 非阻塞IO
                clientChannel.configureBlocking(false);
                System.out.printf("%s connect%n", clientChannel.getRemoteAddress());
                final ByteBuffer buf = ByteBuffer.allocateDirect(4096);
                clientChannel.register(key.selector(), SelectionKey.OP_READ, buf);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        /**
         * 处理读取事件
         */
        public void handleRead(SelectionKey key) {
            final SocketChannel clientChannel = (SocketChannel) key.channel();
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            try {
                // 读取前清空buffer
                buf.clear();
                while (true) {
                    final int readN = clientChannel.read(buf);
                    if (readN > 0) {
                        // 只有有数据可以读取的时候, 才需要回显到客户端
                        clientChannel.register(selector, SelectionKey.OP_WRITE, buf);
                    } else if (readN == 0) {
                        break;
                    } else {
                        // 客户端连接断开, 关闭连接即可
                        clientChannel.close();
                        key.cancel();
                        break;
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        /**
         * 处理写入事件
         */
        public void handleWrite(SelectionKey key) {
            final SocketChannel clientChannel = (SocketChannel) key.channel();
            final ByteBuffer buf = (ByteBuffer) key.attachment();

            // 这里只是为了在服务端打印一下
            buf.flip();
            final byte[] bytes = new byte[buf.limit()];
            buf.slice().get(bytes);
            String msg = new String(bytes, StandardCharsets.UTF_8);
            System.out.printf("%s", msg);

            try {
                while (buf.hasRemaining()) {
                    clientChannel.write(buf);
                }
                // 写入完毕, 清空buffer
                buf.clear();
                // 继续注册读取事件
                clientChannel.register(selector, SelectionKey.OP_READ, buf);
            } catch (IOException e) {
                e.printStackTrace();
            }

        }
    }
}
```

### 多线程多selector

#### without woker

> 混杂模式, 多个线程, 多个selector
> 每个selector都会处理OP_ACCEPT/OP_READ/OP_WRITE的事件注册与读写操作

```java
/**
 * 多线线程多selector模型
 * 创建多个线程, 每个线程都有一个独立的selector, 多个线程只会同步处理自己selector上的IO事件, 即利用了多核性能, 又尽可能避免了竞态条件
 */
public class NioMultiSelectorThreadDemo {
    public static void main(String[] args) {
        // 混杂模式, 多个线程, 多个selector
        // 每个selector都会处理OP_ACCEPT/OP_READ/OP_WRITE的事件注册与读写操作
        final SelectorThreadGroup stg = new SelectorThreadGroup(Runtime.getRuntime().availableProcessors());
        stg.bind("0.0.0.0", 8000);
        stg.serveForever();
    }
}
```

```java
/**
 * 多路复用器线程组
 */
public class SelectorThreadGroup {
    private final SelectorThread[] selectorThreads;

    // 轮询算法计数器
    private final AtomicInteger counter = new AtomicInteger(0);

    // 默认ByteBuffer大小
    protected final int DEFAULT_BYTE_BUFFER_SIZE = 8192;

    public SelectorThreadGroup(int parallelize) {
        this(parallelize, false);
    }

    public SelectorThreadGroup(int parallelize, boolean daemon) {
        this.selectorThreads = new SelectorThread[parallelize];
        for (int i = 0; i < parallelize; i++) {
            try {
                this.selectorThreads[i] = new SelectorThread(Selector.open(), this);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    public void serveForever() {
        for (SelectorThread st : this.selectorThreads) {
            new Thread(st).start();
        }
    }

    /**
     * 绑定地址与端口
     *
     * @param addr 绑定地址
     * @param port 端口
     */
    public void bind(String addr, int port) {
        try {
            final SelectorThread st = nextSelectorThread();
            final Selector sel = st.getSelector();
            final ServerSocketChannel channel = ServerSocketChannel.open();
            channel.configureBlocking(false);
            channel.bind(new InetSocketAddress(addr, port));

            // !!! 多线程环境下调用Channel#register可能会导致死锁
            // 这里利用阻塞队列在多线程中通信, 将要注册的管道发送给对应的SelectorThread
            st.localQueue.offer(channel);
            sel.wakeup();

            // 向多路复用器注册accept事件
            // channel.register(sel, SelectionKey.OP_ACCEPT);
            // 唤醒selector thread
            // sel.wakeup();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 获取下一个多路复用器线程
     * 轮询算法
     */
    protected SelectorThread nextSelectorThread() {
        return this.selectorThreads[counter.getAndIncrement() % this.selectorThreads.length];
    }
}
```

```java
/**
 * 多路复用器线程
 */
public class SelectorThread extends ThreadLocal<LinkedBlockingDeque<Channel>> implements Runnable {
    private final Selector selector;

    private final SelectorThreadGroup stg;

    protected final LinkedBlockingDeque<Channel> localQueue = get();

    public SelectorThread(Selector selector, SelectorThreadGroup stg) {
        this.selector = selector;
        this.stg = stg;
    }

    @Override
    protected LinkedBlockingDeque<Channel> initialValue() {
        return new LinkedBlockingDeque<>();
    }

    protected Selector getSelector() {
        return selector;
    }

    @Override
    public void run() {
        while (true) {
            try {
                // 永久阻塞, 等待wakeup
                System.out.printf("before select, thread name: %s%n", Thread.currentThread().getName());
                final int num = selector.select();
                System.out.printf("after select, thread name: %s%n", Thread.currentThread().getName());
                // 有fd才需要处理
                if (num > 0) {
                    final Set<SelectionKey> keys = selector.selectedKeys();
                    final Iterator<SelectionKey> it = keys.iterator();
                    while (it.hasNext()) {
                        final SelectionKey key = it.next();
                        it.remove();
                        if (key.isAcceptable()) {
                            handleAccept(key);
                        } else if (key.isReadable()) {
                            handleRead(key);
                        } else if (key.isWritable()) {
                            handleWrite(key);
                        }
                    }
                }

                // 阻塞任务, 同步注册accept与rw等IO事件
                if (!localQueue.isEmpty()) {
                    final Channel channel = localQueue.poll();
                    if (channel instanceof ServerSocketChannel) {
                        final ServerSocketChannel serverCh = (ServerSocketChannel) channel;
                        serverCh.register(selector, SelectionKey.OP_ACCEPT);
                    } else if (channel instanceof SocketChannel) {
                        final SocketChannel sockCh = (SocketChannel) channel;
                        final ByteBuffer buf = ByteBuffer.allocateDirect(this.stg.DEFAULT_BYTE_BUFFER_SIZE);
                        sockCh.register(selector, SelectionKey.OP_READ, buf);
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void handleWrite(SelectionKey key) {
        final SocketChannel sockChannel = (SocketChannel) key.channel();
        try {
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            // 写入时, 需要读取, flip转换成读模式
            buf.flip();
            while (buf.hasRemaining()) {
                // 测试http服务器
                String respStr = "HTTP/1.1 200 OK\nServer: MultiSelectorThreadServer\nContent-Type: text/html;charset=UTF-8\n\nok\n";
                buf.clear();
                buf.put(respStr.getBytes(StandardCharsets.UTF_8));
                buf.flip();

                sockChannel.write(buf);
            }

            // 默认只要send-queue不为空, 就会一直触发写入事件, 提示用户可以写入数据
            // 但是我们的逻辑中, 写入是有自己控制的, 所以每次写入完成后, 都删除对应事件, 下次一需要写入时, 再去注册事件
            // key.cancel();

            // 也可以通过再次向多路复用器注册OP_READ事件来防止重复写入
            sockChannel.register(key.selector(), SelectionKey.OP_READ, buf);
        } catch (IOException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }

    private void handleAccept(SelectionKey key) {
        final ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
        final SelectorThread st = this.stg.nextSelectorThread();
        final Selector sel = st.getSelector();
        try {
            // 接受客户端连接channel
            final SocketChannel sockChannel = serverChannel.accept();
            // 设置非阻塞才能使用多路复用器
            sockChannel.configureBlocking(false);

            System.out.printf("%s connect%n", sockChannel.getRemoteAddress());

            // !!! 所有accept, rw等注册关注事件的操作都使用阻塞队列传递消息
            // 由同一个线程注册自己的IO事件, 防止Channel#register方法死锁
            st.localQueue.put(sockChannel);
            sel.wakeup();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }

    private void handleRead(SelectionKey key) {
        final SocketChannel sockChannel = (SocketChannel) key.channel();

        try {
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            // 读取前清空buffer
            buf.clear();
            while (true) {
                final int readN = sockChannel.read(buf);
                if (readN > 0) {
                    buf.flip();
                    byte[] bytes = new byte[buf.limit()];
                    buf.slice().get(bytes);
                    String msg = new String(bytes, StandardCharsets.UTF_8);
                    System.out.printf("thread name: %s, server receive msg: %s%n",
                            Thread.currentThread().getName(), msg);
                    buf.compact();

                    sockChannel.register(selector, SelectionKey.OP_WRITE, buf);
                } else if (readN == 0) { // 没有数据可读取, 停止循环, 注意这并不代表连接关闭了, tcp是长连接, 只是客户端没有发数据
                    break;
                } else {
                    // readN < 0表示客户端连接关闭
                    // 取消key, 不然还会通知并报错
                    key.cancel();
                    sockChannel.close();
                    break;
                }
            }

            sockChannel.register(selector, SelectionKey.OP_WRITE, buf);
        } catch (IOException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }
}
```

#### with worker

> 模仿netty，BossGroup负责Accpet，WorkerGroup负责RW

```java
/**
 * 多线线程多selector模型
 * 创建多个线程, 每个线程都有一个独立的selector, 多个线程只会同步处理自己selector上的IO事件, 即利用了多核性能, 又尽可能避免了竞态条件
 */
public class NioMultiSelectorThreadDemo {
    public static void main(String[] args) {
        // 混杂模式, 多个线程, 多个selector
        // 每个selector都会处理OP_ACCEPT/OP_READ/OP_WRITE的事件注册与读写操作
        // 用于accept连接
        final SelectorThreadGroup boosGroup = new SelectorThreadGroup(1);
        // 用于rw
        final SelectorThreadGroup workerGroup = new SelectorThreadGroup(Runtime.getRuntime().availableProcessors());

        boosGroup.setWorkerGroup(workerGroup);

        boosGroup.bind("0.0.0.0", 8000);
        boosGroup.serveForever();
    }
}
```

```java
/**
 * 多路复用器线程组
 */
public class SelectorThreadGroup {
    private final SelectorThread[] selectorThreads;

    private SelectorThreadGroup workerGroup;

    // 轮询算法计数器
    private final AtomicInteger counter = new AtomicInteger(0);

    // 默认ByteBuffer大小
    protected final int DEFAULT_BYTE_BUFFER_SIZE = 8192;

    public SelectorThreadGroup(int parallelize) {
        this(parallelize, false);
    }

    public SelectorThreadGroup(int parallelize, boolean daemon) {
        this.selectorThreads = new SelectorThread[parallelize];
        for (int i = 0; i < parallelize; i++) {
            try {
                this.selectorThreads[i] = new SelectorThread(Selector.open(), this);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    /**
     * 设置worker负责处理rw
     */
    public void setWorkerGroup(SelectorThreadGroup workerGroup) {
        this.workerGroup = workerGroup;
    }

    public void serveForever() {
        for (SelectorThread st : this.selectorThreads) {
            new Thread(st).start();
        }
    }

    /**
     * 绑定地址与端口
     *
     * @param addr 绑定地址
     * @param port 端口
     */
    public void bind(String addr, int port) {
        try {
            final SelectorThread st = nextSelectorBoosThread();
            final Selector sel = st.getSelector();
            final ServerSocketChannel channel = ServerSocketChannel.open();
            channel.configureBlocking(false);
            channel.bind(new InetSocketAddress(addr, port));


            // !!! 多线程环境下调用Channel#register可能会导致死锁
            // 这里利用阻塞队列在多线程中通信, 将要注册的管道发送给对应的SelectorThread
            st.localQueue.offer(channel);
            sel.wakeup();

            // 向多路复用器注册accept事件
            // channel.register(sel, SelectionKey.OP_ACCEPT);
            // 唤醒selector thread
            // sel.wakeup();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /**
     * 获取下一个多路复用器线程
     */
    protected SelectorThread nextSelectorBoosThread() {
        return this.selectorThreads[counter.getAndIncrement() % this.selectorThreads.length];
    }

    /**
     * 下一个Worker线程
     */
    protected SelectorThread nextSelectorWorkerThread() {
        int mod = this.selectorThreads.length - 1;
        // mod == 0时, by zero error, 需要特殊处理一下
        return mod == 0 ?
                this.selectorThreads[0] :
                this.selectorThreads[counter.getAndIncrement() % (mod) + 1];
    }
}
```

```java
/**
 * 多路复用器线程
 */
public class SelectorThread extends ThreadLocal<LinkedBlockingDeque<Channel>> implements Runnable {
    private final Selector selector;

    private final SelectorThreadGroup selectorGroup;

    protected final LinkedBlockingDeque<Channel> localQueue = get();

    public SelectorThread(Selector selector, SelectorThreadGroup stg) {
        this.selector = selector;
        this.selectorGroup = stg;
    }

    @Override
    protected LinkedBlockingDeque<Channel> initialValue() {
        return new LinkedBlockingDeque<>();
    }

    protected Selector getSelector() {
        return selector;
    }

    @Override
    public void run() {
        while (true) {
            try {
                // 永久阻塞, 等待wakeup
                System.out.printf("before select, thread name: %s%n", Thread.currentThread().getName());
                final int num = selector.select();
                System.out.printf("after select, thread name: %s%n", Thread.currentThread().getName());
                // 有fd才需要处理
                if (num > 0) {
                    final Set<SelectionKey> keys = selector.selectedKeys();
                    final Iterator<SelectionKey> it = keys.iterator();
                    while (it.hasNext()) {
                        final SelectionKey key = it.next();
                        it.remove();
                        if (key.isAcceptable()) {
                            handleAccept(key);
                        } else if (key.isReadable()) {
                            handleRead(key);
                        } else if (key.isWritable()) {
                            handleWrite(key);
                        }
                    }
                }

                // 阻塞任务, 同步注册accept与rw等IO事件
                if (!localQueue.isEmpty()) {
                    final Channel channel = localQueue.poll();
                    if (channel instanceof ServerSocketChannel) {
                        final ServerSocketChannel serverCh = (ServerSocketChannel) channel;
                        serverCh.register(selector, SelectionKey.OP_ACCEPT);
                        System.out.println(Thread.currentThread().getName() + " register listen");
                    } else if (channel instanceof SocketChannel) {
                        final SocketChannel sockCh = (SocketChannel) channel;
                        final ByteBuffer buf = ByteBuffer.allocateDirect(this.selectorGroup.DEFAULT_BYTE_BUFFER_SIZE);
                        sockCh.register(selector, SelectionKey.OP_READ, buf);
                        System.out.println(Thread.currentThread().getName()
                                + " register listen " + sockCh.getRemoteAddress());
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void handleWrite(SelectionKey key) {
        final SocketChannel sockChannel = (SocketChannel) key.channel();
        try {
            final ByteBuffer buf = (ByteBuffer) key.attachment();

            // 写入时, 需要读取, flip转换成读模式
            buf.flip();
            while (buf.hasRemaining()) {
                // 测试http服务器
                String respStr = "HTTP/1.1 200 OK\nServer: MultiSelectorThreadServer\nContent-Type: text/html;charset=UTF-8\n\nok\n";
                buf.clear();
                buf.put(respStr.getBytes(StandardCharsets.UTF_8));
                buf.flip();

                sockChannel.write(buf);
            }

            // 默认只要send-queue不为空, 就会一直触发写入事件, 提示用户可以写入数据
            // 但是我们的逻辑中, 写入是有自己控制的, 所以每次写入完成后, 都删除对应事件, 下次一需要写入时, 再去注册事件
            // key.cancel();

            // 也可以通过再次向多路复用器注册OP_READ事件来防止重复写入
            sockChannel.register(key.selector(), SelectionKey.OP_READ, buf);
        } catch (IOException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }

    private void handleAccept(SelectionKey key) {
        final ServerSocketChannel serverChannel = (ServerSocketChannel) key.channel();
        final SelectorThread st = this.selectorGroup.nextSelectorWorkerThread();
        final Selector sel = st.getSelector();
        try {
            // 接受客户端连接channel
            final SocketChannel sockChannel = serverChannel.accept();
            // 设置非阻塞才能使用多路复用器
            sockChannel.configureBlocking(false);

            System.out.printf("%s connect%n", sockChannel.getRemoteAddress());

            // !!! 所有accept, rw等注册关注事件的操作都使用阻塞队列传递消息
            // 由同一个线程注册自己的IO事件, 防止Channel#register方法死锁
            st.localQueue.put(sockChannel);
            sel.wakeup();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }

    private void handleRead(SelectionKey key) {
        final SocketChannel sockChannel = (SocketChannel) key.channel();

        try {
            final ByteBuffer buf = (ByteBuffer) key.attachment();
            // 读取前清空buffer
            buf.clear();
            while (true) {
                final int readN = sockChannel.read(buf);
                if (readN > 0) {
                    buf.flip();
                    byte[] bytes = new byte[buf.limit()];
                    buf.slice().get(bytes);
                    String msg = new String(bytes, StandardCharsets.UTF_8);
                    System.out.printf("thread name: %s, server receive msg: %s%n",
                            Thread.currentThread().getName(), msg);
                    buf.compact();

                    sockChannel.register(selector, SelectionKey.OP_WRITE, buf);
                } else if (readN == 0) { // 没有数据可读取, 停止循环, 注意这并不代表连接关闭了, tcp是长连接, 只是客户端没有发数据
                    break;
                } else {
                    // readN < 0表示客户端连接关闭
                    // 取消key, 不然还会通知并报错
                    key.cancel();
                    sockChannel.close();
                    break;
                }
            }

            sockChannel.register(selector, SelectionKey.OP_WRITE, buf);
        } catch (IOException e) {
            e.printStackTrace();
            // 出现错误直接移除对应fd
            key.cancel();
        }
    }
}
```

## NettyClient

```java
public class SimpleClientDemo {

    public class SimpleStringInHandler extends ChannelInboundHandlerAdapter {

        @Override
        public void channelActive(ChannelHandlerContext ctx) throws Exception {
            System.out.printf("client active, %s%n", ctx.channel());
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
            final ByteBuf buf = (ByteBuf) msg;
            // get系列方法不会移动read指针
            final CharSequence str = buf.getCharSequence(0, buf.readableBytes(), CharsetUtil.UTF_8);
            System.out.println(str);
            ctx.writeAndFlush(buf);
        }
    }

    @Test
    public void clientMode() throws InterruptedException {
        final NioEventLoopGroup loopGroup = new NioEventLoopGroup();
        final NioSocketChannel sockCh = new NioSocketChannel();
        loopGroup.register(sockCh);

        // 所有具体的IO处理(如编解码, 自定义处理等)都放在Pipeline中处理
        final ChannelPipeline pipeline = sockCh.pipeline();
        pipeline.addLast(new SimpleStringInHandler());

        final ChannelFuture connSync = sockCh.connect(new InetSocketAddress("localhost", 8000)).sync();
        final ByteBuf buf = Unpooled.copiedBuffer("hello server\n", CharsetUtil.UTF_8);
        sockCh.writeAndFlush(buf).sync();

        // 让服务器阻塞住
        connSync.channel().closeFuture().sync();
        System.out.println("client over");
    }
}
```

## NettyServer

```java
public class SimpleServerDemo {

    /**
     * 用来处理accept, 并动态添加用户指定的handler
     */
    class SimpleAcceptInHandler extends ChannelInboundHandlerAdapter {

        private final EventLoopGroup loopGroup;

        private final ChannelHandler handler;

        SimpleAcceptInHandler(EventLoopGroup loopGroup, ChannelHandler handler) {
            this.loopGroup = loopGroup;
            this.handler = handler;
        }

        @Override
        public void channelActive(ChannelHandlerContext ctx) throws Exception {
            System.out.printf("SimpleAcceptInHandler channel[%s] registered%n", ctx.channel());
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
            // netty 已经帮我们accept了, 可以直接使用accept返回的SocketChannel
            final SocketChannel sockCh = (SocketChannel) msg;
            final ChannelPipeline pipeline = sockCh.pipeline();
            // 添加用户自定义的Handler
            pipeline.addLast(handler);
            // 将连接注册到事件循环中
            loopGroup.register(sockCh);
        }
    }

    /**
     * 读取客户端发送的字符串数据, 并回显客户端
     */
    // @ChannelHandler.Sharable
    class SimpleStringInHandler extends ChannelInboundHandlerAdapter {

        @Override
        public void channelRegistered(ChannelHandlerContext ctx) throws Exception {
            System.out.printf("SimpleStringInHandler channel[%s] registered%n", ctx.channel());
        }

        @Override
        public void channelActive(ChannelHandlerContext ctx) throws Exception {
            System.out.printf("SimpleStringInHandler channel[%s] active %n", ctx.channel());
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
            final ByteBuf buf = (ByteBuf) msg;
            // get系列方法不会移动read指针
            final CharSequence str = buf.getCharSequence(0, buf.readableBytes(), CharsetUtil.UTF_8);
            System.out.println(str);
            ctx.writeAndFlush(buf);
        }
    }

    @ChannelHandler.Sharable
    abstract static class MyChannelInitializer extends ChannelInboundHandlerAdapter {
        @Override
        public void channelRegistered(ChannelHandlerContext ctx) throws Exception {
            initialize(ctx);
        }

        public abstract void initialize(ChannelHandlerContext ctx);
    }

    @Test
    public void serverMode() throws InterruptedException {
        final NioEventLoopGroup loopGroup = new NioEventLoopGroup();

        final NioServerSocketChannel serverCh = new NioServerSocketChannel();

        final ChannelPipeline pipeline = serverCh.pipeline();
        // 多个客户端连复用同一个handler时, 如果没有标注@ChannelHandler.Sharable注解, 无法共享handler


        // 模仿netty, 设计一个通用的ChannelInitializer, 加上@ChannelHandler.Sharable在多个客户端中共享
        // 详见ChannelInitializer源码
        pipeline.addLast(new SimpleAcceptInHandler(loopGroup, new MyChannelInitializer() {
            @Override
            public void initialize(ChannelHandlerContext ctx) {
                final ChannelPipeline pip = ctx.pipeline();
                pip.addLast(new SimpleStringInHandler());
            }
        }));

        loopGroup.register(serverCh).sync();
        final ChannelFuture connSync = serverCh.bind(new InetSocketAddress("0.0.0.0", 8000));

        // 同步阻塞server
        connSync.sync().channel().closeFuture().sync();
    }

    @Test
    public void nettyServerMode() throws InterruptedException {
        // 使用netty提供里的api创建server
        final NioEventLoopGroup loopGroup = new NioEventLoopGroup(1);
        final ChannelFuture serverSync = new ServerBootstrap()
                .group(loopGroup, loopGroup)
                .channel(NioServerSocketChannel.class)
                .childHandler(new ChannelInitializer<NioSocketChannel>() {
                    @Override
                    protected void initChannel(NioSocketChannel ch) throws Exception {
                        final ChannelPipeline pipeline = ch.pipeline();
                        pipeline.addLast(new SimpleStringInHandler());
                    }
                }).bind("0.0.0.0", 8000);

        serverSync.sync().channel().closeFuture().sync();
    }
}
```