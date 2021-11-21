-- 1、查询"01"课程比"02"课程成绩高的学生的信息及课程分数
select stu.*, s1.s_score s1, s2.s_score s2
from student stu
         join score s1 on stu.s_id = s1.s_id and s1.c_id = '01'
         join score s2 on stu.s_id = s2.s_id and s2.c_id = '02'
where s1.s_score > s2.s_score;

-- 2、查询"01"课程比"02"课程成绩低的学生的信息及课程分数
select stu.*, s1.s_score s1, s2.s_score s2
from student stu
         join score s1 on stu.s_id = s1.s_id and s1.c_id = '01'
         join score s2 on stu.s_id = s2.s_id and s2.c_id = '02'
where s1.s_score < s2.s_score;

-- 3、查询平均成绩大于等于60分的同学的学生编号和学生姓名和平均成绩
select stu.s_id, stu.s_name, round(avg(s.s_score), 2)
from student stu
         join score s on stu.s_id = s.s_id
group by stu.s_id
having avg(s.s_score) >= 60;

-- 4、查询平均成绩小于60分的同学的学生编号和学生姓名和平均成绩 (包括有成绩的和无成绩的)
select stu.s_id, stu.s_name, round(avg(ifnull(s.s_score, 0)), 2) avg_score
from student stu
         left join score s on stu.s_id = s.s_id
group by stu.s_id
having avg_score < 60;

-- 5、查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩
select stu.s_id, stu.s_name, count(s.c_id) sum_cource, sum(ifnull(s.s_score, 0)) sum_score
from student stu
         left join score s on stu.s_id = s.s_id
group by stu.s_id;

-- 6、查询"李"姓老师的数量
select count(t.t_name)
from teacher t
where t.t_name like '李%';

-- 7、查询学过"张三"老师授课的同学的信息
select stu.*
from student stu
         join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
         join teacher t on c.t_id = t.t_id
where t.t_name = '张三';

select stu.s_id
from student stu
where stu.s_id in (select s.s_id
                   from score s
                   where s.c_id in (select c.c_id
                                    from course c
                                    where c.t_id in (select t_id from teacher where t_name = '张三')))

-- 8、查询没学过"张三"老师授课的同学的信息
select stu.*
from student stu
         left join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
         join teacher t on c.t_id = t.t_id
where t.t_name != '张三';

-- 9、查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息
select *
from student stu
         join score s1 on stu.s_id = s1.s_id and s1.c_id = '01'
         join score s2 on stu.s_id = s2.s_id and s2.c_id = '02';

-- 10、查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息
select stu.*
from student stu
         join score s1 on stu.s_id = s1.s_id and s1.c_id = '01'
where stu.s_id not in (select s.s_id from score s where s.c_id = '02');

-- 11、查询没有学全所有课程的同学的信息
select *
from student stu
where stu.s_id not in (select sc1.s_id
                       from score sc1
                                join score sc2 on sc1.s_id = sc2.s_id and sc2.c_id = '02'
                                join score sc3 on sc1.s_id = sc3.s_id and sc3.c_id = '03'
                       where sc1.c_id = '01');

-- 12、查询至少有一门课与学号为"01"的同学所学相同的同学的信息
select *
from student stu
where stu.s_id in (select sc.s_id
                   from score sc
                   where sc.c_id in (select sc.c_id
                                     from score sc
                                     where sc.s_id = '01'
                   ));

-- 13、查询和"01"号的同学学习的课程完全相同的其他同学的信息
select *
from student stu
where stu.s_id in (select sc.s_id
                   from score sc
                   where sc.s_id != '01'
                     and sc.c_id in (select c_id from score where s_id = '01')
                   group by sc.s_id
                   having count(1) = (select count(1) from score where s_id = '01')
);

-- 14、查询没学过"张三"老师讲授的任一门课程的学生姓名
select stu.s_name
from student stu
where stu.s_id not in (select sc.s_id
                       from score sc
                       where sc.c_id in (select c.c_id
                                         from course c
                                         where c.t_id = (select t.t_id
                                                         from teacher t
                                                         where t.t_name = '张三'
                                         )));

-- 15、查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
select stu.s_name, round(avg(s.s_score), 2)
from student stu
         join score s on stu.s_id = s.s_id
where stu.s_id in (select sc.s_id
                   from score sc
                   where sc.s_score < 60
                   group by sc.s_id
                   having count(1) >= 2)
