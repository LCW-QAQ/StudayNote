# Spark

> spark是一个适用于大规模数据处理的统一分析引擎
>
> spark是一个计算引擎，需要依赖于hadoop，数据存储在hdfs中，由于spark是基于内存的性能远高于MapReduce，可以替代MR。

## Spark角色

* master
    * 集群主节点，负责整个集群的资源调度（类似于yarn中的ResourceManager）
* woker
    * 负责单节点的资源调度（类似于yarn中的NodeManager）
* driver
    * 负责每个任务的资源调度（类似于yarn中的ApplicationMaster）
* executor
    * 具体计算任务的进程（类似于yarn分配的容器里的maptask）

## 部署

spark往往是与hadoop配套使用，请先搭建hadoop运行环境。

### anaconda pyspark

后续操作使用pyspark, 首先安装去anaconda官网下载安装脚本，安装anaconda环境。

安装成功，重新连接linux，控制台前面显示`(base)`即成功。



配置anaconda国内源

```
channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  msys2: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  bioconda: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  menpo: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  pytorch: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud
```



创建虚拟环境

```bash
# 创建虚拟环境 pyspark, 基于Python 3.8
conda create -n pyspark python=3.8
# 切换到虚拟环境内
conda activate pyspark
# 在虚拟环境内安装pyspark
pip install pyspark -i https://pypi.tuna.tsinghua.edu.cn/simple 
```

### 部署spark

