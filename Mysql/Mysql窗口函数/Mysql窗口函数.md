# Mysql窗口函数

> mysql在8.0支持窗口函数

## 什么是窗口函数

窗口函数，也叫OLAP函数（Online Anallytical Processing，联机分析处理），可对数据库数据进行实时分析处理。

一般可用在以下业务需求

排名问题：每个部门按业绩来排名

topN问题：排名前N的员工

聚合函数与专门的窗口函数都可以进行窗口计算

| 名称         | 参数                           | 描述                                                         |
| ------------ | ------------------------------ | ------------------------------------------------------------ |
| ROW_NUMBER   | 否                             | 返回当前行在分组的序号，其结果无论如何都是1、2、3、4、5这样的 |
| DENSE_RANK   | 否                             | DENSE_RANK 各分区的排名，数值相等同一排名，排名连续，1、1、2、3 |
| RANK         | 否                             | RANK 各分区的排名，数值相等同一排名，排名不连续，1、1、3、3、5 |
| PERCENT_RANK | 否                             | 百分比排名: 计算公式  `(rank函数返回的结果-1) / (当前分区总记录数-1)`<br/>百分比计算为什么使用rank函数的结果，而不是DENSE_RANK<br/>可能是DENSE_RANK最后的排名可能不与总记录数相等，这样就不好做百分比计算了（最大值不是100%） |
| CUME_DIST    | 否                             | CUME_DIST函数与PERCENT_RANK类似<br/>PERCENT_RANK求的是`rank()-1 / 分区总记录数-1`<br/>CUME_DIST求的是`<=当前分数的记录数 / 分区总记录数` |
| LAG          | lag(字段，[偏移量，[默认值]])  | 向负方向偏移                                                 |
| LEAD         | lead(字段，[偏移量，[默认值]]) | 向正方向偏移                                                 |
| FIRST_VALUE  | FIRST_VALUE(字段)              | 当前分区的第一条记录                                         |
| LAST_VALUE   | LAST_VALUE(字段)               | 当前分区的第一条记录，默认数据范围是当前行数据与当前行之前的数据 |
| NTH_VALUE    | NTH_VALUE(字段，第N行)         | 显示第N行的指定字段                                          |
| NTILE        | NTILE(最大级别)                | 给当前分区分级，最大num级，记录数不一定被n整除所以分级不一定完全平均.<br/>默认按照order值的大小分级，值越大级别越高<br/>当记录数<=最大级别时，分级是连续的，不会有最大级别 |

## SQL Demo

