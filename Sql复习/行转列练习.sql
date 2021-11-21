select * from test;
-- 姓名      性别     年龄
-- --------- -------- ----
-- 张三       男        50
select max(decode(TYPE,1,value)) 姓名,
       max(decode(TYPE,2,value)) 性别,
       max(decode(TYPE,3,value)) 年龄
from test group by T_ID;

select * from tmp;
--           胜 负
-- 2005-05-09 2 2
-- 2005-05-10 1 2
select rq,
       count(decode(SHENGFU,'胜','胜')) 胜,
       count(decode(SHENGFU,'负','负')) 负
from tmp group by rq order by rq;

select * from STUDENT_SCORE;
-- 姓名   语文  数学  英语
-- 王五    89    56   89
select name,
       max(decode(SUBJECT, '语文', SCORE)) 语文,
       max(decode(SUBJECT, '数学', SCORE)) 数学,
       max(decode(SUBJECT, '英语', SCORE)) 英语
from STUDENT_SCORE
group by NAME;

select ss1.NAME,ss1.SCORE 语文,0 数学,0 英语 from STUDENT_SCORE ss1 where ss1.SUBJECT = '语文' union all
select ss2.NAME,0 语文,ss2.SCORE 数学,0 英语 from STUDENT_SCORE ss2 where ss2.SUBJECT = '数学' union all
select ss3.NAME,0 语文,0 数学,ss3.SCORE 英语 from STUDENT_SCORE ss3 where ss3.SUBJECT = '英语';

select t.NAME, sum(t.语文), sum(t.数学), sum(t.英语)
from (select ss1.NAME, ss1.SCORE 语文, 0 数学, 0 英语
      from STUDENT_SCORE ss1
      where ss1.SUBJECT = '语文'
      union all
      select ss2.NAME, 0 语文, ss2.SCORE 数学, 0 英语
      from STUDENT_SCORE ss2
      where ss2.SUBJECT = '数学'
      union all
      select ss3.NAME, 0 语文, 0 数学, ss3.SCORE 英语
      from STUDENT_SCORE ss3
      where ss3.SUBJECT = '英语') t
group by t.NAME;

select name,
       max(decode(SUBJECT, '语文', case when SCORE>=80 then '优秀' when SCORE>=60 then '及格' else '不及格' end)) 语文,
       max(decode(SUBJECT, '数学', case when SCORE>=80 then '优秀' when SCORE>=60 then '及格' else '不及格' end)) 数学,
       max(decode(SUBJECT, '英语', case when SCORE>=80 then '优秀' when SCORE>=60 then '及格' else '不及格' end)) 英语
from STUDENT_SCORE
group by NAME;

/*
create table yj01(
       month varchar2(10),
       deptno number(10),
       yj number(10)
);

insert into yj01(month,deptno,yj) values('一月份',01,10);
insert into yj01(month,deptno,yj) values('二月份',02,10);
insert into yj01(month,deptno,yj) values('二月份',03,5);
insert into yj01(month,deptno,yj) values('三月份',02,8);
insert into yj01(month,deptno,yj) values('三月份',04,9);
insert into yj01(month,deptno,yj) values('三月份',03,8);

create table yjdept(
       deptno number(10),
       dname varchar2(20)
);

insert into yjdept(deptno,dname) values(01,'国内业务一部');
insert into yjdept(deptno,dname) values(02,'国内业务二部');
insert into yjdept(deptno,dname) values(03,'国内业务三部');
insert into yjdept(deptno,dname) values(04,'国际业务部');
*/

-- table3 （result）
--
-- 部门dep 一月份      二月份      三月份
-- --------------------------------------
--       01      10
--       02      10         8
--       03                 5        8
--       04                          9
-- ------------------------------------------

select * from YJ01;
select yd.DEPTNO,
       max(decode(yj.MONTH,'一月份',YJ)) 一月份,
       max(decode(yj.MONTH,'二月份',YJ)) 二月份,
       max(decode(yj.MONTH,'三月份',YJ)) 三月份
from YJDEPT yd join YJ01 yj on yd.DEPTNO = yj.DEPTNO group by yd.DEPTNO;















