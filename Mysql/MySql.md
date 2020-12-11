# MySql

## 了解数据库和表

- 创建Schema(数据源)
  - 使用`create schema :[your schema name];`	创建数据源(数据库)
- 切换当前数据源
  - 使用use schema切换当前数据源

## MySql命令行基础show命令

- `show schemas` 显示所有数据源
- `show tables` 显示当前数据源里的所有表
- `show columns from :[table name]`  显示指定表中的所有列信息
  - `describe :[table name]`是上面的简单写法
- `show status`显示服务器的状态信息
- `show grants`显示授权用户的安全信息
- `show errors` `show wranings` 显示服务器的错误和警告

## 表的检索

- select column,..... from :[table name]检索数据
- select * from :[table name]; 通配符检索数据

### limt限制结果

select * from psn limt 2;	表示直接截取不多于两条数据

select * from psn limt 2,2	表示从第二条数据开始截取两条数据

## 数据排序

### order by

select * from psn order by id,name	按照id,name排序, 优先按照id排序, 在id相同的情况下按照name排序

默认排序是升序asc

order by colunm asc||desc

asc升序

desc降序

