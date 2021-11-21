-- 题目要求：根据Oracle数据库scott模式下的emp表和dept表，完成下列操作。
-- （1）	查询20号部门的所有员工信息。
select * from emp where deptno = 20;
-- （2）	查询所有工种为CLERK的员工的工号、员工名和部门名。
select empno,ename,dname from emp e join DEPT D on D.DEPTNO = e.DEPTNO where e.job in('CLERK');
-- （3）	查询奖金（COMM）高于工资（SAL）的员工信息。
select * from emp e where comm > sal;
-- （4）	查询奖金高于工资的20%的员工信息。
select * from emp where comm > 0.2*sal;
-- （5）	查询10号部门中工种为MANAGER和20号部门中工种为CLERK的员工的信息。
select * from emp e where e.deptno = 20 and e.job = 'CLERK' or
                          e.deptno = 10 and e.job = 'MANAGER';
-- （6）	查询所有工种不是MANAGER和CLERK，且工资大于或等于2000的员工的详细信息。
select * from emp e where e.job not in('MANAGER','CLERK') and sal >= 2000;
-- （7）	查询有奖金的员工的不同工种。
select distinct job from emp e where e.comm is not null;
-- （8）	查询所有员工工资和奖金的和。
select ename,nvl(sal,0)+nvl(comm,0) from emp;
select sum(nvl(sal,0)+nvl(comm,0)) from emp;
-- （9）	查询没有奖金或奖金低于100的员工信息。
select * from emp e where e.comm is null or e.comm < 100;
-- （10）查询各月倒数第2天入职的员工信息。
select * from emp where last_day(hiredate)-hiredate = 1;
-- （11）查询员工工龄大于或等于30年的员工信息。
select * from emp where (sysdate-hiredate)/365 >= 30;
-- （12）查询员工信息，要求以首字母大写的方式显示所有员工的姓名。
select upper(substr(ename,0,1))||lower(substr(ename,2)) from emp;
-- （13）查询员工名正好为6个字符的员工的信息。
select * from emp where length(ename) = 6;
-- （14）查询员工名字中不包含字母“S”员工。
select * from emp where instr(ename,'S') = 0;
-- （15）查询员工姓名的第2个字母为“M”的员工信息。
select * from emp where ename like('_M%');
-- （16）查询所有员工姓名的前3个字符。
select substr(ename,0,3) from emp;
-- （17）查询所有员工的姓名，如果包含字母“s”，则用“S”替换。
select replace(ename,'s','S') from emp;
-- （18）查询员工的姓名和入职日期，并按入职日期从先到后进行排列。
select ename,hiredate from emp order by hiredate;
-- （19）显示所有的姓名、工种、工资和奖金，按工种降序排列，若工种相同则按工资升序排列。
select ename,job,sal,comm from emp order by job desc,sal asc;
-- （20）显示所有员工的姓名、入职的年份和月份，若入职日期所在的月份排序，若月份相同则按入职的年份排序。
select ename,extract(year from hiredate),extract(month from hiredate) from emp order by extract(month from hiredate),
                                                                                        extract(year from hiredate);
-- （21）查询在2月份入职的所有员工信息。
select * from emp where extract(month from hiredate) = '2';
-- （22）查询所有员工入职以来的工作期限，用“**年**月**日”的形式表示。
select ename,
       floor((sysdate-hiredate)/365) || '年' ||
       floor(mod(sysdate-hiredate,365)/30) || '月' ||
       ceil(mod(mod(sysdate-hiredate,365),30)) || '天'
from emp;
-- （23）查询至少有一个员工的部门信息。
select e.deptno, max(d.dname)
from emp e
         join DEPT D on D.DEPTNO = e.DEPTNO
where e.deptno is not null
group by e.deptno
having count(1) >= 1;
select * from dept;
-- （24）查询工资比SMITH员工工资高的所有员工信息。
select * from emp e where e.sal > (select sal from emp where ename = 'SMITH');
-- （25）查询所有员工的姓名及其直接上级的姓名。
select e.ename 员工,m.ename 领导 from emp e join emp m on e.mgr = m.empno;
-- （26）查询入职日期早于其直接上级领导的所有员工信息。
select e.ename 员工, e.hiredate, m.ename 领导, m.hiredate
from emp e
         join emp m on e.mgr = m.empno
