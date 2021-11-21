-- 1、查询"01"课程比"02"课程成绩高的学生的信息及课程分数
-- 01 02 if 01.score > 02.score show msg and score
select * from student std
    left join score s on std.s_id = s.s_id and s.c_id = '01'
    left join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
    where s.s_score > s2.s_score;
-- 2、查询"01"课程比"02"课程成绩低的学生的信息及课程分数
-- 01 02 if 01.score > 02.score show msg and score
select std.*, s.s_score '01', s2.s_score '02' from student std
    left join score s on std.s_id = s.s_id and s.c_id = '01'
    left join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
    where s.s_score < s2.s_score;
-- 3、查询平均成绩大于等于60分的同学的学生编号和学生姓名和平均成绩
-- avg if avg >= 60 show msg and avg
select std.s_id, std.s_name, avg(s.s_score)
from student std
         left join score s on std.s_id = s.s_id
group by std.s_id
having avg(s.s_score) >= 60;
-- 4、查询平均成绩小于60分的同学的学生编号和学生姓名和平均成绩
-- (包括有成绩的和无成绩的)
-- avg if avg < 60 show msg and avg
select std.s_id,std.s_name,round(avg(ifnull(s.s_score, 0)), 2) v_score
from student std
         left join score s on std.s_id = s.s_id
group by std.s_id
having v_score < 60;

-- union 并集, union all 全集

select b.s_id,b.s_name,ROUND(AVG(a.s_score),2) as avg_score from
    student b
    left join score a on b.s_id = a.s_id
    GROUP BY b.s_id,b.s_name HAVING ROUND(AVG(a.s_score),2)<60
    union
select a.s_id,a.s_name,0 as avg_score from
    student a
    where a.s_id not in (
                select distinct s_id from score);
-- 5、查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩
-- all show id,name,count(c_id),sum(s_score)
select std.s_id,std.s_name,count(s.c_id),sum(ifnull(s.s_score, 0)) from student std
    left join score s on std.
        s_id = s.s_id group by std.s_id;
-- 6、查询"李"姓老师的数量
select count(1) from teacher where t_name like('李%');
-- 7、查询学过"张三"老师授课的同学的信息
-- std if list(c_id) not contain '张三'
select std.* from student std
    join score s on std.s_id = s.s_id
    join course c on s.c_id = c.c_id
    join teacher t on c.t_id = t.t_id and t.t_name = '张三' group by std.s_id;

select std.*
from student std
         join score s on std.s_id = s.s_id
        where s.c_id in(select c.c_id from course c where c.t_id = (select t_id from teacher where t_name = '张三'));
-- 8、查询没学过"张三"老师授课的同学的信息
-- std if '张三' not in list(course)
select *
from student std
where std.s_id not in (
    select std.s_id
    from student std
             join score s on std.s_id = s.s_id
    where s.c_id in (
        select c.c_id from course c where c.t_id = (select t.t_id from teacher t where t.t_name = '张三'))
);

select *
from student std
where std.s_id not in (
    select std.s_id
    from student std
             join score s on std.s_id = s.s_id
             join course c on s.c_id = c.c_id
             join teacher t on c.t_id = t.t_id and t.t_name = '张三'
    group by std.s_id
);
-- 9、查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息
-- std if 01 02 in list(course) show msg
select std.*,s.c_id,s2.c_id from student std
    join score s on std.s_id = s.s_id and s.c_id = '01'
    join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
group by std.s_id;

-- 10、查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息
-- std if 01 in course and o2 not in course show msg
select *
from student std
where std.s_id in (select s.s_id from score s where s.c_id = '01')
  and std.s_id not in (select s.s_id from score s where s.c_id = '02');

-- 11、查询没有学全所有课程的同学的信息, 不包含没有学任何课的同学
-- std if 01 02 03 in list(course) and list(course) is not null show msg
select *
from student std
where std.s_id in (
    select sc.s_id
    from score sc
    where sc.s_id not in (
        select s1.s_id
        from score s1
                 join score s2 on s1.s_id = s2.s_id and s2.c_id = '02'
                 join score s3 on s1.s_id = s3.s_id and s3.c_id = '03'
        where s1.c_id = '01'
    )
);


select s.* from
    student s where s.s_id in(
        select s_id from score where s_id not in(
            select a.s_id from score a
                join score b on a.s_id = b.s_id and b.c_id='02'
                join score c on a.s_id = c.s_id and c.c_id='03'
            where a.c_id='01'));
-- 12、查询至少有一门课与学号为"01"的同学所学相同的同学的信息
-- std if course in 01.course
select *
from student std
where std.s_id in (
    select sc.s_id
    from score sc
    where sc.s_id != '01'
      and sc.c_id in (select c_id from score s where s.s_id = '01')
);

select *
from student
where s_id in (
    select distinct a.s_id from score a where a.c_id in (select a.c_id from score a where a.s_id = '01')
);

-- 13、查询和"01"号的同学学习的课程完全相同的其他同学的信息
-- std if std.course == 01.course show msg
select *
from student std
where std.s_id in (
    select sc.s_id
    from score sc
    where sc.s_id != '01'
      and sc.c_id in (select s.c_id from score s where s.s_id = '01')
    group by sc.s_id
    having count(1) = (select count(1) from score sc where sc.s_id = '01')
);

select a.* from student a where a.s_id in(
    select distinct s_id from score where s_id!='01' and c_id in(select c_id from score where s_id='01')
    group by s_id
    having count(1)=(select count(1) from score where s_id='01'));
-- 14、查询没学过"张三"老师讲授的任一门课程的学生姓名
-- 查询张三老师讲过的课
-- 查询所有学生的上课记录

-- 查询##学过##"张三"老师讲授的任一门课程的学生姓名
-- 查询没有学过"张三"老师讲授的任一门课程的学生姓名

-- 15、查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
-- 查询>=两门不及格的学生
-- 同学的学号，姓名及其平均成绩

-- 16、检索"01"课程分数小于60，按分数降序排列的学生信息

-- 17、按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩
-- 查询所有学生的所学的课程的成绩

/* 18.查询各科成绩最高分、最低分和平均分：以如下形式显示：课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90 */
-- 19、按各科成绩进行排序，并显示排名(实现不完全)
-- mysql没有rank函数
-- 20、查询学生的总成绩并进行排名







