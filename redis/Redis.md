# Redis

## redis 类型系统

redis 以kv方式存储数据, key 没有类型, 可以理解为就是一个字符串, value有类型, 可以以不同方式存储数据

### 常用类型

| type        | describe           |
| ----------- | ------------------ |
| string      | 字符串类型         |
| hashes      | HashMap kv映射类型 |
| lists       | 有序线性列表       |
| sets        | 无序去重列表       |
| sorted sets | 有序去重列表       |

### Strings

#### get

`GET key`

getrange

`GETRANGE key start end`

获取key从start到end位置上的value

返回给定key的value

#### set

`set key value [EX seconds|PX milliseconds] [NX|XX] [KEEPTTL]`

ex 设置过期时间以秒为单位

px 设置过期事件以毫秒为单位

nx 不存在的时候才会set

xx 存在的时候才会set

#### mset

`MSET key value [key value ...]`

一次性set多个值

#### strlen

`STRLEN key`

获取给定key的长度

#### getset

`GETSET key value`

先获取value, 并设置新的值, 返回之前获取的value

#### append

`APPEND key value`

向指定key上追加值, 如果key不存在就创建

#### setrange

`SETRANGE key offset value`

将给定key, offset位置向后strlen(value)长度改为value

## Redis 代理 集群 分区 主从 等

**详细见官网**

**[redis.cn](http://redis.cn)**