group by stu.s_id;

-- 16、检索"01"课程分数小于60，按分数降序排列的学生信息
select stu.*, sc.s_score
from score sc
         join student stu on sc.s_id = stu.s_id
where sc.s_score < 60
  and sc.c_id = '01'
order by sc.s_score desc;

-- 17、按平均成绩从高到低显示 所有学生的所有课程的成绩以及平均成绩
select sc.s_id,
       (select if(count(1) = 1, s_score, 0) from score where s_id = sc.s_id and c_id = '01') 语文,
       (select if(count(1) = 1, s_score, 0) from score where s_id = sc.s_id and c_id = '02') 数学,
       (select if(count(1) = 1, s_score, 0) from score where s_id = sc.s_id and c_id = '03') 英语,
       round(avg(sc.s_score), 2)                                                             avg_score
from score sc
group by sc.s_id
order by avg_score desc;

-- 18.查询各科成绩最高分、最低分和平均分：以如下形式显示：课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
-- 及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90
select c.c_id,
       c.c_name,
       max(sc.s_score)                                                                          最高分,
       min(sc.s_score)                                                                          最低分,
       round(avg(sc.s_score), 2)                                                                平均分,
       round(100 * sum(if(sc.s_score >= 60, 1, 0)) / count(sc.s_score), 2)                      及格率,
       round(100 * sum(if(sc.s_score >= 70 and sc.s_score <= 80, 1, 0)) / count(sc.s_score), 2) 中等率,
       round(100 * sum(if(sc.s_score >= 80 and sc.s_score <= 90, 1, 0)) / count(sc.s_score), 2) 优良率,
       round(100 * sum(if(sc.s_score >= 90, 1, 0)) / count(sc.s_score), 2)                      优秀率
from score sc
         join course c on sc.c_id = c.c_id
group by c.c_id;

-- 19、按各科成绩进行排序，并显示排名(实现不完全)
-- mysql没有rank函数
-- 这题操作很秀
-- 总结: 在需要对一张表的X字段具体类型(X1, X2, X3)分别排序时的解决方案

-- 分数一样时, 保留排名
-- 遍历score表, 提取出一条A数据
-- 再次遍历score表, 提取出与A数据相同科目的AA数据集合, 找出AA数据集合中比A数据分数大的, 有N条, 那么A数据排名为N + 1
select sc.*, (select count(1) from score where c_id = sc.c_id and s_score > sc.s_score) + 1 as px
from score sc
order by sc.c_id, px;

select sc.*, (select count(s_score) from score where c_id = sc.c_id and s_score > sc.s_score) + 1 px
from score sc
order by sc.c_id, px;

-- 分数一样时, 合并名次
-- 遍历score表, 提取出一条A数据
-- 再次遍历score表, 提取出与A数据相同科目的AA数据集合, 找出AA数据集合中比A数据分数大的, 有N条, 去重, 那么A数据排名为(distinct N) + 1
select sc.*, (select count(distinct s_score) from score where c_id = sc.c_id and s_score > sc.s_score) + 1 as px
from score sc
order by sc.c_id, px;

-- 使用mysql 8.0 rank函数
-- 重复时保留名次
select t.*, px = rank() over (partition by c_id order by s_score desc)
from score t
order by t.c_id, px;
-- 重复时合并名次
select t.*, px = DENSE_RANK() over (partition by c_id order by s_score desc)
from score t
order by t.c_id, px;

-- 20、查询学生的总成绩并进行排名
select sc.s_id, sum(sc.s_score) sum_score
from score sc
group by sc.s_id
order by sum_score desc;

# ?---: 感觉只需要@i就能表示排名了
select rk_tbl.s_id,
       @i := @i + 1                                  as 'index',
       @k := (if(@score = rk_tbl.sum_score, @k, @i)) as 'rank',
       rk_tbl.sum_score
from (select sc.s_id, sum(sc.s_score) sum_score
      from score sc
      group by sc.s_id
      order by sum_score desc) rk_tbl,
     (select @rank := 0, @i := 0, @score := 0) var;

select a.s_id,
       @i := @i + 1                                               as i,
       @k := (case when @score = a.sum_score then @k else @i end) as 'rank',
       @score := a.sum_score                                      as score
from (select s_id, SUM(s_score) as sum_score from score GROUP BY s_id ORDER BY sum_score DESC) a,
     (select @k := 0, @i := 0, @score := 0) s;

