# Mycat

> 数据库分库分表、水平扩展、垂直拆分工具。
>
> 详细配置使用参考黑马Mysql文档

## 主键生成策略

> mycat默认主键, 不支持自增, 需要手动指定主键。通过配置主键生成策略以支持主键自动生成。

配置server.xml

```xml
<!-- 
配置主键生成策略:
1=本地文件方式：使用服务器本地磁盘文件的方式
2=本地时间戳方式：使用时间戳方式
3=数据库方式：使用数据库的方式
4=zookeeper：使用zookeeper生成id
-->
<property name="sequnceHandlerType">2</property>
```

这里只演示一下最简单的本地时间戳方式, 生产环境考虑使用雪花算法。

配置schema.xml

```xml
<schema name="itcast" checkSQLschema="false" sqlMaxLimit="100" randomDataNode="dn1">

<!-- 需要指定primaryKey，并开启autoIncrement --->
<table name="tb_logger" dataNode="dn4,dn5,dn6" 
splitTableNames ="true" rule="sharding-by-murmur"
primaryKey="id" autoIncrement="true"/>

</schema>
```

测试sql

```sql
create table TB_LOGGER(
id int primary key auto_increment,
content nvarchar(100) not null
);

insert into TB_LOGGER(content) values('新日志');
```
