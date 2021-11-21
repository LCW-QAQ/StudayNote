-- 1、查询"01"课程比"02"课程成绩高的学生的信息及课程分数
select *
from student s
         join score s2 on s.s_id = s2.s_id and s2.c_id = '01'
         join score s3 on s.s_id = s3.s_id and s3.c_id = '02'
where s2.s_score > s3.s_score;
-- 2、查询"01"课程比"02"课程成绩低的学生的信息及课程分数
select *
from student s
         join score s2 on s.s_id = s2.s_id and s2.c_id = '01'
         join score s3 on s.s_id = s3.s_id and s3.c_id = '02'
where s2.s_score < s3.s_score;
-- 3、查询平均成绩大于等于60分的同学的学生编号和学生姓名和平均成绩
select s.s_id,s.s_name,avg(s2.s_score)
from student s
         join score s2 on s.s_id = s2.s_id
group by s2.s_id
having avg(s2.s_score) >= 60;
-- 4、查询平均成绩小于60分的同学的学生编号和学生姓名和平均成绩
select s.s_id, s.s_name, avg(s2.s_score)
from student s
         join score s2 on s.s_id = s2.s_id
group by s2.s_id
having avg(s2.s_score) <= 60
union
select s.s_id, s.s_name, avg(0)
from student s
where s.s_id not in (select s_id from score);
-- (包括有成绩的和无成绩的)
-- 5、查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩
select s.s_id, s.s_name, count(s2.c_id), sum(s2.s_score)
from student s
         left join score s2 on s.s_id = s2.s_id group by s.s_id,s.s_name;
-- 6、查询"李"姓老师的数量
select count(*) from teacher
-- 7、查询学过"张三"老师授课的同学的信息
select st.s_id,st.s_name,t.t_name from student st join score sc on st.s_id = sc.s_id
join course co on sc.c_id = co.c_id
join teacher t on co.t_id = t.t_id and t.t_name = '张三';
-- 8、查询没学过"张三"老师授课的同学的信息
select st.s_id,st.s_name,t.t_name from student st join score s on st.s_id = s.s_id
join course c on s.c_id = c.c_id
join teacher t on c.t_id = t.t_id and t.t_name != '张三';
-- 9、查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息
select st.*
from student st
         join score sc on st.s_id = sc.s_id and sc.c_id = '01'
         join score sc2 on st.s_id = sc2.s_id and sc2.c_id = '02';
-- 10、查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息
select st.*
from student st
         join score sc on st.s_id = sc.s_id and sc.c_id = '01'
where st.s_id not in (select s_id from score where c_id = '02');
-- 11、查询没有学全所有课程的同学的信息
-- 学了01,02,03课程的学生
select st.*
from student st
where st.s_id in (select sc.s_id
                      from score sc
                      where sc.s_id not in (select sc.s_id
                                            from score sc
                                                     join score sc2 on sc.s_id = sc2.s_id and sc2.c_id = '02'
                                                     join score sc3 on sc.s_id = sc3.s_id and sc3.c_id = '03'
                                            where sc.c_id = '01'));

-- 12、查询至少有一门课与学号为"01"的同学所学相同的同学的信息
-- 学号为01的同学所学的课程
select distinct st.*
from student st
         join score s on st.s_id = s.s_id
where s.c_id in
      (select s.c_id from score s where s.s_id = '01');
-- 13、查询和"01"号的同学学习的课程完全相同的其他同学的信息
-- 查询01号同学学习的课程
select c_id from score where s_id = '01';
-- 查询学习课程与01号同学一样的同学(排除01号同学)
select s_id
from score
where s_id != '01'
  and c_id in (select c_id from score where s_id = '01')
group by s_id
having count(1) = (select count(1) from score where s_id = '01');

select st.*
from student st
where s_id in (select s_id
               from score
               where s_id != '01'
                 and c_id in (select c_id from score where s_id = '01')
               group by s_id
               having count(1) = (select count(1) from score where s_id = '01'));
-- 14、查询没学过"张三"老师讲授的任一门课程的学生姓名
-- 查询张三老师讲过的课
select t_id from teacher where t_name = '张三';
select c_id from course where t_id in(select t_id from teacher where t_name = '张三');
-- 查询所有学生的上课记录
select * from score;
-- 查询##学过##"张三"老师讲授的任一门课程的学生姓名
select s_id
from score
where c_id in (select c_id from course where t_id in (select t_id from teacher where t_name = '张三'));
-- 查询没有学过"张三"老师讲授的任一门课程的学生姓名
select *
from student
where s_id not in (select s_id
                   from score
                   where c_id in
                         (select c_id from course where t_id in (select t_id from teacher where t_name = '张三')));

select a.s_name from student a where a.s_id not in (
    select s_id from score where c_id =
                (select c_id from course where t_id =(
                    select t_id from teacher where t_name = '张三'))
                group by s_id);

-- 15、查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
-- 查询>=两门不及格的学生
select s_id,avg(s_score) from score where s_score < 60 group by s_id having  count(1) >= 2;
-- 同学的学号，姓名及其平均成绩
select st.s_id, st.s_name, round(m.vscore,2)
from student st
         join (select s_id, avg(s_score) vscore from score where s_score < 60 group by s_id having count(1) >= 2) m
              on st.s_id = m.s_id;

-- 16、检索"01"课程分数小于60，按分数降序排列的学生信息
select st.s_id,st.s_name,sc.s_score
from student st
         join score sc on st.s_id = sc.s_id and sc.c_id = '01'
where sc.s_score < 60
order by sc.s_score desc;
-- 17、按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩
-- 查询所有学生的所学的课程的成绩
select sc.s_id,
       (select ifnull(s_score,0) from score where s_id=sc.s_id and c_id='01') 语文,
       (select ifnull(s_score,0) from score where s_id=sc.s_id and c_id='02') 数学,
       (select ifnull(s_score,0) from score where s_id=sc.s_id and c_id='03') 英语,
       round(avg(s_score),2) 平均分
from score sc group by sc.s_id order by 平均分 desc;


select a.s_id,
       (select s_score from score where s_id = a.s_id and c_id = '01') as 语文,
       (select s_score from score where s_id = a.s_id and c_id = '02') as 数学,
       (select s_score from score where s_id = a.s_id and c_id = '03') as 英语,
       round(avg(s_score), 2)                                          as 平均分
from score a
GROUP BY a.s_id
ORDER BY 平均分 DESC;

/* 18.查询各科成绩最高分、最低分和平均分：以如下形式显示：课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90 */
-- 19、按各科成绩进行排序，并显示排名(实现不完全)
-- mysql没有rank函数
-- 20、查询学生的总成绩并进行排名







