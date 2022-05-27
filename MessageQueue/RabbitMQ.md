# RabbitMQ

## 概念

生产者（Producer）：生产者，就是投递消息的一方。

消费者（Consumer）：消费者，就是接收消息的一方。

RabbitMQ服务器（Broker）：Broker对应的就是RabbitMQ服务器，RabbitMQ支持主从但不支持分布式。一台Broker上可以有多个exchange与queue。



exchange表示交换机，客户端发送消息给broker中的exchange，由exchange来将消息发送给queue。

routerKey表示路由键，可以通过路由键进行支持通配符模式匹配，从而将消息发送给匹配上的交换机。

RabbitMQ提供了四种exchange模式：

1. Direct
    - 直接路由，绝对路由方式，严格匹配与routerKey名称一样的队列
2. Fanout
    - 广播模式，会将消息广播给所有queue
3. Topic
    - 主题模式，根据routerKey和exchange将消息路由到匹配上的queue中。
4. Headers
    - 根据header信息过滤分发消息，header信息可以理解为元数据。

## QuickStart

### dcoker-compose启动

```yaml
version: '3.0'
services:
  rbmq:
    image: rabbitmq:3-management
    container_name: rbmq
    ports:
      - "5671:5671"
      - "5672:5672"
      - "4369:4369"
      - "25672:25672"
      - "15671:15671"
      - "15672:15672"
```

端口说明（https://www.rabbitmq.com/install-rpm.html#configuration的google翻译）

