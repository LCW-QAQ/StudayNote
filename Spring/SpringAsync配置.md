# SpringAsync配置

```java
@Configuration
public class OrderAsynConfig implements AsyncConfigurer {
 
    private static Logger logger = LoggerFactory.getLogger(OrderAsynConfig.class);
 
    private static final String THREAD_POOL_NAME = "order-task-pool";
 
    @Bean
    @Override
    public Executor getAsyncExecutor() {
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        //线程池的名字
        taskExecutor.setThreadGroupName(THREAD_POOL_NAME);
        //设置创建线程的工程 主要是给线程起名字
        taskExecutor.setThreadFactory(new OrderThreadFactory());
        //核心线程的数量 默认1
        taskExecutor.setCorePoolSize(10);
        //最大线程的数量 默认int最大值
        taskExecutor.setMaxPoolSize(20);
        //队列的长度   默认int最大值
        taskExecutor.setQueueCapacity(1000);
        //线程空闲时间 处主线程以外其他的线程超过该时间就会被回收  默认60s
        taskExecutor.setKeepAliveSeconds(60);
        //核心线程 是否超时 默认false
        taskExecutor.setAllowCoreThreadTimeOut(false);
        //true 线程池关闭之前执行完所有队列里面的任务 false则相反  默认false
        taskExecutor.setWaitForTasksToCompleteOnShutdown(true);
        //拒绝策略  当线程池队列满了继续添加的任务由主线程执行
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        return taskExecutor;
    }
 
    /**
     * 打印线程异常时的报错 可以防止子线程异常被吞掉。
     *
     * @return
     */
    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return (Throwable ex, Method method, Object... params) -> {
            String errorBuilder = "Async execution error on method:" + method.toString() + " with parameters:"
                    + Arrays.toString(params);
            logger.error(errorBuilder);
        };
    }
 
    /**
     * 线程的工厂类 打印线程的名字方便问题的定位 参照Executors。DefaultThreadFactory编写
     */
    static class OrderThreadFactory implements ThreadFactory {
        private final AtomicInteger poolNumber = new AtomicInteger(1);
 
        private final ThreadGroup threadGroup;
 
        private final AtomicInteger threadNumber = new AtomicInteger(1);
 
        public final String namePrefix;
 
        public OrderThreadFactory() {
            SecurityManager s = System.getSecurityManager();
            threadGroup = (s != null) ? s.getThreadGroup() :
                    Thread.currentThread().getThreadGroup();
            namePrefix = THREAD_POOL_NAME + "-";
        }
 
        @Override
        public Thread newThread(Runnable r) {
            Thread t = new Thread(threadGroup, r,
                    namePrefix + threadNumber.getAndIncrement(),
                    0);
            if (t.isDaemon()) {
                t.setDaemon(false);
            }
            if (t.getPriority() != Thread.NORM_PRIORITY) {
                t.setPriority(Thread.NORM_PRIORITY);
            }
            return t;
        }
    }
}
```