where e.hiredate < m.hiredate;
-- （27）查询所有部门及其员工信息，包括那些没有员工的部门。
select * from emp e right join DEPT D on D.DEPTNO = e.DEPTNO;
select * from dept d left join EMP E on d.DEPTNO = E.DEPTNO;
-- （28）查询所有员工及其部门信息，包括那些还不属于任何部门的员工。
select * from emp e left join DEPT D on D.DEPTNO = e.DEPTNO;
-- （29）查询所有工种为CLERK的员工的姓名及其部门名称。
select e.ename,d.dname from emp e join DEPT D on e.DEPTNO = D.DEPTNO where e.job in('CLERK');
-- （30）查询最低工资大于2500的各种工作。
select job from emp group by job having min(sal)>2500;
-- （31）查询最低工资低于2000的部门及其员工信息。
select e.deptno, max(d.dname)
from emp e
         join DEPT D on D.DEPTNO = e.DEPTNO
group by e.deptno
having min(sal) < 2000;
-- （32）查询在SALES部门工作的员工的姓名信息。
select * from emp e join DEPT D on D.DEPTNO = e.DEPTNO and d.dname = 'SALES';
-- （33）查询工资高于公司平均工资的所有员工信息。
select * from emp e where e.sal > (select avg(sal) from emp);
-- （34）查询与SMITH员工从事相同工作的所有员工信息。
select * from emp e where e.job in(select job from emp where ename in('SMITH'));
-- （35）列出工资等于30号部门中某个员工工资的所有员工的姓名和工资。
select e.ename,e.sal from emp e where e.sal in(select sal from emp where deptno = 30) and e.deptno != 30;
-- （36）查询工资高于30号部门中工作的所有员工的工资的员工姓名和工资。
select e.ename,e.sal from emp e where e.sal > all(select sal from emp where deptno = 30);
-- （37）查询每个部门中的员工数量、平均工资和平均工作年限。
select count(1) 员工数量,avg(e.sal) 平均工资,round(avg(sysdate-hiredate)/365,2) 平均工作年限 from emp e group by e.deptno;
-- （38）查询从事同一种工作但不属于同一部门的员工信息。
select distinct e.empno,e.ename,e.deptno from emp e join emp e2 on e.job = e2.job and e.deptno != e2.deptno;
-- （39）查询各个部门的详细信息以及部门人数、部门平均工资。
select e.deptno, max(d.dname), count(1), avg(e.sal)
from emp e
         join DEPT D on D.DEPTNO = e.DEPTNO
group by e.deptno;
-- （40）查询各种工作的最低工资。
select job,min(sal) from emp group by job;
-- （41）查询各个部门中的不同工种的最高工资。
select e.deptno,e.job,max(e.sal) from emp e where e.deptno is not null group by e.deptno,e.job order by e.deptno;
-- （42）查询10号部门员工以及领导的信息。
select e.ename,e2.ename from emp e join emp e2 on e.mgr = e2.empno where e.deptno = 10;
-- （43）查询各个部门的人数及平均工资。
select deptno,count(1),avg(sal) from emp where deptno is not null group by deptno;
-- （44）查询工资为某个部门平均工资的员工信息。
select * from emp e where e.sal in(select avg(sal) from emp group by deptno);
-- （45）查询工资高于本部门平均工资的员工的信息。
select e.ename,e.sal,m.vsal
from emp e
         join (select deptno, avg(sal) vsal from emp group by deptno) m on e.deptno = m.deptno
where e.sal > m.vsal;
-- （46）查询工资高于本部门平均工资的员工的信息及其部门的平均工资。
select e.ename,e.sal,m.vsal
from emp e
         join (select deptno, avg(sal) vsal from emp group by deptno) m on e.deptno = m.deptno