测试数据

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for tb_customer_shopping
-- ----------------------------
DROP TABLE IF EXISTS `tb_customer_shopping`;
CREATE TABLE `tb_customer_shopping`  (
  `order_id` int NULL DEFAULT NULL COMMENT '订单id',
  `username` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL COMMENT '顾客姓名',
  `create_date` date NULL DEFAULT NULL COMMENT '购买日期',
  `cost` int NULL DEFAULT NULL COMMENT '购买金额'
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tb_customer_shopping
-- ----------------------------
INSERT INTO `tb_customer_shopping` VALUES (1, 'Jack', '2017-01-01', 10);
INSERT INTO `tb_customer_shopping` VALUES (2, 'Tony', '2017-01-02', 15);
INSERT INTO `tb_customer_shopping` VALUES (3, 'Jack', '2017-02-03', 23);
INSERT INTO `tb_customer_shopping` VALUES (4, 'Tony', '2017-01-04', 29);
INSERT INTO `tb_customer_shopping` VALUES (5, 'Jack', '2017-01-05', 46);
INSERT INTO `tb_customer_shopping` VALUES (6, 'Jack', '2017-04-06', 42);
INSERT INTO `tb_customer_shopping` VALUES (7, 'Tony', '2017-01-07', 50);
INSERT INTO `tb_customer_shopping` VALUES (8, 'Jack', '2017-01-08', 55);
INSERT INTO `tb_customer_shopping` VALUES (9, 'King', '2017-04-08', 62);
INSERT INTO `tb_customer_shopping` VALUES (10, 'King', '2017-04-09', 68);
INSERT INTO `tb_customer_shopping` VALUES (11, 'Paul', '2017-05-10', 12);
INSERT INTO `tb_customer_shopping` VALUES (12, 'King', '2017-04-11', 75);
INSERT INTO `tb_customer_shopping` VALUES (13, 'Paul', '2017-06-12', 80);
INSERT INTO `tb_customer_shopping` VALUES (14, 'King', '2017-04-13', 94);

-- ----------------------------
-- Table structure for tb_score
-- ----------------------------
DROP TABLE IF EXISTS `tb_score`;
CREATE TABLE `tb_score`  (
  `stu_id` int NULL DEFAULT NULL,
  `name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `subject` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL DEFAULT NULL,
  `score` int NULL DEFAULT NULL
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of tb_score
-- ----------------------------
INSERT INTO `tb_score` VALUES (1, '孙悟空', '语文', 87);
INSERT INTO `tb_score` VALUES (1, '孙悟空', '数学', 100);
INSERT INTO `tb_score` VALUES (1, '孙悟空', '英语', 68);
INSERT INTO `tb_score` VALUES (2, '唐僧', '语文', 94);
INSERT INTO `tb_score` VALUES (2, '唐僧', '数学', 56);
INSERT INTO `tb_score` VALUES (2, '唐僧', '英语', 84);
INSERT INTO `tb_score` VALUES (3, '沙僧', '语文', 87);
INSERT INTO `tb_score` VALUES (3, '沙僧', '数学', 97);
INSERT INTO `tb_score` VALUES (3, '沙僧', '英语', 84);
INSERT INTO `tb_score` VALUES (4, '八戒', '语文', 65);
INSERT INTO `tb_score` VALUES (4, '八戒', '数学', 85);
INSERT INTO `tb_score` VALUES (4, '八戒', '英语', 78);
INSERT INTO `tb_score` VALUES (5, '蜘蛛侠', '语文', 55);
INSERT INTO `tb_score` VALUES (5, '蜘蛛侠', '数学', 97);
INSERT INTO `tb_score` VALUES (5, '蜘蛛侠', '英语', 98);
INSERT INTO `tb_score` VALUES (6, '美国队长', '语文', 56);
INSERT INTO `tb_score` VALUES (6, '美国队长', '数学', 99);
INSERT INTO `tb_score` VALUES (6, '美国队长', '英语', 87);
INSERT INTO `tb_score` VALUES (7, '钢铁侠', '语文', 94);
INSERT INTO `tb_score` VALUES (7, '钢铁侠', '数学', 100);
INSERT INTO `tb_score` VALUES (7, '钢铁侠', '英语', 85);

SET FOREIGN_KEY_CHECKS = 1;
```

```sql
/* 订单表，记录了name在create_date消费了cost元 */
SELECT
* 
FROM
	tb_customer_shopping;
/* 考试成绩表，记录了name的subject考了score分 */
SELECT
	* 
FROM
	tb_score;
```

### 序号函数

>ROW_NUMBER()、RANK()、DENSE_RANK()

```sql
/*
涉及的窗口函数
ROW_NUMBER 各分区的行号
DENSE_RANK 各分区的排名，数值相等同一排名，排名连续
RANK 各分区的排名，数值相等同一排名，排名不连续
*/
/* 查询每个学生各科的分数与各科分数的排名 */
SELECT
	stu_id 学号,
	NAME 姓名,
	SUBJECT 学科,
	score 分数,
/* 学生分数在当前科目的排名（降序），分数一样优先级随机，按照行号 */
	ROW_NUMBER() OVER ( PARTITION BY SUBJECT ORDER BY score DESC ) AS 'ROW_NUMBER排名',
/* 学生分数在当前科目的排名（降序），分数一样记为同一排名，排名连续 */
	DENSE_RANK() OVER ( PARTITION BY SUBJECT ORDER BY score DESC ) AS 'DENSE_RANK排名',
/* 学生分数在当前科目的排名（降序），分数一样记为同一排名，排名不连续 */
	RANK() OVER ( PARTITION BY SUBJECT ORDER BY score DESC ) AS 'RANK排名' 
FROM
	tb_score ts;
```

### 分布函数

>PERCENT_RANK()、CUME_DIST()

```sql
/* 
查询学号为1的学生，各科目的成绩，并显示该科目在该学生所有考试的科目中的排名与百分比排名
百分比排名: 计算公式  `(rank函数返回的结果-1) / (当前分区总记录数-1)`
百分比计算为什么使用rank函数的结果，而不是DENSE_RANK
可能是DENSE_RANK最后的排名可能不与总记录数相等，这样就不好做百分比计算了（最大值不是100%）

WINDOW w相当于为`AS ( PARTITION BY stu_id ORDER BY score )`取了别名
不取命名的写法:
SELECT
	rank() over ( PARTITION BY stu_id ORDER BY score ) AS rk,
	percent_rank() over ( PARTITION BY stu_id ORDER BY score ) AS prk,
	stu_id 学号,
	NAME 姓名,
	score 分数,
	SUBJECT 科目 
FROM
	tb_score 
WHERE
	stu_id = 1;
*/
SELECT
	RANK() OVER w AS rk AS 排名,
	PERCENT_RANK() OVER w AS 百分比排名,
	stu_id 学号,
	NAME 姓名,
	score 分数,
	SUBJECT 科目 
FROM
	tb_score 
WHERE
	stu_id = 1 WINDOW w AS ( PARTITION BY stu_id ORDER BY score );
```

```sql
/* 
查询唐僧和孙悟空的成绩信息
并分别显示所有成绩中小于等于当前分数的百分比与自己的成绩中小于等于当前分数的百分比
CUME_DIST函数与PERCENT_RANK类似
PERCENT_RANK求的是`rank()-1 / 分区总记录数-1`
CUME_DIST求的是`<=当前分数的记录数 / 分区总记录数`
*/
SELECT
	stu_id AS 学号,
	NAME AS 姓名,
	score AS 分数,
	CUME_DIST() OVER ( ORDER BY score ) AS cm1,
	CUME_DIST() OVER ( PARTITION BY NAME ORDER BY score ) AS cm2 
FROM
	tb_score 
WHERE
	NAME IN ( '孙悟空', '唐僧' );
```

### 滑动窗口函数

>LAG()、LEAD()

```sql
/*
查询所有订单，并分别显示每个人正负方向的下一条金额记录
lag/lead(字段，[偏移量，[默认值]])
lag 向负方向偏移
lead 向正方向偏移
*/
SELECT
	order_id AS 订单号,
	username AS 用户名,
	create_date AS 创建日期,
	cost AS 消费金额,
	LAG( cost, 1, 0 ) OVER ( PARTITION BY username ORDER BY create_date ) AS lag_负方向的下一条金额记录,
	LEAD( cost, 1, 0 ) OVER ( PARTITION BY username ORDER BY create_date ) AS lead_正方向的下一条金额记录 
FROM
	tb_customer_shopping tcs;
```

### 首尾函数

>FIRST_VALUE()、LAST_VALUE()

```sql
/*
查询所有订单，并分别显示当前用户的第一条与最后一条消费记录金额
first_value/last_value(字段)
first_value当前分区的第一条记录
last_value当前分区的最后一条记录
但是默认情况下last_value是取当前行数据与当前行之前的数据的比较
(即rows between unbounded preceding and current row)，而不是分区所有数据的最后一行
如果想要取需要在over语句的order后面加上`rows between unbounded preceding and unbounded following`
*/
SELECT
	order_id AS 订单号,
	username AS 用户名,
	create_date AS 创建日期,
	cost AS 消费金额,
	FIRST_VALUE( cost ) OVER ( PARTITION BY username ORDER BY create_date DESC ) 当前用户的第一条消费记录金额,
	LAST_VALUE( cost ) OVER ( PARTITION BY username ORDER BY create_date DESC /* rows BETWEEN unbounded preceding AND unbounded following */ ) 当前用户的最后一条消费记录金额 
FROM
	tb_customer_shopping tcs;
```

### 其它函数

>NTH_VALUE()、NTILE()、聚合函数

```sql
/*
查询所有记录，并显示第3行数据的金额
NTH_VALUE(字段，第N行)
显示第N行的指定字段
*/
SELECT
	ROW_NUMBER() OVER w AS 行号,
	order_id AS 订单号,
	username AS 用户名,
	create_date AS 创建日期,
	cost AS 消费金额,
	NTH_VALUE( cost, 3 ) OVER w AS '第3行记录金额' 
FROM
	tb_customer_shopping WINDOW w AS ( ORDER BY username ASC );
```

```sql
/*
查询所有数据，并给每个人按照金额升序分级(最大4级)，金额越大级别越大
NTILE(最大级别)
给当前分区分级，最大num级，记录数不一定被n整除所以分级不一定完全平均.
默认按照order值的大小分级，值越大级别越高
当记录数<=最大级别时，分级是连续的，不会有最大级别

也可以理解为将数据分为多少份，尽可能均分，如果不能均分先保证等级小的行，每份最多差1行
*/
SELECT
	NTILE( 4 ) OVER w AS nf,
	order_id 订单号,
	username 姓名,
	cost 金额 
FROM
	tb_customer_shopping tcs 
WHERE
	username IN ( 'Jack', 'King' ) WINDOW w AS ( PARTITION BY username ORDER BY cost );
/* 记录数<最大级别的例子 */
SELECT
	ntile( 4 ) over ( ORDER BY cost ) AS nf,
	cost 
FROM
	( SELECT * FROM tb_customer_shopping WHERE username = 'Jack' LIMIT 0, 2 ) AS t;
```

```sql
/*
聚合函数也可以按照窗口计算值
有order by条件没有制定rows between，默认是rows between unbounded preceding and current row 取本行和之前所有的行，详见数据范围
示例：每个用户截止到当前日期的累计购买金额/平均购买金额/最大购买金额/最小购买金额/购买数量。
*/
SELECT
	*,
	SUM( cost ) OVER ( PARTITION BY username ORDER BY create_date ) sum_cost,
	AVG( cost ) OVER ( PARTITION BY username ORDER BY create_date ) avg_cost,
	MAX( cost ) OVER ( PARTITION BY username ORDER BY create_date ) max_cost,
	MIN( cost ) OVER ( PARTITION BY username ORDER BY create_date ) min_cost,
	COUNT( cost ) OVER ( PARTITION BY username ORDER BY create_date ) count_cost 
FROM
	tb_customer_shopping;
/*
查询所有记录，并显示以最高消费金额为标准的百分比
*/
SELECT
	*,
	cost / MAX( cost ) over ( ORDER BY cost DESC ) 
FROM
	tb_customer_shopping 
WHERE
	username = 'Jack';
```

## 总结

### 窗口函数语法格式

函数名(字段名) over(子句) 

over()括号内若不写，则意味着窗口函数基于满足where条件的所有行进行计算。

若括号内不为空，则支持以下语法来设置窗口。

函数名(字段名) over(partition by <要分列的组> order by <要排序的列> rows between <数据范围>) 

### 数据范围

* rows between 2 preceding and current row 取本行和前面两行

* rows between unbounded preceding and current row 取本行和之前所有的行

* rows between current row and unbounded following 取本行和之后所有的行

* rows between 3 preceding and 1 following 从前面三行和下面一行，总共五行

* 当order by后面没有rows between时，窗口规范默认是取本行和之前所有的行

* 当order by和rows between都没有时，窗口规范默认是分组下所有行，即rows between unbounded preceding and unbounded following