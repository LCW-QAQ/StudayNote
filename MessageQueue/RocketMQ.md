# RocketMQ

## 部署

[RockeMQ官网](https://rocketmq.apache.org/)下载rocketmq二进制包

[rocketmq github](https://github.com/apache/rocketmq)下载rocketmq dashboard

* 运行`rocketmq/bin`目录下的`mqnamesrv`与`mqbroker`即可
    * `mqnamesrv`
    * `mqbroker -n 127.0.0.1:9876 autoCreateTopicEnable=true`
        * autoCreateTopicEnable=true是为了自动创建topic, 否则无法给未创建的topic发消息
* 运行dashboard
    * 官网只提供源码, 运行`mvn clean package -Dmaven.test.skip=true`编译
    * 编译成功后直接`java -jar rocketmq-dashboard-1.0.0.jar`即可
    * 运行后需要在OPS选项中手动添加namesrv地址, 也可以在`application.properties`中配置



### 配置文件

> rocketmq默认内存2g (rocketmq 4.9.0 2021/12/27)
>
> 在小内存服务器中部署可能会出现内存不足, 需要配置runbroker或runserver脚本中的jvm内存大小

> rocketmq部署在windows上时, 可能会出现`Files\.....\`找不到文件或无法加载主类
>
> 大多数都是因为windows上的文件夹有空格导致, 要么将rocketmq与jdk安装到没有空格的路径下, 要么在配置文件中做出修改
>
> 如下:

```cmd
# runbroker.cmd
@echo off
rem Licensed to the Apache Software Foundation (ASF) under one or more
rem contributor license agreements.  See the NOTICE file distributed with
rem this work for additional information regarding copyright ownership.
rem The ASF licenses this file to You under the Apache License, Version 2.0
rem (the "License"); you may not use this file except in compliance with
rem the License.  You may obtain a copy of the License at
rem
rem     http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

# ------------------------修改------------------------
# 添加一行, 将JAVA_HOME以字符串的方式存储, 替换下面的JAVA_HOME即可
set JAVAHOME="%JAVA_HOME%"

if not exist "%JAVA_HOME%\bin\java.exe" echo Please set the JAVA_HOME variable in your environment, We need java(x64)! & EXIT /B 1
set "JAVA=%JAVA_HOME%\bin\java.exe"

setlocal

set BASE_DIR=%~dp0
set BASE_DIR=%BASE_DIR:~0,-1%
for %%d in (%BASE_DIR%) do set BASE_DIR=%%~dpd

set CLASSPATH=.;%BASE_DIR%conf;%CLASSPATH%

rem ===========================================================================================
rem  JVM Configuration
rem ===========================================================================================
set "JAVA_OPT=%JAVA_OPT% -server -Xms2g -Xmx2g"
set "JAVA_OPT=%JAVA_OPT% -XX:+UseG1GC -XX:G1HeapRegionSize=16m -XX:G1ReservePercent=25 -XX:InitiatingHeapOccupancyPercent=30 -XX:SoftRefLRUPolicyMSPerMB=0 -XX:SurvivorRatio=8"
set "JAVA_OPT=%JAVA_OPT% -verbose:gc -Xloggc:%USERPROFILE%\mq_gc.log -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCApplicationStoppedTime -XX:+PrintAdaptiveSizePolicy"
set "JAVA_OPT=%JAVA_OPT% -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=30m"
set "JAVA_OPT=%JAVA_OPT% -XX:-OmitStackTraceInFastThrow"
set "JAVA_OPT=%JAVA_OPT% -XX:+AlwaysPreTouch"
set "JAVA_OPT=%JAVA_OPT% -XX:MaxDirectMemorySize=15g"
set "JAVA_OPT=%JAVA_OPT% -XX:-UseLargePages -XX:-UseBiasedLocking"
# ------------------------修改------------------------
# 这里换成我们定义的字符串方式的JAVAHOME
set "JAVA_OPT=%JAVA_OPT% -Djava.ext.dirs=%BASE_DIR%lib;%JAVAHOME%\jre\lib\ext"
set "JAVA_OPT=%JAVA_OPT% -cp %CLASSPATH%"

"%JAVA%" %JAVA_OPT% %*
```

runserver.cmd文件同理

## 使用

### 自定义bean

#### 普通producer

```java
@Configuration
public class RocketMqProducer {
    @Bean
    public MQProducer mqProducer() throws MQClientException {
        // 必须指定producerGroup
        final DefaultMQProducer mqProducer = new DefaultMQProducer("producerGroup-1");
        mqProducer.setNamesrvAddr("127.0.0.1:9876");
        mqProducer.start();
        return mqProducer;
    }
}
```

#### pull模式consumer

```
@Configuration
@Slf4j
public class RocketMqPullConsumer {
    //    @Bean
    public MQConsumer mqPullConsumer() throws MQClientException {
        // rocketmq 支持pull与push两种模式
        // pull性能损耗低. 客户端手动拉取, 拉取逻辑等需要自己实现, 开发成本高, 一般使用push
        // push性能损耗高, 但是实时性高. 服务端推送给客户端
        final DefaultMQPullConsumer mqPullConsumer = new DefaultMQPullConsumer("consumerGroup-1");
        mqPullConsumer.setNamesrvAddr("127.0.0.1:9876");

        // 使用timer简单模拟一下
        final ScheduledThreadPoolExecutor executor = new ScheduledThreadPoolExecutor(1, new ThreadFactory() {
            @Override
            public Thread newThread(Runnable r) {
                return new Thread(r, "mqPullConsumer-scheduled-1");
            }
        });
        executor.scheduleAtFixedRate(() -> {
            try {
                final Set<MessageQueue> messageQueues = mqPullConsumer.fetchSubscribeMessageQueues("topic-1");
                log.info("------消费消息------");
                log.info("messageQueues: {}", messageQueues);
                for (MessageQueue mq : messageQueues) {
                    try {
                        mqPullConsumer.pullBlockIfNotFound(mq, "*", 0, 10, new PullCallback() {
                            @Override
                            public void onSuccess(PullResult pullResult) {
                                log.info("pullResult: {}", pullResult);
                            }

                            @Override
                            public void onException(Throwable e) {
                                log.error("pull消息出错", e);
                            }
                        });
                    } catch (RemotingException | InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                log.info("------消费消息 end------");
            } catch (MQClientException e) {
                e.printStackTrace();
            }
        }, 5000, 5000, TimeUnit.MILLISECONDS);

        // 这个不是消费, 这个是监听
        mqPullConsumer.setMessageQueueListener(new MessageQueueListener() {
            @Override
            public void messageQueueChanged(String topic, Set<MessageQueue> mqAll, Set<MessageQueue> mqDivided) {
                log.info("------MessageQueueChanged------");
                log.info("topic: {}", topic);
                log.info("mqAll: {}", mqAll);
                log.info("mqDivided: {}", mqDivided);
                log.info("------MessageQueueChanged end------");
            }
        });

        mqPullConsumer.start();
        return mqPullConsumer;
    }
}
```

#### push模式consumer

```java
@Configuration
@Slf4j
public class RocketMqPushConsumer {
    @Bean
    public MQConsumer mqPushConsumer() throws MQClientException {
        final DefaultMQPushConsumer mqPushConsumer = new DefaultMQPushConsumer("consumerGroup-1");
        mqPushConsumer.setNamesrvAddr("127.0.0.1:9876");
        // 订阅topic, subExpression根据tag或sql过滤, 详见文档
        mqPushConsumer.subscribe("topic-1", "*");
        // 设置最大再消费次数, 超过限制后进入死信队列
        // mqPushConsumer.setMaxReconsumeTimes(10);

        /*
            rocketmq 提供两种消费模式
            mqPushConsumer.setMessageModel(MessageModel.CLUSTERING);
                CLUSTERING
                    表示同一个consumerGroup中只有一个人能消费到同一个消息
            mqPushConsumer.setMessageModel(MessageModel.BROADCASTING);
                BROADCASTING
                    表示同一个consumerGroup中只每个人能消费到所有消息
         */

        /*
        RocketMQ 提供了MessageListenerConcurrently与MessageListenerOrderly
            MessageListenerConcurrently
                并发消费消息, 不保证消息的顺序
            MessageListenerOrderly
                保证分区内顺序消费(一个topic对应, 对应多个queue, 只保证每个queue内顺序消费)
         */

        /*
            rocketmq 提供消息过滤机制
            mqPushConsumer.subscribe("topic", MessageSelector.byTag("R18"));
                tag
                    通过指定tag过滤, 多个tag可以使用||分割
                    producer发送消息时需指定tag
            mqPushConsumer.subscribe("topic", MessageSelector.bySql("age >= 18"));
                sql
                    通过sql语法过滤消息
                    sql默认关闭, 需要在broker.conf中添加enablePropertyFilter=true
                    producer发送消息时, 需要使用putUserProperty, 自定义属性
         */

        mqPushConsumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext context) {
                log.info("------消费消息------");
                log.info("msgs: {}", msgs);
                log.info("------消费消息 end------");
                // return ConsumeConcurrentlyStatus.RECONSUME_LATER; // 再消费
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS; // 消费成功
            }
        });

        mqPushConsumer.start();
        return mqPushConsumer;
    }
}
```

#### 事务消息producer

```java
@Configuration
@Slf4j
public class RocketMqTransactionProducer {
    @Bean
    public MQProducer mqTransactionProducer() throws MQClientException {
        final TransactionMQProducer producer = new TransactionMQProducer("transaction-producerGroup-1");
        producer.setNamesrvAddr("127.0.0.1:9876");
        producer.setTransactionListener(new TransactionListener() {
            @Override
            public LocalTransactionState executeLocalTransaction(Message msg, Object arg) {
                log.info("------执行本地事务------");
                log.info("------执行本地事务 end------");
                // return LocalTransactionState.ROLLBACK_MESSAGE; // 回滚消息
                // return LocalTransactionState.UNKNOW; // UNKNOW 特殊处理, 走checkLocalTransaction
                return LocalTransactionState.COMMIT_MESSAGE;
            }

            @Override
            public LocalTransactionState checkLocalTransaction(MessageExt msg) {
                log.info("------checkLocalTransaction------");
                log.info("------checkLocalTransaction end------");
                return LocalTransactionState.COMMIT_MESSAGE;
            }
        });
        producer.start();
        return producer;
    }
}
```

### RocketMQTemplate and Annotation

#### yaml配置

详细配置见官网

```yaml
rocketmq:
  name-server: 127.0.0.1:9876
```

#### RestTemplateController Demo

```jav
@RestController
@RequestMapping("template")
@RequiredArgsConstructor
@Slf4j
public class RocketMqTemplateController {
    private final RocketMQTemplate rocketMQTemplate;

    @PostMapping("send")
    public ResponseEntity<Object> send(@RequestBody String msg) {
        rocketMQTemplate.convertAndSend("template-topic-1", msg);
        return ResponseEntity.ok("ok");
    }

    @PostMapping("sendAsync")
    public ResponseEntity<Object> sendAsync(@RequestBody String msg) {
        rocketMQTemplate.asyncSend("template-topic-1", msg, new SendCallback() {
            @Override
            public void onSuccess(SendResult sendResult) {
                log.info("消息发送成功, sendResult: {}", sendResult);
            }

            @Override
            public void onException(Throwable e) {
                log.info("消息发送失败", e);
            }
        });
        return ResponseEntity.ok("ok");
    }

    @PostMapping("sendInTransaction")
    public ResponseEntity<Object> sendInTransaction(@RequestBody String msg) {
        final TransactionSendResult transactionSendResult = rocketMQTemplate.sendMessageInTransaction(
                "transaction-producerGroup-template-1",
                "template-transaction-topic-1",
                MessageBuilder.withPayload(msg).build(),
                null);
        return ResponseEntity.ok(transactionSendResult);
    }
}
```

#### @RocketMQMessageListener

```java
@Component
@RocketMQMessageListener(
        consumerGroup = "annotation-consumerGroup-1",
        topic = "template-topic-1"
)
@Slf4j
public class RocketMqTemplateConsumer implements RocketMQListener<MessageExt>, RocketMQPushConsumerLifecycleListener {
    @SneakyThrows
    @Override
    public void prepareStart(DefaultMQPushConsumer consumer) {
        log.info("------RocketMqTemplateConsumer prepareStart------");
        consumer.setConsumerGroup("annotation-consumerGroup-1");
        consumer.subscribe("template-topic-1", "*");
        // 手动在这里注册MessageListener, 进行更细粒度的操作, 但是没必要, 这样写还不如不用注解
        // 如果真的需要细粒度, 直接使用原生api即可
        consumer.registerMessageListener(new MessageListenerConcurrently() {
            @Override
            public ConsumeConcurrentlyStatus consumeMessage(List<MessageExt> msgs, ConsumeConcurrentlyContext context) {
                log.info("------消费消息 [{}]------", "template-topic-1");
                log.info("msgs: {}", msgs);
                log.info("------消费消息 [{}] end------", "template-topic-1");
                return ConsumeConcurrentlyStatus.CONSUME_SUCCESS;
            }
        });
        log.info("------RocketMqTemplateConsumer prepareStart end------");
    }

    /**
     * spring 提供的默认消费方法, ConsumeConcurrentlyStatus已经有spring默认处理
     * 需要手动控制ConsumeConcurrentlyStatus, 直接使用原生api
     */
    @Override
    public void onMessage(MessageExt message) {
        log.info("------消费消息 onMessage [{}]------", "template-topic-1");
        log.info("msgs: {}", message);
        log.info("------消费消息 onMessage [{}] end------", "template-topic-1");
    }
}
```

#### @RocketMQTransactionListener

```java
@Component
@RocketMQTransactionListener(
        txProducerGroup = "transaction-producerGroup-template-1"
)
@Slf4j
public class RocketMqTransactionListener implements RocketMQLocalTransactionListener {
    @Override
    public RocketMQLocalTransactionState executeLocalTransaction(Message msg, Object arg) {
        log.info("------RocketMqTransactionListener 执行本地事务------");
        log.info("------RocketMqTransactionListener 执行本地事务 end------");
        return RocketMQLocalTransactionState.COMMIT;
    }

    @Override
    public RocketMQLocalTransactionState checkLocalTransaction(Message msg) {
        log.info("------RocketMqTransactionListener 检查本地事务------");
        log.info("------RocketMqTransactionListener 检查本地事务 end------");
        return RocketMQLocalTransactionState.COMMIT;
    }
}
```

```java
@Component
@RocketMQMessageListener(
        consumerGroup = "annotation-transaction-consumerGroup-1",
        topic = "template-transaction-topic-1"
)
@Slf4j
public class RocketMqTransactionConsumer implements RocketMQListener<MessageExt> {
    @Override
    public void onMessage(MessageExt message) {
        log.info("------RocketMqTransactionConsumer 消费消息------");
        log.info("msg: {}", message);
        log.info("------RocketMqTransactionConsumer 消费消息 end------");
    }
}
```