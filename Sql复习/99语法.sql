--cross join 等同于笛卡尔积
select * from emp cross join dept;
--natural join 自然连接
select * from emp natural join dept;
--外连接
select * from emp e left join dept d on e.deptno = d.deptno;
select * from emp e right join dept d on e.deptno = d.deptno;
select * from emp e full join dept d on e.deptno = d.deptno;

select * from emp e inner join dept d on e.deptno = d.deptno;
select * from emp e join dept d using(deptno);

--查询雇员名字, 所在单位, 薪水等级
select e.ename, d.loc, sg.grade
from emp e
         join DEPT D on D.DEPTNO = e.DEPTNO
         join salgrade sg on e.sal between sg.losal and sg.hisal;