-- 自交法
select sc.s_id, sum(sc.s_score)
from score sc
group by sc.s_id;

select rank_rbl.s_id,
       sum_score,
       (select count(r.sum_score)
        from (select sc.s_id, sum(sc.s_score) sum_score
              from score sc
              group by sc.s_id) r
        where r.sum_score > rank_rbl.sum_score) + 1 as px
from (select sc.s_id, sum(sc.s_score) sum_score
      from score sc
      group by sc.s_id) rank_rbl
order by px;

-- 21、查询不同老师所教不同课程平均分从高到低显示
select t.t_name, c.c_name, avg(s.s_score) avg_score
from course c
         join score s
              on c.c_id = s.c_id
         join teacher t on c.t_id = t.t_id
group by c.c_id
order by avg_score desc;

-- 22、查询所有课程的成绩第2名到第3名的学生信息及该课程成绩
-- 分数一样合并排名
select stu.s_name,
       c.c_name,
       c.c_id,
       s.s_score,
       (select count(distinct s_score) from score where c_id = s.c_id and s_score > s.s_score) + 1 as rk
from course c
         join score s on c.c_id = s.c_id
         join student stu on s.s_id = stu.s_id
having rk >= 2
   and rk <= 3
order by c.c_id, rk;

-- 23、统计各科成绩各分数段人数：课程编号,课程名称,[100-85],[85-70],[70-60],[0-60]及所占百分比
select c.c_id,
       c.c_name,
       (select count(s_score) from score where c_id = s.c_id and s_score <= 100 and s_score > 85) as '[100-85]',
       (round(100 * (select count(s_score) from score where c_id = s.c_id and s_score <= 100 and s_score > 85) /
              count(1), 2))                                                                       as '[100-85]%',
       (select count(s_score) from score where c_id = s.c_id and s_score <= 85 and s_score > 70)  as '[85-70]',
       (round(100 * (select count(s_score) from score where c_id = s.c_id and s_score <= 85 and s_score > 70) /
              count(1), 2))                                                                       as '[85-70]%',
       (select count(s_score) from score where c_id = s.c_id and s_score <= 70 and s_score > 60)  as '[70-60]',
       (round(100 * (select count(s_score) from score where c_id = s.c_id and s_score <= 70 and s_score > 60) /
              count(1), 2))                                                                       as '[70-60]%',
       (select count(s_score) from score where c_id = s.c_id and s_score <= 60 and s_score > 0)   as '[60-0]',
       (round(100 * (select count(s_score) from score where c_id = s.c_id and s_score <= 60 and s_score > 0) /
              count(1), 2))                                                                       as '[60-0]%'
from score s
         join course c on s.c_id = c.c_id
group by s.c_id;

-- 24、查询学生平均成绩及其名次
select rk_tbl.s_id,
       rk_tbl.avg_score,
       @i := @i + 1                                    as '分数一样不合并排名',
       @k := if(@avg_score = rk_tbl.avg_score, @k, @i) as '分数一样保留排名',
       @avg_score := rk_tbl.avg_score
from (select s.s_id,
             round(avg(s.s_score), 2) as avg_score
      from score s
      group by s.s_id
      order by avg_score desc) rk_tbl,
     (select @i := 0, @k := 0, @avg_score := 0) var;

-- 25、查询各科成绩前三名的记录
select s.c_id,
       s.s_score,
       (select count(distinct s_score) from score where c_id = s.c_id and s_score > s.s_score) + 1 as rk
from score s
having rk between 1 and 3
order by s.c_id, rk;

-- 26、查询每门课程被选修的学生数
select c.c_name, count(s.s_score)
from score s
         right join course c on s.c_id = c.c_id
group by c.c_id;

-- 27、查询出只有两门课程的全部学生的学号和姓名
select s_id
from score
group by s_id
having count(c_id) = 2;

select *
from student stu
where s_id in (select s_id
               from score
               group by s_id
               having count(c_id) = 2);

-- 28、查询男生、女生人数
select s_sex, count(s_sex)
from student
group by s_sex;

-- 29、查询名字中含有"风"字的学生信息
select *
from student
where s_name like '%风%';

-- 30、查询同名同性学生名单，并统计同名人数
select s1.*, count(1)
from student s1
         join student s2 on s1.s_id != s2.s_id and s1.s_name = s2.s_name and s1.s_sex = s2.s_sex
group by s1.s_name, s1.s_sex;

