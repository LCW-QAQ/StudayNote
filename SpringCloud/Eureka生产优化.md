# Eureka生产优化

## 自我保护

自我保护机制的工作机制是：**如果在15分钟内超过85%的客户端节点都没有正常的心跳，那么Eureka就认为客户端与注册中心出现了网络故障，Eureka Server自动进入自我保护机制**，此时会出现以下几种情况：

1. Eureka Server不再从注册列表中移除因为长时间没收到心跳而应该过期的服务。
2. Eureka Server仍然能够接受新服务的注册和查询请求，但是不会被同步到其它节点上，保证当前节点依然可用。
3. 当网络稳定时，当前Eureka Server新的注册信息会被同步到其它节点中。

因此Eureka Server可以很好的应对因网络故障导致部分节点失联的情况，而不会像ZK那样如果有一半不可用的情况会导致整个集群不可用而变成瘫痪。



1. 在服务器数量较少的时候, 比如有10课服务
    - 其中有三个无法访问了(无论是超时还是真的挂了), 这个时候没有触发85%的阈值, 不会自我保护, eureka会剔除服务.
    - 在服务数量少的情况下, 可能真的是挂了, 但是如果服务多就不一定了
2. 在服务器数量多的情况下, 比如有100个服务
    - 其中有三个无法访问了, 同样不会触发自我保护, 没有达到85%阈值. 但是这么多服务, 很有可能是因为网络超时情况.
    - 这时可以考虑将自我保护阈值设置的低一些

自我保护阈值要跟随具体业务, 服务数量合理设置

```yaml
eureka:
  server:
    # 关闭自我保护, 方便开发, 生产环境需要开启
    enable-self-preservation: false
    # 自我保护阈值
    renewal-percent-threshold: 0.85
    # 剔除服务间隔, 默认是60s
    # eviction-interval-timer-in-ms: 1000
    # 默认为true, readWriteCache与readOnlyCache不是强一致, readWriteCache更准确一些, RWC与ROC 30s同步一次
    use-read-only-response-cache: false
    # 默认30s, 缓存更新间隔时间, 设置小一点, 加快服务发现
    # response-cache-update-interval-ms: 1000
  client:
    service-url:
      defaultZone: http://euk.com:7900/eureka
    register-with-eureka: false
    fetch-registry: false
  instance:
    hostname: euk.com

server:
  port: 7900
```

## 多级缓存

ReadOnlyResponseCache

ReadWriteCache 这个缓存更加准确一些, 新注册服务后, 会让该缓存失效

这两个缓存不是强一致性的, 没30s同步一次

直接从ReadWriteCachel拉取会更快一些



那么为什么eureka还要搞一个ReadOnlyResponseCache ?

听名字ReadOnly, 这个缓存是为了给client读取用的, 在高并发环境下, 写入(即注册服务)时不会影响当前客户端读取.

只不过读取的值可能不是最新的, 保证最终一致性



设置是否开启ROC

use-read-only-response-cache: false

设置ROC与RWC同步的时间间隔, 默认30s

response-cache-update-interval-ms

## service-url

RetryableEurekaHttpClient类中定义了`public static final int DEFAULT_NUMBER_OF_RETRIES = 3;`常量默认只有三个eureka server

给四个service-url是没有用的



默认情况下eureka只是用3个

eureka client 默认 从service-url的第一个开始拉取, 只有第一个有问题时, 才回去第二个拉取.

为了分散请求压力, 可以将多个服务上的service-url打散, 让负载均衡一些