where e.sal > m.vsal;
-- （47）查询工资高于20号部门某个员工工资的员工的信息。
select * from emp e where e.sal > any(select sal from emp where deptno = 20) and e.deptno != 20;
-- （48）统计各个工种的人数与平均工资。
select job,count(1),avg(sal) from emp group by job;
-- （49）统计每个部门中各个工种的人数与平均工资。
select e.deptno,e.job,count(1),avg(sal) from emp e group by e.deptno,e.job order by e.deptno;
-- （50）查询工资、奖金与10号部门某个员工工资、奖金都相同的员工的信息。
select e.ename, e.sal, e.comm, e2.ename, e2.sal, e2.comm
from emp e
         join emp e2 on e2.deptno = 10
where e.deptno != 10
  and e.sal = e2.sal
  and e.comm = e2.comm;
-- （51）查询部门人数大于5的部门的员工的信息。
select e.deptno from emp e group by e.deptno having count(1)>5;
select * from emp e where e.deptno in(select e.deptno from emp e group by e.deptno having count(1)>5);
-- （52）查询所有员工工资都大于1000的部门的信息。
select e.deptno, max(d.dname)
from emp e
         join DEPT D on D.DEPTNO = e.DEPTNO
where e.deptno is not null and e.deptno not in(select deptno from emp where sal<1000)
group by e.deptno;
-- （53）查询所有员工工资都大于1000的部门的信息及其员工信息。
select e.*, m.name
from emp e
         join (select e.deptno, max(d.dname) name
               from emp e
                        join DEPT D on D.DEPTNO = e.DEPTNO
               where e.deptno is not null
                 and e.deptno not in (select deptno from emp where sal < 1000)
               group by e.deptno) m on e.deptno = m.deptno;
-- （54）查询所有员工工资都在900~3000之间的部门的信息。
select distinct e.deptno
from emp e
where e.deptno not in (select distinct deptno from emp where deptno is not null and sal not between 900 and 3000);

select *
from dept
where deptno in (select distinct e.deptno
                 from emp e
                 where e.deptno not in
                       (select distinct deptno from emp where deptno is not null and sal not between 900 and 3000));
-- （55）查询所有工资都在900~3000之间的员工所在部门的员工信息。
select *
from emp
where deptno in (select distinct deptno
                 from emp
                 where deptno not in
                       (select distinct deptno from emp where deptno is not null and sal not between 900 and 3000));
-- （56）查询每个员工的领导所在部门的信息。
select distinct m.ename,d.dname from emp e join emp m on e.mgr = m.empno join DEPT D on D.DEPTNO = m.DEPTNO;
-- （57）查询人数最多的部门信息。
select max(count(1)) from emp e where e.deptno is not null group by e.deptno;
select deptno,count(1) from emp e where e.deptno is not null group by e.deptno;

select m1.deptno
from (select deptno, count(1) cou from emp e where e.deptno is not null group by e.deptno) m1
where m1.cou in (select max(count(1)) from emp e where e.deptno is not null group by e.deptno);

select *
from dept d
where d.deptno in (select m1.deptno
                   from (select deptno, count(1) cou from emp e where e.deptno is not null group by e.deptno) m1
                   where m1.cou in (select max(count(1)) from emp e where e.deptno is not null group by e.deptno));
-- （58）查询30号部门中工资排序前3名的员工信息。
select * from emp where deptno = 30 order by sal desc;
-- （59）查询所有员工中工资排在5~10名之间的员工信息。
select * from emp order by sal desc;
select * from (select e.*,rownum rn from emp e order by sal desc) m where m.rn between 5 and 10;
-- （60）向emp表中插入一条记录，员工号为1357，员工名字为oracle，工资为2050元，部门号为20，入职日期为2002年5月10日。
insert into emp(empno, ename, sal, deptno, hiredate)
values (1357, 'oracle', 2050, 20, to_date('2002/05/10','yyyy-dd-mm'));
select * from emp;
-- （61）向emp表中插入一条记录，员工名字为FAN，员工号为8000，其他信息与SMITH员工的信息相同。
insert into emp(empno, ename, job, mgr, hiredate, sal, comm, deptno)
select 8000,'FAN',job,mgr,hiredate,sal,comm,deptno from emp where ename = 'SMITH';
-- （62）将各部门员工的工资修改为该员工所在部门平均工资加1000。
create table temp_emp as select * from emp;
select * from temp_emp;
update temp_emp set sal=1000+(select avg(sal) from temp_emp e where temp_emp.deptno = e.deptno group by deptno)
drop table temp_emp;