-- 31、查询1990年出生的学生名单
select *
from student
where s_birth like '1990%';

select *
from student
where year(s_birth) = '1990';

-- 32、查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列
select round(avg(s_score), 2) as avg_score
from score
group by c_id
order by avg_score desc, c_id;

-- 33、查询平均成绩大于等于85的所有学生的学号、姓名和平均成绩
select stu.*, round(avg(s.s_score), 2) as avg_score
from student stu
         join score s on stu.s_id = s.s_id
group by stu.s_id
having avg_score >= 85;

-- 34、查询课程名称为"数学"，且分数低于60的学生姓名和分数
select stu.*, s.s_score
from score s
         join course c on s.c_id = c.c_id
         join student stu on s.s_id = stu.s_id
where c.c_name = '数学'
  and s.s_score < 60;

-- 35、查询所有学生的课程及分数情况
select stu.s_id,
       stu.s_name,
       sum(if(c.c_name = '数学', s.s_score, 0)) as '数学',
       sum(if(c.c_name = '语文', s.s_score, 0)) as '语文',
       sum(if(c.c_name = '英语', s.s_score, 0)) as '英语',
       sum(s.s_score)                         as '总分'
from student stu
         join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
group by stu.s_id;

-- 36、查询任何一门课程成绩在70分以上的姓名、课程名称和分数
select stu.s_name, c.c_name, s.s_score
from student stu
         join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
where s.s_score > 70;

-- 37、查询不及格的课程
select sc.s_id, sc.c_id, c.c_name, sc.s_score
from score sc
         join course c on sc.c_id = c.c_id
where sc.s_score < 60;

-- 38、查询课程编号为01且课程成绩在80分以上的学生的学号和姓名
select stu.s_id, stu.s_name
from student stu
         join score s on stu.s_id = s.s_id
where s.c_id = '01'
  and s.s_score > 80;

-- 39、求每门课程的学生人数
select count(1)
from score s
group by s.c_id;

-- 40、查询选修"张三"老师所授课程的学生中，成绩最高的学生信息及其成绩
select stu.s_name, max(sc.s_score)
from score sc
         join course c on sc.c_id = c.c_id
         join teacher t on c.t_id = t.t_id
         join student stu on sc.s_id = stu.s_id
where t.t_name = '张三';

-- 41、查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩
select distinct sc1.s_id, sc1.c_id, sc1.s_score
from score sc1
         join score sc2
where sc1.c_id != sc2.c_id
  and sc1.s_score = sc2.s_score;

select stu.s_name, t.*
from student stu,
     (select distinct sc1.s_id, sc1.c_id, sc1.s_score
      from score sc1
               join score sc2
      where sc1.c_id != sc2.c_id
        and sc1.s_score = sc2.s_score) t
where stu.s_id = t.s_id;

-- 42、查询每门功成绩最好的前两名
select sc.s_id, sc.c_id, sc.s_score
from score sc
where (select count(1) from score where c_id = sc.c_id and s_score >= sc.s_score) <= 2
order by sc.c_id;

-- 43、统计每门课程的学生选修人数（超过5人的课程才统计）。要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列
select s.c_id, count(1) as total
from score s
group by s.c_id
having total > 5
order by total desc, c_id;

-- 44、检索至少选修两门课程的学生学号
select sc.s_id, count(sc.c_id) as total
from score sc
group by sc.s_id
having total >= 2;

-- 45、查询选修了全部课程的学生信息
select *
from student stu
where stu.s_id in (select s_id
                   from score
                   group by s_id
                   having count(c_id) = (select count(1) from course));

-- 46、查询各学生的年龄
select s_id,
       s_birth,
       (date_format(now(), '%Y') - date_format(s_birth, '%Y')) -
       (if(DATE_FORMAT(NOW(), '%m%d') > DATE_FORMAT(s_birth, '%m%d'), 0, 1)) as age
from student;

-- 47、查询本周过生日的学生
select *
from student
where yearweek(s_birth) = yearweek(date_format(now(), '%Y%m%d'));

-- 48、查询下周过生日的学生
select *
from student
where week(date_format(now(), '%Y%m%d')) + 1 = week(s_birth);

-- 49、查询本月过生日的学生
select *
from student
where month(date_format(now(), '%Y%m%d')) = month(s_birth);

-- 50、查询下月过生日的学生
select *
from student
where month(date_format(now(), '%Y%m%d')) + 1 = month(s_birth);