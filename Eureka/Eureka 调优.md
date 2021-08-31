# Eureka 调优

1. eureka服务心跳包验证失败后, eureka默认开启自我保护, 在没有触发自我保护阈值之前, eureka不会将服务移除列表
    - 生产环境中, 可能因为网络延时, 各种情况, 导致心跳验证失败.  
        心跳验证失败并不带表, 服务下线了  
        触发自我保护阈值后eureka将会直接删除服务

2. 服务进来后, 默认使用readOnlyResponseCache, readOnly和readWriteCache`30秒`同步一次.  
    服务注册上来后直接存入readWriteCahce, 因此让eureka直接去readWriteCache里找会更快

    - ```java
        // com.netflix.eureka.registry.ResponseCacheImpl;
        @VisibleForTesting
        ResponseCacheImpl.Value getValue(Key key, boolean useReadOnlyCache) {
            ResponseCacheImpl.Value payload = null;
        
            try {
                // 默认使用readOnlyCache
                if (useReadOnlyCache) {
                    // 先去readOnlyCache里找, 没有再去readWriteCache里找
                    ResponseCacheImpl.Value currentPayload = (ResponseCacheImpl.Value)this.readOnlyCacheMap.get(key);
                    if (currentPayload != null) {
                        payload = currentPayload;
                    } else {
                        // 没找到就去readWriteCacheMap里找
                        payload = (ResponseCacheImpl.Value)this.readWriteCacheMap.get(key);
                        this.readOnlyCacheMap.put(key, payload);
                    }
                } else {
                    payload = (ResponseCacheImpl.Value)this.readWriteCacheMap.get(key);
                }
            } catch (Throwable var5) {
                logger.error("Cannot get value for key : {}", key, var5);
            }
        
            return payload;
        }
        ```

    - ```java
        ResponseCacheImpl(EurekaServerConfig serverConfig, ServerCodecs serverCodecs, AbstractInstanceRegistry registry) {
            // ...... 
                if (this.shouldUseReadOnlyResponseCache) {
                    // 配置使用readOnlyResponseCache, 就执行一个定时任务, 默认30秒, 30秒会同步一次readOnlyResponseCache与readWriteCache
                    this.timer.schedule(this.getCacheUpdateTask(), new Date(System.currentTimeMillis() / responseCacheUpdateIntervalMs * responseCacheUpdateIntervalMs + responseCacheUpdateIntervalMs), responseCacheUpdateIntervalMs);
                }
            // ......
            }
        ```
    
3. recentlyChangedQueue 保留3分钟的注册信息, 不需要每次都拉取全量数据

4. yml

    - ```yml
        eureka:
          client:
            register-with-eureka: true
            fetch-registry: true
            service-url:
              defaultZone: http://localhost:7900/eureka
        #       eureka集群
        #       defaultZone: http://euk.com:7900/eureka,http://euk1.com:7901/eureka,http://euk2.com:7902/eureka
          server:
            # 关闭自我保护, 配置合适的阈值, 设置检测服务是否失效的时间间隔, 做到快速下线
            enable-self-preservation: false # 关闭自我保护
            renewal-percent-threshold: 0.85 # 续约次数(自我保护)阈值
            eviction-interval-timer-in-ms: 1000 # 检查服务失效的间隔, 默认60秒才回去检测服务是否失效
        
            # 三级缓存优化, 直接去readWriteCache找服务, 降低高可用, 加快找到服务的速度
            # readOnlyResponseCache和readWriteCache不是强一致性的, 两个数据不同步
            # 不是用户readOnlyResponse直接去readWriteCache里去找会快一点, readWriteCache里的缓存是最准确的
            use-read-only-response-cache: false
        
            # readOnlyResponseCache和readWriteCache的同步时间间隔, 默认30秒同步一次服务, 设置1秒可以更快的查询出服务
            response-cache-update-interval-ms: 1000
        ```

    - 
