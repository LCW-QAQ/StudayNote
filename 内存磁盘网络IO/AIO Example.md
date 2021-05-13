# AIO Example

```java
	@Test
    public void test01() throws Exception {
        Path path = Paths.get("D:\\study\\java\\springboot\\springboot_mybatis\\src\\main\\resources\\mapper\\EmpMapper.xml");
        AsynchronousFileChannel channel = AsynchronousFileChannel.open(path);
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        Future<Integer> future = channel.read(buffer, 0);

        // 阻塞等待IO读取完毕, 获得结果
        Integer readNumber = future.get();

        buffer.flip();
        CharBuffer charBuffer = CharBuffer.allocate(1024);
        CharsetDecoder decoder = Charset.defaultCharset().newDecoder();
        decoder.decode(buffer, charBuffer, false);
        charBuffer.flip();
        String data = new String(charBuffer.array(), 0, charBuffer.limit());
        System.out.println("read number:" + readNumber);
        System.out.println(data);
    }

    @Test
    public void test02() throws Exception {
        Path path = Paths.get("D:\\study\\java\\springboot\\springboot_mybatis\\src\\main\\resources\\mapper\\EmpMapper.xml");
        AsynchronousFileChannel channel = AsynchronousFileChannel.open(path);
        ByteBuffer buffer = ByteBuffer.allocate(1024);
        // 使用回调函数的方式处理
        channel.read(buffer, 0, buffer, new CompletionHandler<Integer, ByteBuffer>() {
            @Override
            public void completed(Integer result, ByteBuffer attachment) {
                System.out.println(Thread.currentThread().getName() + " read success!" + ", result: " + result);
                attachment.flip();
                System.out.println(new String(attachment.array(), 0, attachment.limit()));
            }

            @Override
            public void failed(Throwable exc, ByteBuffer attachment) {
                System.out.println("read error");
            }
        });
    }

    @Test
    public void test03() throws Exception {
        AsynchronousSocketChannel channel = AsynchronousSocketChannel.open();
        channel.connect(new InetSocketAddress("127.0.0.1", 8888)).get();
        ByteBuffer buffer = ByteBuffer.wrap("a".getBytes());
        Future<Integer> result = channel.write(buffer);
    }

    @Test
    public void test04() throws Exception {
        final AsynchronousServerSocketChannel channel = AsynchronousServerSocketChannel
                .open()
                .bind(new InetSocketAddress("0.0.0.0", 8888));
        channel.accept(null, new CompletionHandler<AsynchronousSocketChannel, Void>() {
            @Override
            public void completed(final AsynchronousSocketChannel client, Void attachment) {
                channel.accept(null, this);

                ByteBuffer buffer = ByteBuffer.allocate(1024);
                client.read(buffer, buffer, new CompletionHandler<Integer, ByteBuffer>() {
                    @Override
                    public void completed(Integer result_num, ByteBuffer attachment) {
                        attachment.flip();
                        CharBuffer charBuffer = CharBuffer.allocate(1024);
                        CharsetDecoder decoder = Charset.defaultCharset().newDecoder();
                        decoder.decode(attachment, charBuffer, false);
                        charBuffer.flip();
                        String data = new String(charBuffer.array(), 0, charBuffer.limit());
                        System.out.println("read data:" + data);
                        try {
                            client.close();
                        } catch (Exception e) {
                            e.printStackTrace();
                        }
                    }

                    @Override
                    public void failed(Throwable exc, ByteBuffer attachment) {
                        System.out.println("read error");
                    }
                });
            }

            @Override
            public void failed(Throwable exc, Void attachment) {
                System.out.println("accept error");
            }
        });
        while (true) ;
    }
```