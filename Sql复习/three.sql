select sum(sal) from emp;
select count(0) from emp;
select deptno,count(*) from emp group by deptno having count(*)>3 order by deptno;
select lpad(ename,length(ename)+2,' ') from emp;
select trim(ename) from emp;
select instr('aBaBAB','A') from dual;
select substr('0123456',0,2) from dual;
select replace('01234256','2','*') from dual;









