select * from test;
/*
    姓名 性别 年龄
*/
select max(case TYPE when 1 then VALUE end) 姓名,
       max(case TYPE when 2 then VALUE end) 性别,
       max(case TYPE when 3 then VALUE end) 年龄
from test
group by T_ID;

select max(decode(TYPE,1,VALUE,0)) 姓名,
       max(decode(TYPE,2,VALUE,0)) 性别,
       max(decode(TYPE,3,VALUE,0)) 年龄
from test
group by T_ID;

select * from emp where extract(year from HIREDATE) = '1982';

select * from emp where (sysdate-hiredate)/365 >= 39;

select hiredate,next_day(add_months(hiredate,6),'星期一') from emp;

select ename,nvl(to_char(mgr),'boss') from emp where mgr is null;

select ename,sal,deptno,decode(deptno,10,sal*1.1,20,sal*1.15,30,sal*1.2,sal*1.18) sal from emp;












