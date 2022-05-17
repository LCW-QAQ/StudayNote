/* 订单表，记录了name在create_date消费了cost元 */ SELECT
* 
FROM
	tb_customer_shopping;
/* 考试成绩表，记录了name的subject考了score分 */
SELECT
	* 
FROM
	tb_score;
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
/*
查询所有数据，并给每个人按照金额升序分级(最大4级)，金额越大级别越大
NTILE(最大级别)
给当前分区分级，最大num级，记录数不一定被n整除所以分级不一定完全平均.
默认按照order值的大小分级，值越大级别越高
当记录数<=最大级别时，分级是连续的，不会有最大级别
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
/*
总结:
窗口函数语法格式
函数名(字段名) over(子句) 
over()括号内若不写，则意味着窗口函数基于满足where条件的所有行进行计算。
若括号内不为空，则支持以下语法来设置窗口。
函数名(字段名) over(partition by <要分列的组> order by <要排序的列> rows between <数据范围>) 

数据范围:
rows between 2 preceding and current row 取本行和前面两行

rows between unbounded preceding and current row 取本行和之前所有的行

rows between current row and unbounded following 取本行和之后所有的行

rows between 3 preceding and 1 following 从前面三行和下面一行，总共五行

当order by后面没有rows between时，窗口规范默认是取本行和之前所有的行

当order by和rows between都没有时，窗口规范默认是分组下所有行
即rows between unbounded preceding and unbounded following
*/