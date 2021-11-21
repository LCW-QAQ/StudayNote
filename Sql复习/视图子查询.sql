--求平均薪水等级最低的部门, 他的部门名称是什么, 请完全使用子查询
--每个部门的平均薪水等级
select deptno,avg(sal) from emp group by deptno having deptno is not null;
select min(sg.grade)
from salgrade sg,
     (select deptno, avg(sal) vsal from emp group by deptno having deptno is not null) m
where m.vsal between sg.LOSAL and sg.HISAL;

select m.deptno, sg.grade
from salgrade sg,
     (select deptno, avg(sal) vsal from emp group by deptno having deptno is not null) m
where m.vsal between sg.LOSAL and sg.HISAL
  and sg.grade in (select min(sg.grade)
                   from salgrade sg,
                        (select deptno, avg(sal) vsal from emp group by deptno having deptno is not null) m
                   where m.vsal between sg.LOSAL and sg.HISAL
);

select d.dname, m.grade
from dept d
         join (select m.deptno, sg.grade
               from salgrade sg,
                    v_dept_avg m
               where m.vsal between sg.LOSAL and sg.HISAL
                 and sg.grade in (select min(sg.grade)
                                  from salgrade sg,
                                       v_dept_avg m
                                  where m.vsal between sg.LOSAL and sg.HISAL
               )) m on d.deptno = m.deptno;

--创建部门薪水的视图
create view v_dept_avg as select deptno, avg(sal) vsal from emp group by deptno having deptno is not null;