[下载spark](https://spark.apache.org/downloads.html)，这里使用的是spark3.2

解压spark软件包

配置全局环境变量

/etc/profile

```bash
export JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
# 运行pyspark程序时需要配置, 这里配置为anaconda的pyspark虚拟环境
export PYSPARK_PYTHON=/opt/anaconda3/envs/pyspark/bin/python3.8
# 配置spark软件根目录
export SPARK_HOME=/opt/spark
```

linux bash启动时，不会执行/etc/profile中的环境变量，在`/.bashrc`中添加`. /etc/profile`，使bash启动时执行`/etc/profile`中export的变量。

#### Local

> spark本地模式，在一个spark进程中开启多个线程模拟spark运行环境。
>
> 该模式下，由于只有一个进程，driver与woker是同一身份，都在一个进程内，executor对应多个线程。

运行`$SPARK_HOME/bin/pyspark`

```python
# 执行pyspark代码
sc.parallelize([1,2,3,4,5]).map(lambda x: x + 1).collect()
```

##### WebUI

spark提供了两个WebUI，默认是`8080`、`4040`分别是spark主节点监控页面、spark当前正在运行的spark任务的监控页面。

主节点`8080`的页面是唯一的，而`4040`是spark任务的job页面，如果开启多个spark任务4040`端口被占用端口，新的端口号会顺延。

主节点`8080`端口被占用同样会顺延。

##### spark-submit

作用: 提交指定的Spark代码到Spark环境中运行


使用方法:


```shell
# 语法
bin/spark-submit [可选的一些选项] jar包或者python代码的路径 [代码的参数]

# 示例
bin/spark-submit /opt/spark/examples/src/main/python/pi.py 10
# 此案例 运行Spark官方所提供的示例代码 来计算圆周率值.  后面的10 是主函数接受的参数, 数字越高, 计算圆周率越准确.
```

#### StandAlone

> Spark提供了集群部署模式，如果有足够多的集群资源，可以单独搭建StandAlone模式的spark集群。



新角色 历史服务器

历史服务器不是Spark环境的必要组件, 是可选的.

回忆: 在YARN中 有一个历史服务器, 功能: 将YARN运行的程序的历史日志记录下来, 通过历史服务器方便用户查看程序运行的历史信息.



Spark的历史服务器, 功能: 将Spark运行的程序的历史日志记录下来, 通过历史服务器方便用户查看程序运行的历史信息.

搭建集群环境, 我们一般`推荐将历史服务器也配置上`, 方面以后查看历史记录



##### 集群规划

cdh1 spark worker节点

cdh2 spark主节点

##### anaconda环境

所有机器安装anaconda，并配置pyspark虚拟环境。

##### 配置文件

来到`$SPARK_HOME/conf`配置目录下



配置workers

改名, 去掉后面的.template后缀

`cp workers.template workers`

编辑workers文件

```bash
# 将里面的localhost删除, 追加
node1
node2
node3
```



配置`spark-env.sh`

`cp spark-env.sh.template spark-env.sh`

编辑`spark-env.sh`

```bash
# 设置JAVA安装目录
JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera

# HADOOP软件配置文件目录，读取HDFS上文件和运行YARN集群
HADOOP_CONF_DIR=/etc/hadoop/conf
YARN_CONF_DIR=/etc/hadoop/conf

# 指定spark老大Master的IP和提交任务的通信端口
# 告知Spark的master运行在哪个机器上
# export SPARK_MASTER_HOST=cdh2
# 告知sparkmaster的通讯端口
export SPARK_MASTER_PORT=7077
# 告知spark master的 webui端口
SPARK_MASTER_WEBUI_PORT=8080

# worker cpu可用核数
SPARK_WORKER_CORES=1
# worker可用内存
SPARK_WORKER_MEMORY=1g
# worker的工作通讯地址
SPARK_WORKER_PORT=7078
# worker的 webui地址
SPARK_WORKER_WEBUI_PORT=8081

# 设置历史服务器
# 配置的意思是  将spark程序运行的历史日志 存到hdfs的/sparklog文件夹中
SPARK_HISTORY_OPTS="-Dspark.history.fs.logDirectory=hdfs://cdh1:8020/sparklog/ -Dspark.history.fs.cleaner.enabled=true"
```



注意，上面的配置的路径 要根据你自己机器实际的路径来写。

在HDFS上创建程序运行历史记录存放的文件夹：

```bash
hadoop fs -mkdir /sparklog
hadoop fs -chmod 777 /sparklog
```



配置`spark-defaults.conf`文件

`cp spark-defaults.conf.template spark-defaults.conf`

```
# 2. 修改内容, 追加如下内容
# 开启spark的日期记录功能
spark.eventLog.enabled 	true
# 设置spark日志记录的路径
spark.eventLog.dir	 hdfs://node1:8020/sparklog/ 
# 设置spark日志是否启动压缩
spark.eventLog.compress 	true
```



配置log4j.properties 文件 [可选配置]

`cp log4j.properties.template log4j.properties`

```properties
log4j.rootCategory=WARN, console
```

这个文件的修改不是必须的,  为什么修改为WARN. 因为Spark是个话痨

会疯狂输出日志, 设置级别为WARN 只输出警告和错误日志, 不要输出一堆废话.



使用rsync将配置分发到其他服务器

##### 启动Spark

启动历史服务器

`$SPARK_HOME/sbin/start-history-server.sh`

启动Spark主节点

`$SPARK_HOME/sbin/start-master.sh`

启动Woker节点

`$SPARK_HOME/sbin/start-worker.sh`



全部启动/关闭

`$SPARK_HOME/sbin/start-all.sh`

`$SPARK_HOME/sbin/stop-all.sh`

##### 连接StandAlone集群

pyspark

```bash
# 通过--master选项来连接到 StandAlone集群
# 如果不写--master选项, 默认是local模式运行
pyspark --master spark://node1:7077
```

spark-shell

```bash
# 同样适用--master来连接到集群使用
spark-shell --master spark://node1:7077
```

```scala
// 测试代码
sc.parallelize(Array(1,2,3,4,5)).map(x=> x + 1).collect()
```

spark-submit

```bash
spark-submit --master spark://node1:7077 /opt/spark/examples/src/main/python/pi.py 100
# 同样使用--master来指定将任务提交到集群运行
```

#### StandAlone HA

> 前提: 确保Zookeeper 和 HDFS 均已经启动



先在`spark-env.sh`中, 删除: `SPARK_MASTER_HOST=node1`


原因: 配置文件中固定master是谁, 那么就无法用到zk的动态切换master功能了.


在`spark-env.sh`中, 增加:


```shell
SPARK_DAEMON_JAVA_OPTS="-Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=node1:2181,node2:2181,node3:2181 -Dspark.deploy.zookeeper.dir=/spark-ha"
# spark.deploy.recoveryMode 指定HA模式 基于Zookeeper实现
# 指定Zookeeper的连接地址
# 指定在Zookeeper中注册临时节点的路径
```

将spark-env.sh 分发到每一台服务器上


停止当前StandAlone集群


```shell
sbin/stop-all.sh
```


启动集群:


```shell
# 在node1上 启动一个master 和全部worker
sbin/start-all.sh

# 注意, 下面命令在node2上执行
sbin/start-master.sh
# 在node2上启动一个备用的master进程
```

![spark_ha_img1](Spark.assets/spark_ha_img1.png)

![spark_ha_img2.png](Spark.assets/spark_ha_img2.png.png)

**Spark master主备切换**


提交一个spark任务到当前`alive`master上:


```shell
spark-submit --master spark://node1:7077 /opt/spark/examples/src/main/python/pi.py 1000
```


在提交成功后, 将alivemaster直接kill掉

不会影响程序运行:
![spark_ha_img3](Spark.assets/spark_ha_img3-16562442630771.png)
当新的master接收集群后, 程序继续运行, 正常得到结果.


> 结论 HA模式下, 主备切换 不会影响到正在运行的程序.
>
> 最大的影响是 会让它中断大约30秒左右.

#### Yarn

确保spark-env.sh配置文件中有以下配置:


- HADOOP_CONF_DIR
- YARN_CONF_DIR



pyspark

> client模式driver运行在客户端
>
> cluster模式driver运行在yarn分配的ApplicationMaster上

```bash
# --deploy-mode 选项是指定部署模式, 默认是 客户端模式
# client就是客户端模式
# cluster就是集群模式
# --deploy-mode 仅可以用在YARN模式下
pyspark --master yarn --deploy-mode client|cluster
```

> 注意: 交互式环境 pyspark  和 spark-shell  无法运行 cluster模式



spark-submit

```bash
spark-submit --master yarn --deploy-mode client|cluster /opt/spark/examples/src/main/python/pi.py 10
```

### pyspark与spark-submit

常见的客户端工具：


- pyspark: pyspark解释器spark环境
- spark-shell: scala解释器spark环境
- spark-submit: 提交jar包或Python文件执行的工具
- spark-sql: sparksql客户端工具

这4个客户端工具的参数基本通用.

以spark-submit 为例：

```
Usage: spark-submit [options] <app jar | python file | R file> [app arguments]
Usage: spark-submit --kill [submission ID] --master [spark://...]
Usage: spark-submit --status [submission ID] --master [spark://...]
Usage: spark-submit run-example [options] example-class [example args]

Options:
  --master MASTER_URL         spark://host:port, mesos://host:port, yarn,
                              k8s://https://host:port, or local (Default: local[*]).
  --deploy-mode DEPLOY_MODE   部署模式 client 或者 cluster 默认是client
  --class CLASS_NAME          运行java或者scala class(for Java / Scala apps).
  --name NAME                 程序的名字
  --jars JARS                 Comma-separated list of jars to include on the driver
                              and executor classpaths.
  --packages                  Comma-separated list of maven coordinates of jars to include
                              on the driver and executor classpaths. Will search the local
                              maven repo, then maven central and any additional remote
                              repositories given by --repositories. The format for the
                              coordinates should be groupId:artifactId:version.
  --exclude-packages          Comma-separated list of groupId:artifactId, to exclude while
                              resolving the dependencies provided in --packages to avoid
                              dependency conflicts.
  --repositories              Comma-separated list of additional remote repositories to
                              search for the maven coordinates given with --packages.
  --py-files PY_FILES         指定Python程序依赖的其它python文件
  --files FILES               Comma-separated list of files to be placed in the working
                              directory of each executor. File paths of these files
                              in executors can be accessed via SparkFiles.get(fileName).
  --archives ARCHIVES         Comma-separated list of archives to be extracted into the
                              working directory of each executor.

  --conf, -c PROP=VALUE       手动指定配置
  --properties-file FILE      Path to a file from which to load extra properties. If not
                              specified, this will look for conf/spark-defaults.conf.

  --driver-memory MEM         Driver的可用内存(Default: 1024M).
  --driver-java-options       Driver的一些Java选项
  --driver-library-path       Extra library path entries to pass to the driver.
  --driver-class-path         Extra class path entries to pass to the driver. Note that
                              jars added with --jars are automatically included in the
                              classpath.

  --executor-memory MEM       Executor的内存 (Default: 1G).

  --proxy-user NAME           User to impersonate when submitting the application.
                              This argument does not work with --principal / --keytab.

  --help, -h                  显示帮助文件
  --verbose, -v               Print additional debug output.
  --version,                  打印版本

 Cluster deploy mode only(集群模式专属):
  --driver-cores NUM          Driver可用的的CPU核数(Default: 1).

 Spark standalone or Mesos with cluster deploy mode only:
  --supervise                 如果给定, 可以尝试重启Driver

 Spark standalone, Mesos or K8s with cluster deploy mode only:
  --kill SUBMISSION_ID        指定程序ID kill
  --status SUBMISSION_ID      指定程序ID 查看运行状态

 Spark standalone, Mesos and Kubernetes only:
  --total-executor-cores NUM  整个任务可以给Executor多少个CPU核心用

 Spark standalone, YARN and Kubernetes only:
  --executor-cores NUM        单个Executor能使用多少CPU核心

 Spark on YARN and Kubernetes only(YARN模式下):
  --num-executors NUM         Executor应该开启几个
  --principal PRINCIPAL       Principal to be used to login to KDC.
  --keytab KEYTAB             The full path to the file that contains the keytab for the
                              principal specified above.

 Spark on YARN only:
  --queue QUEUE_NAME          指定运行的YARN队列(Default: "default").
```

### 注意事项

1. 使用yarn模式运行时，出现

## Spark

### RDD

https://spark.apache.org/docs/latest/rdd-programming-guide.html

### SparkSQL

https://spark.apache.org/docs/latest/sql-programming-guide.html

### 简单演示

#### 客户端

spark提供了两种客户端用法，早期使用rdd编程时的SparkContext和SparkSQL出现后的SparkSession

SparkContext支持RDD方式编程，SparkSession支持RDD与SQL

SparkContext

```python
from pyspark import SparkConf, SparkContext

if __name__ == '__main__':
    conf = SparkConf().setAppName("SparkConfApp").setMaster("local[*]")
    sc = SparkContext(conf=conf)

	print(sc.parallelize([1, 2, 3]).sum())
```

SparkSession

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext
    print(sc.parallelize([1, 2, 3]).sum())
```

### 算子简单演示

#### join

```python
from pyspark import SparkConf, SparkContext

if __name__ == '__main__':
    conf = SparkConf().setAppName("SparkConfApp").setMaster("local[*]")
    sc = SparkContext(conf=conf)

    rdd1 = sc.parallelize([
        (1001, "ZhangSan"), (1001, "LiSi"), (1002, "City"), (1003, "Cooker"), (1111, "XiaoMing")
    ])
    rdd2 = sc.parallelize([
        (1001, "销售部"), (1002, "开发部"), (1003, "人事部"), (1004, "财务")
    ])

    print(rdd1.join(rdd2).collect())
    print(rdd1.leftOuterJoin(rdd2).collect())
    print(rdd1.rightOuterJoin(rdd2).collect())
    print(rdd1.fullOuterJoin(rdd2).collect())
```

#### groupby

```python
import operator
from pyspark import SparkConf, SparkContext

if __name__ == '__main__':
    conf = SparkConf().setAppName("SparkConfApp").setMaster("local[*]")
    sc = SparkContext(conf=conf)

    rdd = sc.parallelize([("a", 1), ("a", 1), ("b", 1), ("a", 1), ("b", 1)])
    print(rdd.groupBy(lambda x: x[0]).map(lambda x: (x[0], list(x[1]))).collect())
```

### DataFrame API简单演示

#### 创建DF

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext

    rdd = sc.textFile("/user/root/test_data/sql/people.txt") \
        .map(lambda x: x.split(",")) \
        .map(lambda x: (x[0], int(x[1])))

    # df = spark.createDataFrame(rdd, schema=["name", "age"])
    # schema = StructType().add("name", StringType(), nullable=True) \
    #     .add("age", IntegerType(), nullable=True)
    # df = spark.createDataFrame(rdd, schema=schema)

    # df = rdd.toDF(schema=["name", "age"])
    df = rdd.toDF(schema=StructType().add("name", StringType(), True) \
                  .add("age", IntegerType(), True))
    df.printSchema()
    df.show()

    df.createOrReplaceTempView("people")

    spark.sql("select * from people where age > 20").show()
```

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
import pyspark.pandas as pd

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    df = spark.read.parquet("/user/root/test_data/sql/users.parquet")
    df.printSchema()
    df.show()
```

#### Sogou搜索统计

```python
import jieba
from pyspark import SparkConf, SparkContext, StorageLevel
import operator


def parse_words(word):
    return list(jieba.cut_for_search(word))


def parse_user_with_words(args):
    uid = args[0]
    phrase = args[1]
    words = list(jieba.cut_for_search(phrase))
    return [(f"{uid}_{x}", 1) for x in words if x not in ["谷", "帮", "客"]]


if __name__ == '__main__':
    # conf = SparkConf().setMaster("local[*]").setAppName("SparkHelloWorld")
    conf = SparkConf().setAppName("SparkHelloWorld")
    sc = SparkContext(conf=conf)

    rdd = sc.textFile("/user/root/test_data/SogouQ.txt")

    split_rdd = rdd.map(lambda x: x.split())
    split_rdd.persist(StorageLevel.DISK_ONLY)

    # split_rdd.takeSample(3, True)
    phrase_rdd = split_rdd.map(lambda x: x[2])

    words_rdd = phrase_rdd.flatMap(parse_words)

    filtered_rdd = words_rdd.filter(lambda x: x not in ["谷", "帮", "客"]) \
        .map(lambda x: ({"传智播": "传智播客", "院校": "院校帮", "博学": "博学谷"}.get(x, x), 1))

    print(filtered_rdd.reduceByKey(operator.add) \
          .takeOrdered(5, lambda x: -x[1]))

    user_with_word_rdd = split_rdd.map(lambda x: (x[1], x[2]))

    user_with_words_rdd = user_with_word_rdd.flatMap(parse_user_with_words)
    print(user_with_words_rdd.reduceByKey(operator.add) \
          .takeOrdered(5, lambda x: -x[1]))

    time_rdd = split_rdd.map(lambda x: x[0])
    hour_rdd = time_rdd.map(lambda x: (x.split(":")[0], 1))
    print(hour_rdd.reduceByKey(operator.add) \
          .takeOrdered(5, lambda x: -x[1]))
```

#### SQL WordCount

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext
    rdd = sc.textFile("/user/root/test_data/words.txt") \
        .flatMap(lambda x: x.split()) \
        .map(lambda x: [x])

    df = rdd.toDF(["word"])
    df.createTempView("words")

    spark.sql("""
    select word, count(*) as cnt from words group by word order by cnt desc
    """).show()

    df = spark.read.text("/user/root/test_data/words.txt")
    df2 = df.withColumn("value", F.explode(F.split(df["value"], " ")))
    df2.groupby("value") \
        .count() \
        .withColumnRenamed("value", "word") \
        .withColumnRenamed("count", "cnt") \
        .orderBy("cnt", ascending=False) \
        .show()
```

#### MovieDemo

```python
import time

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F
import pyspark.pandas as pd

if __name__ == '__main__':
    # 设置sql的分区数,  该分区数与rdd中设置的并行度是独立的
    # config("spark.sql.shuffle.partitions", 2) \
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .config("spark.sql.shuffle.partitions", 3) \
        .getOrCreate()

    df = spark.read.csv("/user/root/test_data/sql/u.data",
                        schema=StructType().add("user_id", StringType(), True)
                        .add("movie_id", IntegerType(), True)
                        .add("rank", IntegerType(), True)
                        .add("ts", StringType(), True),
                        encoding="utf8", sep="\t", header=False)

    # 每个人打分的平均分
    df.groupby("user_id") \
        .avg("rank") \
        .withColumnRenamed("avg(rank)", "avg_rank") \
        .withColumn("avg_rank", F.round("avg_rank", 2)) \
        .orderBy("avg_rank", ascending=False) \
        .show()

    # 每个电影的平均分
    df.createTempView("movie")
    spark.sql("""
    with q1 as (
    select movie_id, round(avg(rank)) as avg_rank from movie group by movie_id order by avg_rank desc
    )
    select * from q1
    """).show()

    print(f'大于平均分的电影的数量: {df.where(df["rank"] > df.select(F.avg(df["rank"])).first()["avg(rank)"]).count()}')

    # 查询高分电影中(>3分),打分次数最多的用户,此用户打分的平均分
    user_id = df.where(df["rank"] > 3) \
        .groupby("user_id") \
        .count() \
        .withColumnRenamed("count", "cnt") \
        .orderBy("cnt", ascending=False) \
        .limit(1) \
        .first()["user_id"]

    df.filter(f"user_id == {user_id}") \
        .select(F.round(F.avg("rank"), 2)) \
        .show()

    # 查询用户的平均打分, 最低打分, 最高打分
    df.groupby("user_id") \
        .agg(F.round(F.avg("rank"), 2).alias("avg_rank"),
             F.max("rank").alias("max_rank"),
             F.min("rank").alias("min_rank")) \
        .show()

    # 查询评分超过100次的电影的平均分, 排名top10
    spark.sql("""
    with q1 as (
        select
            movie_id, count("movie_id") cnt, round(avg(rank), 2) avg_rank
        from movie
        group by movie_id
        having cnt >= 100
        order by avg_rank desc
        limit 10
    )
    select * from q1;
    """).show()
```

### 文件读写

```python
from pyspark import SparkConf
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    # 按照csv方式读取
    df = spark.read.csv("/user/root/test_data/sql/u.data",
                        schema=StructType().add("user_id", StringType(), True)
                        .add("movie_id", IntegerType(), True)
                        .add("rank", IntegerType(), True)
                        .add("ts", StringType(), True),
                        encoding="utf8", sep="\t", header=False)
	"""
	mode写入模式
	error 文件已存在报错, 默认
	append 文件存在追加
	overwrite 文件已存在覆盖
	ignore 文件存在不做任何操作
	"""
    
    # 写入文本文件(只能是单列表)
    df.select(F.concat_ws(",", "user_id", "movie_id", "rank", "ts")).write.mode("overwrite") \
        .format("text") \
        .save("/user/root/test_data/text_output")
    
    df.write.mode("overwrite") \
        .option("sep", ",") \
        .format("csv") \
        .save("/user/root/test_data/csv_output")
    
    df.write.mode("overwrite") \
        .format("json") \
        .save("/user/root/test_data/json_output")
    
    df.write.mode("overwrite") \
        .format("parquet") \
        .save("/user/root/test_data/parquet_output")

    df.printSchema()
    df.show()

    # 写入到数据库时, 需要将连接启动上传到服务器的spark安装目录下的jars中
    df.write.mode("overwrite") \
        .format("jdbc") \
        .option("url", "jdbc:mysql://cdh1:3306/test?useUnicode=true&characterEncoding=utf-8") \
        .option("driver", "com.mysql.jdbc.Driver") \
        .option("user", "root") \
        .option("password", "000000") \
        .option("dbtable", "movie_table") \
        .save()

    df = df.read.format("jdbc") \
        .option("url", "jdbc:mysql://cdh1/test?useUnicode=true&characterEncoding=utf-8") \
        .option("user", "root") \
        .option("password", "000000") \
        .option("dbtable", "movie_table") \
        .load()
```

### 自定义函数

> pyspark只能定义udf函数，可以通过mapPartitions模拟udaf函数，无法定义udtf函数，spark目前只支持使用scala或java定义udtf函数。

#### udf

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext

    rdd = sc.parallelize([1, 2, 3, 4])
    df = rdd.map(lambda x: [x]).toDF(["num"])

    # 使用spark.udf方式注册,可以在sql中使用
    udf1 = spark.udf.register("udf1", lambda x: x * 10, "int")

    df.select(udf1(df["num"])).show()
    df.selectExpr("udf1(num)").show()
	
    # 使用spark.sql.functions定义,只能在rdd中定义
    udf2 = F.udf(lambda x: x * 100, "int")
    df.select(udf2(df["num"])).show()
```

udf函数返回数组

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType, ArrayType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext
    df = sc.parallelize(["hell hadoop", "spark flink"]).map(lambda x: [x]).toDF(["content"])
    udf1 = spark.udf.register("udf1", lambda x: x.split(), ArrayType(StringType()))

    df.select(udf1(df["content"])).show()
    df.selectExpr("udf1(content)").show()
    df.createTempView("contents")
    spark.sql("""
    select udf1(content) from contents
    """).show()

    udf2 = F.udf(lambda x: x.split(), ArrayType(StringType()))
    df.select(udf2(df["content"])).show()
```

udf函数返回结构体

```python
import string

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType, ArrayType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext
    df = sc.parallelize([1, 2, 3]).map(lambda x: [x]).toDF(["num"])
    udf1 = spark.udf.register("udf1", lambda x: {"num": x, "letter": string.ascii_letters[x]},
                              StructType().add("num", "integer")
                              .add("letter", "string"))
    df.select(udf1(df["num"])).show()
    df.selectExpr("udf1(num)").show()
```

#### udaf

> 通过mapPartitions模拟udaf函数

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext
    df = sc.parallelize([1, 2, 3, 4]).map(lambda x: [x]).toDF(["num"])


    # 模拟sum函数
    def process(rows):
        num = 0
        for row in rows:
            num += row["num"]
        return [num]


    # 模拟udaf聚合函数操作
    print(df.rdd.repartition(1).mapPartitions(process) \
          .collect())
```

### 共享变量与累加变量

在spark中想要共享python变量，需要使用broadcast广播该变量

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext

    # 记录了职业
    occs = sc.broadcast([(1001, "cooker"), (1002, "students"), (1003, "teacher")])

    rdd = sc.parallelize([
        (1001, "ZhangSan"),
        (1002, "WangWu"),
        (1003, "LiSi"),
    ], 3)


    def process(x):
        item = [i for i in occs.value if i[0] == x[0]]
        if item:
            return x[0], (x[1], item[0][1])
        return x[0], (x[1], None)


    print(rdd.map(process).collect())
```

在spark中想要共享python变量且累加，需要使用累加变量

```python
from pyspark import SparkConf, SparkContext

if __name__ == '__main__':
    conf = SparkConf().setMaster("local[*]").setAppName("SparkHelloWorld")
    sc = SparkContext(conf=conf)

    # 被广播的变量是只读的,不能修改
    # count = sc.broadcast(0)
    # 创建全局共享的累加变量
    count = sc.accumulator(0)


    def foo():
        global count
        count += 1
        print(count)


    rdd = sc.parallelize([1, 2, 3, 4], 2)
    rdd2 = rdd.map(lambda x: foo())
    rdd2.cache()

    print(rdd2.collect())
    print(rdd2.collect())
    print(count)
```

### 窗口函数

```python
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql.window import Window
from pyspark.sql import functions as F

if __name__ == '__main__':
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .getOrCreate()

    sc = spark.sparkContext

    df = sc.parallelize([
        (1001, 0),
        (1001, 2),
        (1001, 1),
        (1003, 12),
        (1004, 11),
    ]).toDF("id int, score int")
    df.createTempView("scores")
    spark.sql("""
    select id, score, sum(score) over(partition by id order by score) as accumulator_sum from scores
    """).show()

    w = Window().partitionBy("id").orderBy("score")
    df.select(["id", "score", F.sum("score").over(w).alias("accumulator_sum")]).show()
```

## SparkOnHive

> Spark通过Hive Metastore做hdfs上的hive表数据
>
> 还有一个HiveOnSpark, 将hive sql转换成spark的rdd运行, 将spark作为执行引擎速度上远快于MR程序.

spark配置

在spark安装目录下的conf文件夹中配置`hive-site.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>

<configuration>
  <!-- 指定hive metastore uri -->
  <property>
    <name>hive.metastore.uris</name>
    <value>thrift://cdh2:9083</value>
  </property>
  <!-- 指定hive数据库的目录 -->
  <property>
    <name>hive.metastore.warehouse.dir</name>
    <value>/user/hive/warehouse</value>
  </property>
</configuration>
```

配置并开启hive metastore即可

测试pyspark

`$SPARK_HOME/bin/pyspark`进入pyspark交互环境

`spark.sql("show databases;")`

测试spark-sql

`$SPARK_HOME/bin/spark-sql`进入spark-sql交互环境

`show databases;`



在pyspark程序中配置

```python
# coding: utf-8

from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StringType, IntegerType
from pyspark.sql import functions as F

if __name__ == '__main__':
    # 如果配置了$SPARK_HOME/conf下的hive-site.xml下面就不需要配置了, 只需要enableHiveSupport开启hive
    spark = SparkSession.builder \
        .appName("test") \
        .master("local[*]") \
        .config("spark.sql.warehouse.dir", "hdfs://cdh1:8020/user/hive/warehouse") \
        .config("hive.metastore.uris", "thrift://cdh2:9083") \
        .enableHiveSupport() \
        .getOrCreate()

    spark.sql("""
        show databases; 
        """).show()
```

## SparkThrift

> Spark ThriftServer提供的Sql服务, 兼容hiveserver2协议, 直接使用hive客户端连接即可.

启动spark-thriftserver

````bash
$SPARK_HOME/sbin/start-thriftserver.sh \
--hiveconf hive.server2.thrift.port=10001 \
--hiveconf hive.server2.thrift.bind.host=cdh2 \
--master local[*]
````
