# Sqoop

## 常用命令

| 参数                                                         | 说明                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| --connect                                                    | 连接关系型数据库的URL                                        |
| --username                                                   | 连接数据库的用户名                                           |
| --password                                                   | 连接数据库的密码                                             |
| --driver                                                     | JDBC的driver class                                           |
| --query或--e <statement>                                     | 将查询结果的数据导入，使用时必须伴随参--target-dir，--hcatalog-table，如果查询中有where条件，则条件后必须加上$CONDITIONS关键字。  如果使用双引号包含sql，则$CONDITIONS前要加上\以完成转义：\$CONDITIONS |
| --hcatalog-database                                          | 指定HCatalog表的数据库名称。如果未指定，default则使用默认数据库名称。提供 --hcatalog-database不带选项--hcatalog-table是错误的。 |
| --hcatalog-table                                             | 此选项的参数值为HCatalog表名。该--hcatalog-table选项的存在表示导入或导出作业是使用HCatalog表完成的，并且是HCatalog作业的必需选项。 |
| --create-hcatalog-table                                      | 此选项指定在导入数据时是否应自动创建HCatalog表。表名将与转换为小写的数据库表名相同。 |
| --hcatalog-storage-stanza 'stored as orc  tblproperties ("orc.compress"="SNAPPY")' \ | 建表时追加存储格式到建表语句中，tblproperties修改表的属性，这里设置orc的压缩格式为SNAPPY |
| -m                                                           | 指定并行处理的MapReduce任务数量。  -m不为1时，需要用split-by指定分片字段进行并行导入，尽量指定int型。 |
| --split-by id                                                | 如果指定-split by, 必须使用$CONDITIONS关键字, 双引号的查询语句还要加\ |
| --hcatalog-partition-keys  --hcatalog-partition-values       | keys和values必须同时存在，相当于指定静态分区。允许将多个键和值提供为静态分区键。多个选项值之间用，（逗号）分隔。比如：  --hcatalog-partition-keys year,month,day  --hcatalog-partition-values 1999,12,31 |
| --null-string '\\N'  --null-non-string '\\N'                 | 指定mysql数据为空值时用什么符号存储，null-string针对string类型的NULL值处理，--null-non-string针对非string类型的NULL值处理 |
| --hive-drop-import-delims                                    | 设置无视字符串中的分割符（hcatalog默认开启）                 |
| --fields-terminated-by '\t'                                  | 设置字段分隔符                                               |

## Demo

查询指定mysql的所有数据库

```bash
sqoop list-databases --connect jdbc:mysql://192.168.52.150:3306 --username root --password 123456
```

查询指定mysql数据库中的所有表

```bash
sqoop list-tables \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 
```

数据导入到hdfs

```bash
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp
# 说明:
#	默认情况下, 会将数据导入到操作sqoop用户的HDFS的家目录下,在此目录下会创建一个以导入表的表名为名称文件夹, 在此文件夹下莫每一条数据会运行一个mapTask, 数据的默认分隔符号为 逗号

# 指定文件夹，存在就删除
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp \
--delete-target-dir \
--target-dir '/sqoop_works/emp_1'

# 指定maptask数量，需要配合--split-by（指定分割字段）使用
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp \
--delete-target-dir \
--target-dir '/sqoop_works/emp_2' \
--split-by id \
-m 2 

# 指定输出文件的分隔符（当然也可以指定输入分隔符）
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp \
--fields-terminated-by '\001' \
--delete-target-dir \
--target-dir '/sqoop_works/emp_3' \
-m 1 
```

数据导入到hive

```bash
# hive中的表
# create database hivesqoop;
# use hivesqoop;
# create table hivesqoop.emp_add_hive(
#	id  int,
#	hno string,
#	street string,
#	city string
#) 
#row format delimited fields terminated by '\t'
#stored as  orc ;

# 通过hcatalog导入到hive，table指定mysql表，hcatalog系列命令指定hive相关配置
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp_add \
--hcatalog-database hivesqoop \
--hcatalog-table emp_add_hive \
-m 1 
```

数据按条件导入到hive

```bash
# 使用where选项过滤数据
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp \
--where 'id > 1205' \
--delete-target-dir \
--target-dir '/sqoop_works/emp_2' \
--split-by id \
-m 2 

# 通过query选项，指定sql导入数据
# !!!注意使用sql必须在where后面加上$CONDITIONS
# !!!如果SQL语句使用 双引号包裹,  $CONDITIONS前面需要将一个\进行转义, 单引号是不需要的
sqoop import \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--query 'select deg  from emp where 1=1 AND \$CONDITIONS' \
--delete-target-dir \
--target-dir '/sqoop_works/emp_4' \
--split-by id \
-m 1 
```

数据导出到mysql

```bash
# 第一步: 在mysql中创建目标表 (必须创建，不会自动创建)
#create table test.emp_add_mysql(
#	 id     INT  ,
#    hno    VARCHAR(32) NULL,
#    street VARCHAR(32) NULL,
#    city   VARCHAR(32) NULL
#);

# export导出到mysql
sqoop export \
--connect jdbc:mysql://192.168.52.150:3306/test \
--username root \
--password 123456 \
--table emp_add_mysql \
--hcatalog-database hivesqoop \
--hcatalog-table emp_add_hive \
-m 1
# 存在问题: 如果hive中表数据存在中文, 通过上述sqoop命令, 会出现中文乱码的问题
# 连接mysql时，添加参数useUnicode=true&characterEncoding=utf-8，防止乱码
```

