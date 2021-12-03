# SpringCloud

## Netflix

> 网关: zuul
>
> 服务注册与服务发现: eureka
>
> RPC: feign & open feign
>
> 客户端负载均衡: ribbon
>
> hystrix: 容错管理, 断路器

### Zuul

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-zuul</artifactId>
</dependency>
```

@EnableZuulProxy开启zuul

```yaml
spring:
  application:
    name: CloudZuul

eureka:
  client:
  	# 注册到eureka服务器上
    service-url:
      defaultZone: http://euk.com:7000/eureka/

# 加载网关上生效了, 之前加在客户端没有生效, 这里也必须使用小写服务名, 不然不会生效
# 配置文件中的负载均衡貌似必须配置在zuul网关层, 配置在consumer与provider上不生效
eurekaclient:
  ribbon:
    NFLoadBalancerRuleClassName: com.netflix.loadbalancer.RandomRule

zuul:
  # 这里必须使用小写, 虽然eureka注册的服务不许分大小写
  # 但是zuul会将所有服务名小写
  # 访问的时候可以不区分大小写, zuul能识别到并自动转换成全小写的服务名
  # 如果要配置忽略的服务就必须全部使用小写, !---: 坑
  ignored-services:
    - eurekaprovider
  routes:
    baidu:
      path: /aidu/**
      url: https://www.baidu.com
    eurekaclient:
      # 重写访问path, 相当于虚拟主机名, 不过配置后之前的名字还是有效
      path: /consumer/**
  # 配置请求通用前缀
  # prefix: /api
  # 删除前缀, 默认为true
  strip-prefix: true

server:
  port: 80
```

### Eureka

#### Server

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-server</artifactId>
</dependency>
```

@EnableEurekaServer开启Eureka

```yaml
spring:
  application:
    name: EurekaServer

eureka:
  server:
    # 开发时为了服务快速下线, 方便调试, 可以关闭. 生产环境建议打开
    enable-self-preservation: false
  client:
    serviceUrl:
#      defaultZone: http://euk.com:7000/eureka/,http://euk1.com:7001/eureka/,http://euk2.com:7002/eureka/
      defaultZone: http://euk.com:7000/eureka/

#配置后没有效果, 其实也可以在代码中配置IRule, 如果想切换通过配置文件来配置使用那个负载均衡规则
#ribbon:
#  NFLoadBalancerRuleClassName: com.netflix.loadbalancer.RandomRule

logging:
  level:
    com.lcw.eurekaserver: debug
---
spring:
  profiles: euk
eureka:
  instance:
    hostname: euk.com
server:
  port: 7000
```

#### Client

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-eureka-client</artifactId>
</dependency>
```

@EnableEurekaClient开启EurekaClient

```yaml
spring:
  application:
    name: EurekaClient

eureka:
  client:
  	# 注册到EurekaServer
    service-url:
      defaultZone: http://euk.com:7000/eureka/

logging:
  level:
    com.lcw.eurekaclient: debug

---
spring:
  profiles: eukClient
server:
  port: 8000
```

### OpenFeign

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-openfeign</artifactId>
</dependency>
```

> OpenFeign是Feign封装, 加入了对SpringMVC注解的支持, 利用动态代理生成实现类
>
> @EnableFeignClients开启OpenFeign

Provider定义接口

```java
public interface IProviderApi {
    @GetMapping("/port")
    String getProviderPort();

    @PostMapping("/param")
    String postParam(@RequestParam("key") String key);

    @PostMapping("/data")
    String postParam(@RequestBody Map<String, Object> map);

    @PostMapping("testTimeOutAndRetry")
    String testTimeOutAndRetry(@RequestBody String port);
}
```

Consumer定义Api接口并实现, 使用@FeignClient自动生成实现类

```java
// 名字不区分大小写
// name就是Eureka的服务名, 通过服务名调用依赖Ribbon负载均衡
@FeignClient(name = "EuRekaProVider")
public interface OpenFeignApi extends IProviderApi {
}
```

### RestTemplate

> SpringCloud提供的HttpClient功能

```java
@Bean
@LoadBalanced // 开启负载均衡
public RestTemplate restTemplate() { // 配置RestTemplate
    final RestTemplate restTemplate = new RestTemplate();
    // restTemplate.getInterceptors().add(new LoggingClientRequestInterceptor()); 添加请求拦截器
    return restTemplate;
}
```

```java
@GetMapping("rpcPort")
public String rpcPort() {
    // 可以使用ip:port调用
    // 也可以使用服务名调用, 但是必须开启负载均衡
    final String res = restTemplate.getForObject("http://EUREKAPROVIDER/port", String.class);
    return res;
}
```

```java
@GetMapping("rpcParam")
public Object rpcParam() {
    // 不能使用HashMap, Spring无法转换HashMap, 可以使用MultiValueMap代替(可能是为了表示url中的数组类型)
    MultiValueMap<String, Object> map = new LinkedMultiValueMap<>();
    map.add("key", "hello");
    HttpHeaders headers = new HttpHeaders();
    // 使用form url的方式传参, Provider需要使用@RequestParam注解获取参数
    headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

    HttpEntity<MultiValueMap<String, Object>> entity = new HttpEntity<>(map, headers);
    ResponseEntity<String> res = restTemplate.postForEntity("http://EUREKAPROVIDER/param",
            entity, String.class);
    return res;
}
```

```java
@GetMapping("rpcData")
public Object rpcData() {
    Map<String, Object> map = new HashMap<>();
    map.put("name", "lcw");
    map.put("list", new ArrayList<String>() {{
        add("hello");
        add("provider");
    }});
    HttpHeaders headers = new HttpHeaders();
    // 手动指定数据类型, 指定JSON, Provider就需要使用@RequestBody来获取参数	
    headers.setContentType(MediaType.APPLICATION_JSON);

    HttpEntity<Map<String, Object>> entity = new HttpEntity<>(map, headers);
    ResponseEntity<String> res = restTemplate.postForEntity("http://EUREKAPROVIDER/data",
            entity, String.class);
    return res;
}
```

### Ribbon

> eureka client starter中自带ribbon, 无需手动引入
>
> 下面的配置都没有提示, 可以参考github eureka wiki

```yaml
ribbon:
  # 连接超时
  #  ConnectTimeout: 1000
  # 业务逻辑超时
  ReadTimeout: 3000
  # 同一台实例的最大重试次数
  MaxAutoRetries: 1
  # 负载其他服务器的重试次数
  MaxAutoRetriesNextServer: 1
  # 是否所有操作都重试, 一般建议设为false, 重试会提高延迟, 影响用户体验, 提高系统压力
  OkToRetryOnAllOperations: true
```

### Hystrix

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>

<!--hystrix面板-->
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix-dashboard</artifactId>
</dependency>
```

@EnableCircuitBreaker 开启断路器, 即开启hystrix
@EnableHystrixDashboard 开启dahsboard监控面板

```yaml
# Feign中内置的容错机制与Hystrix有冲突, 默认关闭了Feign的hystrix, 需要手动开启
feign:
  hystrix:
    # 默认是关闭的, 开启后hystrix才会生效
    enabled: true
```

hystrix dashboard还挺坑的, 基本上都是spring或者hystrix的安全机制, 没有对外暴露端点

```yaml
hystrix:
  dashboard:
    # 如果想要dashboard能访问, 需要添加到proxy-stream-allow-list
    proxy-stream-allow-list: 'euk.com'

# 暴露hystrix端点, 不然访问不到hystrix.stream
management:
  endpoints:
    web:
      exposure:
        include: '*'
  endpoint:
    health:
      # 默认是never, 设置成查看详细信息always
      show-details: always
```

## Alibaba

## 其他组件

### SpringBootAdmin

> 第三方为SpringBoot程序开发的监控页面
>
> 可以监控服务上下线, 邮件提醒
>
> 健康状况, JVM监控. 请求跟踪等

#### 注意

SpringBootAdmin版本兼容性有大坑, 目前使用SpringBoot `2.3.7.RELEASE`版本

最高使用`2.3.1`版本

使用应用监控一类的框架时, 一般会有安全机制, 注意对外暴露接口即可

```yaml
# 使用应用监控时, 万能配置, 开发时暴露所有接口, 生产环境需要按需配置
management:
  endpoints:
    web:
      exposure:
        include: '*'
  endpoint:
    health:
      # 默认是never, 设置成查看详细信息always
      show-details: always
```

#### 服务端

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<!-- 不需要引入boot admin ui, admin server自带ui包 -->
<dependency>
    <groupId>de.codecentric</groupId>
    <artifactId>spring-boot-admin-starter-server</artifactId>
</dependency>
<!-- 邮件提醒依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-mail</artifactId>
</dependency>
```

```yaml
spring:
  application:
    name: boot-admin
  mail:
  	# 邮件服务商host
    host: smtp.163.com
    # 发送放用户名
    username: yuzusoft_CCC@163.com
    # 在邮件服务商网站上申请的授权码
    password: ************
    # 不同的服务商端口不一样, 注意SSL和非SSL协议端口也不一样, 需要去网上查询
    port: 25
  boot:
    admin:
      # 开启配置服务上下线邮件提醒
      notify:
        mail:
          # 接受方(邮件提醒发给谁)
          to: lcwliuchongwei@qq.com
          # 发送方
          from: yuzusoft_CCC@163.com
server:
  port: 8080
```

##### 自定义提醒

继承AbstractStatusChangeNotifier类, 实现方法即可

#### 客户端

```xml
<dependency>
    <groupId>de.codecentric</groupId>
    <artifactId>spring-boot-admin-starter-client</artifactId>
    <version>2.3.1</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```yaml
# 配置admin server的地址
spring:
    boot:
      admin:
        client:
          url: http://euk.com:8080/
```

### 链路追踪

#### Zipkin & Sleuth

> Sleuth是SpringCloud给出的分布式链路追踪解决方案, 兼容 Zipkin，HTrace 和其他基于日志的追踪系统，例如 ELK (Elasticsearch 、Logstash、 Kibana)
>
> - `链路追踪`：通过 Sleuth 可以很清楚的看出一个请求都经过了那些服务，可以很方便的理清服务间的调用关系等。
> - `性能分析`：通过 Sleuth 可以很方便的看出每个采样请求的耗时，分析哪些服务调用比较耗时，当服务调用的耗时随着请求量的增大而增大时， 可以对服务的扩容提供一定的提醒。
> - `数据分析，优化链路`：对于频繁调用一个服务，或并行调用等，可以针对业务做一些优化措施。
> - `可视化错误`：对于程序未捕获的异常，可以配合 Zipkin 查看。
>
> 
>
> [Zipkin](https://zipkin.io/) 是 Twitter 公司开发贡献的一款开源的分布式实时数据追踪系统（Distributed Tracking System），基于 Google Dapper 的论文设计而来，其主要功能是聚集各个异构系统的实时监控数据。
>
> - `Collector`：收集器组件，处理从外部系统发送过来的跟踪信息，将这些信息转换为 Zipkin 内部处理的 Span 格式，以支持后续的存储、分析、展示等功能。
> - `Storage`：存储组件，处理收集器接收到的跟踪信息，默认将信息存储在内存中，可以修改存储策略使用其他存储组件，支持 MySQL，Elasticsearch 等。
> - `Web UI`：UI 组件，基于 API 组件实现的上层应用，提供 Web 页面，用来展示 Zipkin 中的调用链和系统依赖关系等。
> - `RESTful API`：API 组件，为 Web 界面提供查询存储中数据的接口。

```xml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-sleuth</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-zipkin</artifactId>
</dependency>
```

> zipkin 与 sleuth的配置详见官网

在需要监控的应用中暴露接口

```yaml
management:
  endpoints:
    web:
      exposure:
        include: '*'
  endpoint:
    health:
      # 默认是never, 设置成查看详细信息always
      show-details: always
```

去[Zipkin官网](https://zipkin.io/)下载server端jar包, 运行即可

#### Skywalking

> Apache顶级项目
>
> 国产APM系统, 采用语言探针的方式, 无侵入, 应用程序无需任何依赖

##### 部署

###### Server

Skywalking依赖存储中间件, 支持 H2/MySQL/TiDB/InfluxDB/ElasticSearch等

运行前需要配置config中的application.yaml

运行apache-skywalking-apm-bin/bin中的startup脚本即可

###### Agent

下载Agent探针

在运行jar包时, 添加jvm参数

 `-javaagent:D:\study\java\springcloud\skywalking-agent\skywalking-agent.jar -Dskywalking.agent.service_name=eureka-zuul -Dskywalking.controller.backend_service=localhost:11800`

* -Dskywalking.agent.service_name=eureka-zuul 配置服务名
* -Dskywalking.controller.backend_service=localhost:11800 配置server端口
* 数据收集
    * Http默认端口 12800
    * gRPC默认端口 11800

### 配置中心

#### 协程Apollo

[Apollo官网](www.apolloconfig.com)

##### 服务端

现在quick-start项目配置数据源, mysql请使用5.7即以上

执行sql文件, 建库

##### 客户端

```xml
<dependency>
    <groupId>com.ctrip.framework.apollo</groupId>
    <artifactId>apollo-client</artifactId>
    <version>1.9.1</version>
</dependency>
```

@EnableApolloConfig开启Apollo

```java
@Configuration
@EnableApolloConfig
public class ApolloConfig {
    @Bean
    public void config() {
        final Config config = ConfigService.getAppConfig();
        // 添加监听器
        config.addChangeListener(configChangeEvent -> {
            System.out.println("Changes for namespace " + configChangeEvent.getNamespace());
            for (String key : configChangeEvent.changedKeys()) {
                ConfigChange change = configChangeEvent.getChange(key);
                System.out.printf("Found change - key: %s, oldValue: %s, newValue: %s, changeType: %s%n",
                        change.getPropertyName(),
                        change.getOldValue(),
                        change.getNewValue(),
                        change.getChangeType());
            }
        });
    }
}
```

```java
@RestController
public class MainController {
    // Value注解自动同步Apollo配置
    @Value("${name}")
    private String name;

    @GetMapping("getName")
    public String getName() {
        return name;
    }
}
```