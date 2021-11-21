--有哪些人的薪水在整个雇员的平均薪水之上
select * from emp e where e.sal > (select avg(sal) from emp e1);
--每个部门的平均薪水等级
select deptno,avg(sal) from emp e group by deptno;
select m.deptno,round(m.vsal),sg.grade
from salgrade sg
         join (select deptno, avg(sal) vsal from emp e where e.DEPTNO is not null group by deptno) m on m.vsal between sg.LOSAL and sg.HISAL;

--1、求平均薪水最高的部门的部门编号
select e.deptno,avg(sal) from emp e group by e.deptno having e.deptno is not null;
select max(e.vsal) from (select avg(sal) vsal from emp e group by e.deptno having e.deptno is not null) e;
--最高的薪水
select max(avg(sal)) from emp e group by e.deptno having e.deptno is not null;
select e.deptno, avg(sal) vsal
from emp e
group by e.deptno
having e.deptno is not null
   and avg(sal) in (select max(avg(sal)) from emp e group by e.deptno having e.deptno is not null);
--2、求部门平均薪水的等级
select avg(sal) from emp e group by deptno having deptno is not null;
select m.deptno,sg.grade
from salgrade sg
         join (select e.deptno,avg(sal) vsal from emp e group by deptno having deptno is not null) m
              on m.vsal between sg.LOSAL and sg.HISAL;
--3、求部门平均的薪水等级
select deptno, avg(sg.grade)
from emp e
         join salgrade sg on e.sal between sg.LOSAL and sg.HISAL
group by deptno
having deptno is not null;
--4、求薪水最高的前5名雇员
select * from (select * from emp e order by e.sal desc) where rownum <= 5;
--5、求薪水最高的第6到10名雇员
select m.*,rownum from (select * from emp e order by e.sal desc) m where rownum <= 10;
select *
from (select m.*, rownum rn from (select * from emp e order by e.sal desc) m where rownum <= 10) m
where m.rn between 6 and 10;









