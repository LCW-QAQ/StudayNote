select * from emp where deptno in(10);
select * from emp where sal*12 > 30000;
select ename,sal from emp where comm is null;
select ename,sal,comm from emp where sal > 1500 and comm is not null;
select ename,sal,comm from emp where sal > 1500 or comm is not null;
select ename,sal from emp where ename like('%S%');
select ename,sal from emp where ename like('JO%');
select ename,sal from emp where ename like('%\%%') escape('\');
select ename, sal, emp.deptno, dname
from emp
         join dept on emp.deptno = dept.deptno and dept.dname in ('SALES', 'RESEARCH');
select ename, sal, deptno
from emp
where exists(select deptno, dname from dept where dept.deptno = emp.deptno and dname in ('SALES', 'RESEARCH'));











