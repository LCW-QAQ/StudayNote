create table test(
   id int(10) primary key,
   type int(10) ,
   t_id int(10),
   value varchar(5)
);
insert into test values(100,1,1,'zs');
insert into test values(200,2,1,'m');
insert into test values(300,3,1,'50');

insert into test values(101,1,2,'ls');
insert into test values(201,2,2,'m');
insert into test values(301,3,2,'30');

insert into test values(102,1,3,'ww');
insert into test values(202,2,3,'f');
insert into test values(302,3,3,'10');

/*
如图所示，左边是基本的数据表
type值表示的是本行value值的类型：1.姓名 2.性别 3.年龄
t_id表示本行信息所属的用户：1.zs 2.ls 3.ww


请写出一条查询语句结果格式如下：
姓名      性别     年龄
------ --------  -----
zs        m        50
*/
select * from test;

select 
	t_id,
	max(if(type=1, value, null)) '姓名',
	max(if(type=2, value, null)) '性别',
	max(if(type=3, value, null)) '年龄'
from test
group by t_id;

with q1 as (
	select * from test where type = 1
),
q2 as (
	select * from test where type = 2
),
q3 as (
	select * from test where type = 3
)
select
	q1.value, q2.value, q3.value
from q1
-- 需要使用左连接, q1中装的的所有用户
left join q2 on q1.t_id = q2.t_id
left join q3 on q2.t_id = q3.t_id;



create table tmp(rq varchar(10),shengfu varchar(5));

insert into tmp values('2005-05-09','胜');
insert into tmp values('2005-05-09','胜');
insert into tmp values('2005-05-09','负');
insert into tmp values('2005-05-09','负');
insert into tmp values('2005-05-10','胜');
insert into tmp values('2005-05-10','负');
insert into tmp values('2005-05-10','负');

/**
请写出一条查询语句结果格式如下：
          胜 负
2005-05-09 2 2
2005-05-10 1 2
------------------------------------------
*/

select
	rq as '日期',
	count(if(shengfu='胜', 1, null)) as '胜',
	count(if(shengfu='负', 1, null)) as '负'
from tmp
group by rq;



create table student_score
(
  name    VARCHAR(20),
  subject VARCHAR(20),
  score   int
);

insert into student_score (NAME, SUBJECT, SCORE) values ('张三', '语文', 78.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('张三', '数学', 88.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('张三', '英语', 98.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('李四', '语文', 89.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('李四', '数学', 76.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('李四', '英语', 90.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('王五', '语文', 99.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('王五', '数学', 66.0);
insert into student_score (NAME, SUBJECT, SCORE) values ('王五', '英语', 59.0);

/*
1.请写出一条查询语句结果格式如下：
姓名   语文  数学  英语
王五    99   66   59
2.请写出一条查询语句结果格式如下：
大于或等于80表示优秀，大于或等于60表示及格，小于60分表示不及格。    
姓名       语文            数学             英语  
王五       优秀            及格            不及格   
*/

select * from student_score;

select
	name,
	max(if(subject='数学', score, null)) as '数学',
	max(if(subject='语文', score, null)) as '语文',
	max(if(subject='英语', score, null)) as '英语'
from student_score
group by name;

select
	name,
	max(if(subject='数学', 
		case 
			when score >= 80 then '优秀'
			when score >= 60 then '及格'
			else '不及格'
		end
	, null)) as '数学',
	max(if(subject='语文', 
		case 
			when score >= 80 then '优秀'
			when score >= 60 then '及格'
			else '不及格'
		end, null)) as '语文',
	max(if(subject='英语', 
		case 
			when score >= 80 then '优秀'
			when score >= 60 then '及格'
			else '不及格'
		end, null)) as '英语'
from student_score
group by name;


create table yj01(
       month varchar(10),
       deptno int(10),
       yj int(10)
);

insert into yj01(month,deptno,yj) values('一月份',01,10);
insert into yj01(month,deptno,yj) values('一月份',01,6);
insert into yj01(month,deptno,yj) values('二月份',02,10);
insert into yj01(month,deptno,yj) values('二月份',03,5);
insert into yj01(month,deptno,yj) values('二月份',01,3);
insert into yj01(month,deptno,yj) values('三月份',02,8);
insert into yj01(month,deptno,yj) values('三月份',04,9);
insert into yj01(month,deptno,yj) values('三月份',03,8);
insert into yj01(month,deptno,yj) values('三月份',01,7);

create table yjdept(
       deptno int(10),
       dname varchar(20)
);

insert into yjdept(deptno,dname) values(01,'国内业务一部');
insert into yjdept(deptno,dname) values(02,'国内业务二部');
insert into yjdept(deptno,dname) values(03,'国内业务三部');
insert into yjdept(deptno,dname) values(04,'国际业务部');

/**
请写出一条查询语句结果格式如下：注意提供的数据及结果不一定准确，

部门dep       一月份      二月份    三月份
--------------------------------------
国内业务一部      10                  
国内业务二部      10        8         
国内业务三部                5        8
国际业务部                           9
------------------------------------------

*/

select * from yj01;
select * from yjdept;

select
	d.dname as '部门dep',
	sum(if(month='一月份', yj, 0)) as '一月份',
	sum(if(month='二月份', yj, 0)) as '二月份',
	sum(if(month='三月份', yj, 0)) as '三月份'
from yj01 y
left join yjdept d on y.deptno = d.deptno
group by d.dname;



create table students2(
	id int primary key auto_increment,
	name varchar(30) not null,
	scores varchar(30) not null
)

insert into students2(name, scores)
values ('ZhangSan', '100,88,94'),('LiSi', '72,83,99');

/*
1. 将数据转换成
	name			 数学			语文	  英语
	zhangsan   100       80      94
	
2. 再将上面数据转换成:
	name        subject    score
  zhangsan     数学        80
	zhangsan     英语        72
	zhangsan     语文        94
*/

select
	*
from students2

-- substring_index(scores, ',', 1)
select
	name, 
	substring_index(scores, ',', 1) as '数学',
	substring_index(substring_index(scores, ',', 2), ',', -1) as '语文',
	substring_index(scores, ',', -1) as '英语'
from students2;


with q1 as (select
	name, 
	substring_index(scores, ',', 1) as '数学',
	substring_index(substring_index(scores, ',', 2), ',', -1) as '语文',
	substring_index(scores, ',', -1) as '英语'
from students2)
select
	name, '数学' as 'subject', `数学` as 'score'
from q1
union
select
	name, '语文' as 'subject', `语文` as 'score'
from q1
union 
select
	name, '英语' as 'subject', `英语` as 'score'
from q1
order by name;