- 4369：[epmd](http://erlang.org/doc/man/epmd.html)，RabbitMQ 节点和 CLI 工具使用的对等发现服务
- 5672、5671：由不带和带 TLS 的 AMQP 0-9-1 和 1.0 客户端使用
- 25672：用于节点间和 CLI 工具通信（Erlang 分发服务器端口），从动态范围分配（默认限制为单个端口，计算为 AMQP 端口 + 20000）。除非这些端口上的外部连接确实是必要的（例如集群使用[联邦](https://www.rabbitmq.com/federation.html)或在子网外的机器上使用 CLI 工具），否则这些端口不应公开。有关详细信息，请参阅[网络指南](https://www.rabbitmq.com/networking.html)。
- 35672-35682：由 CLI 工具（Erlang 分发客户端端口）用于与节点通信，并从动态范围分配（计算为服务器分发端口 + 10000 到服务器分发端口 + 10010）。有关详细信息，请参阅[网络指南](https://www.rabbitmq.com/networking.html)。
- 15672：[HTTP API](https://www.rabbitmq.com/management.html)客户端、[管理 UI](https://www.rabbitmq.com/management.html)和[rabbitmqadmin](https://www.rabbitmq.com/management-cli.html) （仅在启用[管理插件](https://www.rabbitmq.com/management.html)的情况下）
- 61613、61614：不带和带 TLS 的[STOMP 客户端](https://stomp.github.io/stomp-specification-1.2.html)（仅在启用[STOMP 插件](https://www.rabbitmq.com/stomp.html)的情况下）
- 1883、8883：如果启用了[MQTT 插件](https://www.rabbitmq.com/mqtt.html)，则不带和带 TLS 的[MQTT 客户端](http://mqtt.org/)
- 15674：STOMP-over-WebSockets 客户端（仅当[Web STOMP 插件](https://www.rabbitmq.com/web-stomp.html)启用时）
- 15675：MQTT-over-WebSockets 客户端（仅当启用[Web MQTT 插件时）](https://www.rabbitmq.com/web-mqtt.html)
- 15692：Prometheus 指标（仅在启用[Prometheus 插件](https://www.rabbitmq.com/prometheus.html)的情况下）

### 配置

引入依赖

```xml
<properties>
	<spring-boot.version>2.3.7.RELEASE</spring-boot.version>
</properties>

<dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-dependencies</artifactId>
                <version>${spring-boot.version}</version>
                <type>pom</type>
                <scope>import</scope>
            </dependency>
    </dependencyManagement>
```

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-amqp</artifactId>
</dependency>
```

配置文件

```yaml
spring:
	rabbitmq:
        host: localhost
        port: 5672
        virtual-host: /
        # 开启发送端确认，成功发送给broker交换机的回调
        publisher-confirm-type: correlated
        # 开启发送端消息抵达队列的确认，broker交换机传输到queue时失败的回调
        publisher-returns: true
        template:
          # 只要抵达队列，以异步方式优先回调publisher-returns
          mandatory: true
        listener:
          simple:
            # 开启手动ack
            acknowledge-mode: manual
```

配置类

```java
@Configuration
@EnableRabbit
public class RabbitMqConfig {
}
```

## 简单使用

### AmqpAdmin使用

> 该接口可以创建删除队列、交换机

```java
@SpringBootTest
class GulimallOrderApplicationTests {

    @Autowired
    AmqpAdmin amqpAdmin;

    @Autowired
    RabbitTemplate rabbitTemplate;

    // 创建交换机
    @Test
    void amqpAdminDeclareExchangeTest() {
        final DirectExchange directExchange = new DirectExchange(
                "hello-java-amqp-client"
        );
        amqpAdmin.declareExchange(directExchange);
    }

    // 创建队列
    @Test
    void amqpAdminDeclareQueue() {
        final Queue q = new Queue("hello-java-client-queue");
        amqpAdmin.declareQueue(q);
    }

    // 绑定队列到交换机
    @Test
    void amqpAdminBinding() {
        final Binding binding = new Binding(
                "hello-java-client-queue",
                Binding.DestinationType.QUEUE,
                "hello-java-amqp-client",
                "hello.java", null
        );
        amqpAdmin.declareBinding(binding);
    }

}
```

### 发送消息

```java
@SpringBootTest
class GulimallOrderApplicationTests {

    @Autowired
    RabbitTemplate rabbitTemplate;

    @Test
    void sendMessageTest() {
        for (int i = 0; i < 10; i++) {
            if (i % 2 == 0) {
                final OrderEntity orderEntity = new OrderEntity();
                orderEntity.setId((long) i);
                orderEntity.setCreateTime(new Date());
                rabbitTemplate.convertAndSend("hello-java-amqp-client", "hello.java", orderEntity);
            } else {
                final OrderReturnReasonEntity reasonEntity = new OrderReturnReasonEntity();
                reasonEntity.setId(1L);
                reasonEntity.setName("ZhangSan");
                reasonEntity.setCreateTime(new Date());
                rabbitTemplate.convertAndSend("hello-java-amqp-client", "hello2.java", reasonEntity);
            }
        }
    }
}
```

### 消费消息

#### 自动确认

默认配置就是自动确认

```java
// 配置监听的队列，该注解也可以加在方法上
@RabbitListener(queues = {"hello-java-client-queue"})
@Service("orderItemService")
@Slf4j
public class OrderItemServiceImpl {

    // 不同类型的消息会交由对应的方法助理

    // 该注解表示该方法用于接受消息
    @RabbitHandler
    public void receiveMsg(Message message, OrderReturnReasonEntity reasonEntity, Channel channel) {
        log.info("接收到msg: {}", message);
        log.info("reasonEntity: {}", reasonEntity);
    }

    @RabbitHandler
    public void receiveMsg2(Message message, OrderEntity orderEntity, Channel channel) {
        log.info("接收到msg: {}", message);
        log.info("reasonEntity: {}", orderEntity);
    }
}
```

#### 手动确认

```yaml
spring:
	rabbitmq:
        listener:
          simple:
            # 开启手动ack
            acknowledge-mode: manual
```

```java
@RabbitListener(queues = {"hello-java-client-queue"})
@Service("orderItemService")
@Slf4j
public class OrderItemServiceImpl {

    @RabbitHandler
    public void receiveMsg(Message message, OrderReturnReasonEntity reasonEntity, Channel channel) {
        log.info("接收到msg: {}", message);
        log.info("reasonEntity: {}", reasonEntity);
        // channel内自增的tag
        final long deliveryTag = message.getMessageProperties().getDeliveryTag();
        log.info("deliveryTag: {}", deliveryTag);
        try {
            // ack签收消息，multiple是否批量签收
            channel.basicAck(deliveryTag, false);
            /*
             nack拒绝消息
             multiple为true时该消息前面的消息全部拒绝
             requeue为true表示消息重新回到队列中，再消费（消息重投），值为false则直接丢弃消息
             */
            // channel.basicNack(deliveryTag, false, true);
        } catch (IOException e) {
            log.error("消息签收失败", e);
        }
    }

    @RabbitHandler
    public void receiveMsg2(Message message, OrderEntity orderEntity, Channel channel) {
        log.info("接收到msg: {}", message);
        log.info("reasonEntity: {}", orderEntity);
        // channel内自增的tag
        final long deliveryTag = message.getMessageProperties().getDeliveryTag();
        log.info("deliveryTag: {}", deliveryTag);
        try {
            // ack签收消息，multiple是否批量签收
            channel.basicAck(deliveryTag, false);
        } catch (IOException e) {
            log.error("消息签收失败", e);
        }
    }
}
```

### 生产者回调

```java
@Configuration
@EnableRabbit
@Slf4j
public class RabbitMqConfig {

    @Autowired
    private RabbitTemplate rabbitTemplate;

    // 配置以Json方式序列化消息，默认使用的是java序列化
    @Bean
    public MessageConverter messageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @PostConstruct
    public void rabbitTemplate() {
        rabbitTemplate.setConfirmCallback(new RabbitTemplate.ConfirmCallback() {
            /**
             * broker交换机收到消息的回调
             * 只要消息确认抵达broker交换机，ack就为true
             * @param correlationData 当前消息的唯一关联数据（消息的唯一id，可以理解唯一事务id）
             * @param ack 消息是否成功接收到
             * @param cause 失败原因
             */
            @Override
            public void confirm(CorrelationData correlationData, boolean ack, String cause) {
                log.info("broker交换机接受消息失败, CorrelationData: {}, ack: {}, cause: {}",
                        correlationData, ack, cause);
            }
        });

        rabbitTemplate.setReturnCallback(new RabbitTemplate.ReturnCallback() {
            /**
             * 消息抵达消息队列的回调
             * @param message 投递失败的消息详情
             * @param replyCode 恢复的状态码
             * @param replyText 恢复的文本内容
             * @param exchange 消息发给了那个交换机
             * @param routingKey 消息发送的时候使用的是那个路由键
             */
            @Override
            public void returnedMessage(Message message, int replyCode, String replyText,
                                        String exchange, String routingKey) {
                log.error("Fail message: {}, replyCode: {}, replyText: {}, exchange: {}, routingKey: {}",
                        message, replyCode, replyText, exchange, routingKey);
            }
        });
    }
}
```

### TTL队列

rabbitmq的队列提供了消息过期机制，指定`x-message-ttl`来设置过期时间。

过期的消息被丢弃，可以指定`x-dead-letter-exchange`与`x-dead-letter-routing-key`将详细路由到指定死信队列。

下面是一个模拟订单下单场景，用户下单后发送消息给订单队列，消费者消费订单队列里的数据，如果支付成功成功消费消息，没有支付就拒绝消息并将消息重投，继续消费。当订单过期后，由订单死信队列消费来解锁订单。

```java
// 用@Bean将队列、交换机、绑定关系注入容器，让有组件需要监听相关队列的时候会自动创建（懒加载）
@Configuration
public class RabbitMqOrderConfig {

    /**
     * 绑定订单过期的死信队列交换机与订单过期死信队列
     */
    @Bean
    public Binding orderExchangeDeadBinding() {
        return BindingBuilder.bind(orderDeadQueue())
                .to(orderExchangeDead())
                .with("order.dead")
                .noargs();
    }

    @Bean
    public Binding orderExchangeBinding() {
        return BindingBuilder.bind(orderQueue())
                .to(orderExchange())
                .with("order")
                .noargs();
    }

    /**
     * 订单交换机
     */
    @Bean
    public Exchange orderExchange() {
        return new TopicExchange("gulimall.order.exchange", true, false);
    }

    /**
     * 订单过期的死信队列交换机
     */
    @Bean
    public Exchange orderExchangeDead() {
        return new TopicExchange("gulimall.order.exchange.dead", true, false);
    }

    /**
     * 订单队列，带有消息过期时间
     * 消息过期后会交给订单死信队列，自动解除订单
     */
    @Bean
    public Queue orderQueue() {
        return new Queue("gulimall.order.queue", true, false, false,
                new HashMap<>() {{
                    // 设置消息过期时间
                    // put("x-message-ttl", Duration.of(30, ChronoUnit.MINUTES).toMillis());
                    put("x-message-ttl", Duration.of(1, ChronoUnit.MINUTES).toMillis());
                    // 消息过期后不会删除，交由死信队列交换机路由给死信队列
                    put("x-dead-letter-exchange", "gulimall.order.exchange.dead");
                    // 死信消息发送给死信交换机的路由键
                    put("x-dead-letter-routing-key", "order.dead");
                }});
    }

    /**
     * 订单过期的死信队列
     */
    @Bean
    public Queue orderDeadQueue() {
        return new Queue("gulimall.order.dead.queue", true, false, false);
    }
}
```

```java
@Component
@RabbitListener(queues = "gulimall.order.dead.queue")
@Slf4j
public class OrderDeadQueueConsumer {

    /**
     * 消费过期订单的死信队列中的数据
     * @param orderId 订单id
     * @param message mq消息对象
     * @param channel mq管道对象
     */
    @RabbitHandler
    public void orderDeadHandle(Integer orderId, Message message, Channel channel) {
        final long deliveryTag = message.getMessageProperties().getDeliveryTag();
        try {
            channel.basicAck(deliveryTag, false);
            log.info("{}号订单过期，已解锁订单", orderId);
        } catch (IOException e) {
            log.error(String.format("%d号订单过期，解锁订单出错", orderId), e);
        }
    }
}
```

```java
@Component
@RabbitListener(queues = "gulimall.order.queue")
@Slf4j
public class OrderConsumer {

    /**
     * 消费支付成功的订单
     * @param orderId 订单id
     * @param message mq消息对象
     * @param channel mq管道对象
     */
    @RabbitHandler
    public void orderHandler(Integer orderId, Message message, Channel channel) {
        // 模拟订单支付成功，订单id > 10表示订单已支付，方便演示订单过期后被死信交换机处理
        final long deliveryTag = message.getMessageProperties().getDeliveryTag();
        if (orderId > 10) {
            try {
                channel.basicAck(deliveryTag, false);
                log.info("{}号订单支付成功，已扣减库存", orderId);
            } catch (IOException e) {
                log.error(String.format("%d号的订单支付成功，扣减库存失败", orderId), e);
            }
        } else {
            try {
                channel.basicNack(deliveryTag, false, true);
            } catch (IOException e) {
                log.error(String.format("%d号的订单未支付，拒绝消费出错", orderId), e);
            }
        }
    }
}
```