-- 1、查询82年员工
select * from emp where extract(year from hiredate) = '1982';
-- 2、查询32年工龄的人员
select * from emp where (sysdate-hiredate)/365 > 32;
-- 3、显示员工雇佣期 6 个月后下一个星期一的日期
select next_day(hiredate,'星期一') from emp where hiredate is not null;
-- 4、找没有上级的员工，把mgr的字段信息输出为 "boss"
select ename,nvl(to_char(mgr),'boss') from emp where mgr is null;
-- 5、为所有人长工资，标准是：10部门长10%；20部门长15%；30部门长20%其他部门长18%
select ename,decode(deptno,10,sal*1.1,20,sal*1.15,30,sal*1.2,sal*1.18) from emp;

-- 1.求部门中薪水最高的人
select max(sal) from emp group by deptno;
select * from emp e where sal in(select max(sal) from emp group by deptno);
-- 2.求部门平均薪水的等级
select avg(sal) from emp group by deptno;
select m.deptno, m.vsal
from salgrade sg
         join (select deptno, avg(sal) vsal from emp where deptno is not null group by deptno) m
              on m.vsal between sg.LOSAL and sg.HISAL;
-- 3. 求部门平均的薪水等级
select m.deptno, m.vsal
from salgrade sg
         join (select deptno, avg(sal) vsal from emp where deptno is not null group by deptno) m
              on m.vsal between sg.LOSAL and sg.HISAL;
-- 4. 雇员中有哪些人是经理人
select distinct m.ename from emp e join emp m on e.mgr = m.empno;
-- 5. 不准用组函数，求薪水的最高值
select sal from emp order by sal desc;
select sal from (select sal from emp order by sal desc) where rownum = 1;
-- 6. 求平均薪水最高的部门的部门编号
select max(avg(sal)) from emp group by deptno;
select deptno
from (select deptno, avg(sal) vsal from emp group by deptno having deptno is not null) m1
where m1.vsal in (select max(avg(sal)) from emp group by deptno having deptno is not null);
-- 组函数嵌套写法(对多可以嵌套一次，group by 只对内层函数有效)
--  求平均薪水最高的部门的部门名称
-- 8. 求平均薪水的等级最低的部门的部门名称
select min(avg(sal)) from emp group by deptno;
select d.*
from dept d
         join (select deptno, avg(sal) vsal from emp group by deptno) m1 on d.deptno = m1.deptno
         join (select min(avg(sal)) mind from emp group by deptno) m2 on m1.vsal in (m2.mind);
--  9.求部门经理人中平均薪水最低的部门名称
-->求所有部门经理人中平均薪水最低的人的部门信息
select deptno,avg(sal) from emp where empno in(select mgr from emp) group by deptno;
select min(avg(sal)) from emp where empno in(select mgr from emp) group by deptno;
select d.deptno, d.dname, m1.vsal
from (select deptno, avg(sal) vsal from emp where empno in (select mgr from emp) group by deptno) m1
         join dept d on d.deptno = m1.deptno
where m1.vsal in (select min(avg(sal)) from emp where empno in (select mgr from emp) group by deptno);
-- 10. 求比普通员工的最高薪水还要高的经理人名称(not in)
select *
from emp
where empno in (select mgr from emp)
  and sal > (select max(sal) from emp where empno not in (select mgr from emp where mgr is not null));
select * from emp;
--  11. 求薪水最高的前5名雇员
select * from emp order by sal desc;
select * from (select * from emp order by sal desc) where rownum < 6;
-- 12. 求薪水最高的第6到第10名雇(!important)
select * from (select emp.*,rownum rn from emp order by sal desc) where rn between 6 and 10;
-- 13. 求最后入职的5名员工
select * from emp where hiredate is not null order by hiredate desc;
select * from (select * from emp where hiredate is not null order by hiredate desc) where rownum < 6;












