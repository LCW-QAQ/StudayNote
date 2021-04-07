-- 1.学生表 
-- Student(s_id,s_name,s_birth,s_sex) –学生编号,学生姓名, 出生年月,学生性别 
-- 2.课程表 
-- Course(c_id,c_name,t_id) – –课程编号, 课程名称, 教师编号 
-- 3.教师表 
-- Teacher(t_id,t_name) –教师编号,教师姓名 
-- 4.成绩表 
-- Score(s_id,c_id,s_score) –学生编号,课程编号,分数
select * from student;
select * from course;
select * from teacher;
select * from score;
-- 1、查询"01"课程比"02"课程成绩高的学生的信息及课程分数
select stu.*,s.s_score,s2.s_score from student stu
    left join score s on stu.s_id = s.s_id and s.c_id = '01'
    left join score s2 on stu.s_id = s2.s_id and s2.c_id = '02'
where s.s_score > s2.s_score;
-- 2、查询"01"课程比"02"课程成绩低的学生的信息及课程分数
select stu.*,s.s_score,s2.s_score from student stu
    left join score s on stu.s_id = s.s_id and s.c_id = '01'
    left join score s2 on stu.s_id = s2.s_id and s2.c_id = '02'
where s.s_score < s2.s_score;
-- 3、查询平均成绩大于等于60分的同学的学生编号和学生姓名和平均成绩
select stu.s_id,stu.s_name,avg(IFNULL(s.s_score, 0)) avgScore from student stu
    left join score s on stu.s_id = s.s_id group by stu.s_id having avg(ifnull(s.s_score, 0)) >= 60;
-- 4、查询平均成绩小于60分的同学的学生编号和学生姓名和平均成绩
-- (包括有成绩的和无成绩的)
select stu.s_id,stu.s_name,avg(IFNULL(s.s_score, 0)) avgScore from student stu
    left join score s on stu.s_id = s.s_id group by stu.s_id having avg(ifnull(s.s_score, 0)) <= 60;
-- 5、查询所有同学的学生编号、学生姓名、选课总数、所有课程的总成绩
select stu.s_id,stu.s_name,count(*) count,sum(ifnull(s.s_score, 0)) sumScore
from student stu
    left join score s on stu.s_id = s.s_id group by stu.s_id;
-- 6、查询"李"姓老师的数量
select count(*) from teacher where t_name like('李%');
-- 7、查询学过"张三"老师授课的同学的信息
select stu.* from student stu
    left join score s on stu.s_id = s.s_id
    left join course c on s.c_id = c.c_id
where c.t_id in(select teacher.t_id from teacher where t_name like '张三');
-- 8、查询没学过"张三"老师授课的同学的信息
select *
from student t_stu
where s_id not in (select stu.s_id
                   from student stu
                            left join score s on stu.s_id = s.s_id
                            left join course c on s.c_id = c.c_id
                   where c.t_id in (select t_id from teacher where t_name like '张三'));
-- 9、查询学过编号为"01"并且也学过编号为"02"的课程的同学的信息
select stu.*
from student stu
         join score s on stu.s_id = s.s_id and s.c_id = '01'
         join score s2 on stu.s_id = s2.s_id and s2.c_id = '02';
-- 10、查询学过编号为"01"但是没有学过编号为"02"的课程的同学的信息
select *
from student stu
where stu.s_id in (select score.s_id from score where c_id = '01')
  and stu.s_id not in (select score.s_id from score where c_id = '02');
-- 11、查询没有学全所有课程的同学的信息
select stu.*
from student stu
where stu.s_id in (select s.s_id
                   from score s
                   where s.s_id not in (select s.s_id
                                        from score s
                                                 join score s2 on s.s_id = s2.s_id and s2.c_id = '01'
                                                 join score s3 on s.s_id = s3.s_id and s3.c_id = '02'
                                        where s.c_id = '03'));
-- 12、查询至少有一门课与学号为"01"的同学所学相同的同学的信息
select distinct stu.*
from student stu
         join score s on stu.s_id = s.s_id
where stu.s_id != '01'
  and s.c_id in (select c_id from score s where s.s_id = '01');
-- 13、查询和"01"号的同学学习的课程完全相同的其他同学的信息 ***********************************
-- 首先查询 01 同学学了什么课
select c_id from score where s_id = '01';
-- 那些同学学了 01 同学学过的任意一门课
select * from score s where s.c_id in(select c_id from score where s_id = '01') group by s.s_id;
-- 学过 01 同学学过的任意一门课, 并且所学课程数量与01同学一样, 我们可以认为他学的课和01同学一样
select s.s_id
from score s
where s.c_id in (select c_id from score where s_id = '01')
  and s.s_id != '01'
group by s.s_id
having count(*) = (select count(*) from score where s_id = '01');
-- 14、查询没学过"张三"老师讲授的任一门课程的学生姓名
-- 张三老师的课
select c_id from course c where c.t_id in(select t_id from teacher where t_name like('张三'));
-- 没学过上一个sql结果(张三老师的课)的同学
-- -> 对于这种N多个数据没有满足条件condition的情况, 通常更适合先找到满足条件的, 再用not in来筛选
-- 通常sql查询, 多数据多情况 对 单条件, 更加适合先找到 多数据单情况(满足条件的情况) 对 单条件再反举例 -> 这个描述也太抽象了吧.....
# 错误范例
# select s_id from score s where s.c_id not in(
#     select c_id from course c where c.t_id in(select t_id from teacher where t_name like('张三'))
#     ) group by s.s_id;
-- 学过张三老师课的学生
select stu.*
from student stu
where stu.s_id not in (select s.s_id
                       from score s
                       where s.c_id in (select c_id
                                        from course c
                                        where c.t_id in (select t_id from teacher where t_name like ('张三'))));
-- 15、查询两门及其以上不及格课程的同学的学号，姓名及其平均成绩
-- 查询不及格的同学
select * from score s where s.s_score < 60 group by s.s_id;
-- 限定必须 >= 两门课不及格
select s.s_id,avg(s.s_score) from score s where s.s_score < 60 group by s.s_id having count(*) >= 2;

select stu.s_name, m.vscore
from student stu
         join (select s.s_id, avg(s.s_score) vscore
               from score s
               where s.s_score < 60
               group by s.s_id
               having count(*) >= 2) m
              on stu.s_id = m.s_id;
-- 16、检索"01"课程分数小于60，按分数降序排列的学生信息
select stu.*, s.s_score
from student stu
         join score s on stu.s_id = s.s_id and s.c_id = '01'
where s.s_score < 60
order by s.s_score desc;
-- 17、按平均成绩从高到低显示所有学生的所有课程的成绩以及平均成绩 ******************************
-- 所有学生的 所有课程的成绩 平均成绩
select stu.s_id,
       (select score.s_score from score where stu.s_id = score.s_id and score.c_id = '01') 语文,
       (select score.s_score from score where stu.s_id = score.s_id and score.c_id = '02') 数学,
       (select score.s_score from score where stu.s_id = score.s_id and score.c_id = '03') 语文,
       avg(s.s_score) 平均分
       from student stu
    left join score s on stu.s_id = s.s_id group by stu.s_id order by avg(s.s_score) desc;
-- 18.查询各科成绩最高分、最低分和平均分：以如下形式显示：***********************************************
            -- 课程ID，课程name，最高分，最低分，平均分，及格率，中等率，优良率，优秀率
            -- 及格为>=60，中等为：70-80，优良为：80-90，优秀为：>=90
select c.c_id,
       c_name,
       max(s.s_score)                                                                  最高分,
       min(s.s_score)                                                                  最低分,
       avg(s.s_score)                                                                  平均分,
       round(sum(if(s.s_score >= 60, 1, 0)) / sum(if(s.s_score, 1, 0)) * 100, 2) 及格率,
       round(sum(if(s.s_score < 90 and s.s_score >= 80, 1, 0)) / sum(if(s.s_score, 1, 0)) *
             100, 2)                                                                   优良率,
       round(sum(if(s.s_score < 80 and s.s_score >= 70, 1, 0)) / sum(if(s.s_score, 1, 0)) *
             100, 2)                                                                   中等率
from course c
         left join score s on c.c_id = s.c_id
group by c.c_id;
-- 19、按各科成绩进行排序，并显示排名(实现不完全) *****************************************************************************
-- mysql没有rank函数
# select a.s_id,a.c_id,
#         @i:=@i + 1 as i保留排名,
#         @k:=(case when @score=a.s_score then @k else @i end) as rank不保留排名,
#         @score:=a.s_score as score
#     from (
#         select s_id,c_id,s_score from score WHERE c_id='01' GROUP BY s_id,c_id,s_score ORDER BY s_score DESC
# )a,(select @k:=0,@i:=0,@score:=0)s
#     union
#     select a.s_id,a.c_id,
#         @i:=@i +1 as i,
#         @k:=(case when @score=a.s_score then @k else @i end) as rank,
#         @score:=a.s_score as score
#     from (
#         select s_id,c_id,s_score from score WHERE c_id='02' GROUP BY s_id,c_id,s_score ORDER BY s_score DESC
# )a,(select @k:=0,@i:=0,@score:=0)s
#     union
#     select a.s_id,a.c_id,
#         @i:=@i +1 as i,
#         @k:=(case when @score=a.s_score then @k else @i end) as rank,
#         @score:=a.s_score as score
#     from (
#         select s_id,c_id,s_score from score WHERE c_id='03' GROUP BY s_id,c_id,s_score ORDER BY s_score DESC
# )a,(select @k:=0,@i:=0,@score:=0)
-- 思路-1: 重复名次时, 保留名次空缺
-- 1.每条成绩映射 到与之相同科目的所有成绩   [1.class = N.class]  [1 -> N]
-- 2.从N条成绩过滤, 找出N条成绩中比1成绩高的 N' 条成绩   [N.score > 1.score]  [N -> 1]=>N'
-- 3.N'条成绩实际上就是, 在同一科目中, 比1成绩高的人数, 那么1的排名就是 count(N')+1
select t.s_id,
       (select count(s.s_score) from score s where s.c_id = t.c_id and s.s_score > t.s_score) + 1 ranking from score t;
-- 思路-1-实现:
select stu.s_name,c.c_name,m.s_score,m.ranking from student stu
join (select t.s_id,t.c_id,t.s_score,
       (select count(s.s_score) from score s where s.c_id = t.c_id and s.s_score > t.s_score) + 1 ranking from score t) m
on stu.s_id = m.s_id
join course c on c.c_id = m.c_id
order by m.c_id,m.ranking;

-- 思路-1: 重复名次时, 不保留名次空缺
-- 只需要在删选的时候, 去重score (名次相同的只记为1)
select stu.s_name,c.c_name,m.s_score,m.ranking from student stu
    join (select s.s_id,s.c_id,s.s_score,
       (select count(distinct sc.s_score) from score sc where sc.c_id = s.c_id and sc.s_score > s.s_score) + 1 ranking
from score s) m
on stu.s_id = m.s_id
join course c on c.c_id = m.c_id
order by m.c_id,m.ranking;

-- 变量实现的 连续 不分组 排名
select s.s_id,s.s_score,
       (@cur_rank := @cur_rank + 1) ranking
    from score s, (select @cur_rank := 0) r order by s.s_score desc;
-- 变量实现的 连续 分组 排名
select s.s_id,s.c_id,s_score,
       IF(@pre_c_id = s.c_id, @ranking := @ranking + 1, @ranking := 1) ranking,
       @pre_c_id := s.c_id
    from score s, (select @ranking := 0, @pre_c_id := NULL) vt
order by s.c_id, s.s_score desc;

-- 变量实现的 重复名次保留空缺 不分组 排名
select s.s_id,s.s_score,
       @counter := @counter + 1,
       if(@pre_score = s.s_score, @ranking, @ranking := @counter) 排名,
       @pre_score := s.s_score
from score s, (select @ranking := 0, @pre_score := NULL, @counter := 0) vt
order by s.s_score desc;
-- 变量实现的 重复名次保留空缺 分组 排名
select s.s_id,
       s.c_id,
       s.s_score,
       IF(@pre_c_id = s.c_id, @counter := @counter + 1, @counter := 1) temp,
       IF(@pre_c_id = s.c_id, IF(@pre_score = s.s_score, @ranking, @ranking := @counter), @ranking := 1) ranking,
       @pre_c_id := s.c_id,
       @pre_score := s.s_score
from score s,
     (select @ranking := 0, @pre_score := NULL, @counter := 0, @pre_c_id := NULL) vt
order by s.c_id, s.s_score desc;

-- 变量实现的 重复名次不保留空缺 不分组 排名
select s.s_id,s.s_score,
       if(@pre_score = s.s_score, @ranking, @ranking := @ranking + 1) 排名,
       @pre_score := s.s_score
from score s, (select @ranking := 0, @pre_score := NULL) vt
order by s.s_score desc;
-- 变量实现的 重复名次不保留空缺 分组 排名
select s.s_id,s.c_id,s.s_score,
       IF(@pre_c_id = s.c_id, IF(@pre_score = s.s_score, @ranking,@ranking := @ranking + 1), @ranking := 1) ranking,
       @pre_score := s.s_score,
       @pre_c_id := s.c_id
    from score s, (select @ranking := 0, @pre_score := NULL, @pre_c_id := NULL) vt
order by s.c_id, s.s_score desc;

-- 20、查询学生的总成绩并进行排名
# select a.s_id,
#     @i:=@i+1 as i,
#     @k:=(case when @score=a.sum_score then @k else @i end) as rank,
#     @score:=a.sum_score as score
# from (select s_id,SUM(s_score) as sum_score from score GROUP BY s_id ORDER BY sum_score DESC) a,
#     (select @k:=0,@i:=0,@score:=0);
select a.s_id,
       IF(@pre_score = a.sum_score, @ranking, @ranking := @ranking + 1) ranking,
       @pre_score := a.sum_score
from (select s.s_id,
             sum(s.s_score) sum_score
      from score s
      group by s.s_id
      order by sum_score desc) a,
     (select @ranking := 0, @pre_score := NULL) vt;
-- 21、查询不同老师所教不同课程平均分从高到低显示
select t.t_name, avg(s.s_score) vscore
from score s
         join course c on s.c_id = c.c_id
         join teacher t on c.t_id = t.t_id
group by t.t_id
order by vscore desc;
-- 22、查询所有课程的成绩第2名到第3名的学生信息及该课程成绩 *************************************
# select d.*,c.排名,c.s_score,c.c_id from (
#     select a.s_id,a.s_score,a.c_id,@i:=@i+1 as 排名 from score a,(select @i:=0)s where a.c_id='01'
# )c
# left join student d on c.s_id=d.s_id
# where 排名 BETWEEN 2 AND 3
# UNION
# select d.*,c.排名,c.s_score,c.c_id from (
#     select a.s_id,a.s_score,a.c_id,@j:=@j+1 as 排名 from score a,(select @j:=0)s where a.c_id='02'
# )c
# left join student d on c.s_id=d.s_id
# where 排名 BETWEEN 2 AND 3
# UNION
# select d.*,c.排名,c.s_score,c.c_id from (
#     select a.s_id,a.s_score,a.c_id,@k:=@k+1 as 排名 from score a,(select @k:=0)s where a.c_id='03'
# )c
# left join student d on c.s_id=d.s_id
# where 排名 BETWEEN 2 AND 3;
-- 用之前学过的子查询更加简单
select s.*,
       (select count(distinct sc.s_score) from score sc where sc.c_id = s.c_id and sc.s_score > s.s_score) + 1 ranking
from score s
order by s.c_id, s.s_score desc;

select * from (select s.*,
       (select count(distinct sc.s_score) from score sc where sc.c_id = s.c_id and sc.s_score > s.s_score) + 1 ranking
from score s
order by s.c_id, s.s_score desc) m
where m.ranking between 2 and 3;

-- 变量排名的方法
select s.*,
       IF(@pre_c_id = s.c_id, IF(@pre_score = s.s_score, @ranking, @ranking := @ranking + 1), @ranking := 1) ranking,
       @pre_score := s.s_score pre_score,
       @pre_c_id := s.c_id
from score s, (select @ranking := 0, @pre_score := NULL, @pre_c_id := NULL) vt
order by s.c_id,s.s_score desc;

select * from (select s.*,
       IF(@pre_c_id = s.c_id, IF(@pre_score = s.s_score, @ranking, @ranking := @ranking + 1), @ranking := 1) ranking,
       @pre_score := s.s_score pre_score,
       @pre_c_id := s.c_id
from score s, (select @ranking := 0, @pre_score := NULL, @pre_c_id := NULL) vt
order by s.c_id,s.s_score desc) m
where m.ranking between 2 and 3;


-- 23、统计各科成绩各分数段人数：课程编号,课程名称,[100-85],[85-70],[70-60],[0-60]及所占百分比 **********************************
# 课程名称 课程编号 [100-85] [85-70] [70-60] [0-60]
select c.c_name,c.c_id,
       SUM(case when s.s_score >= 85 and s.s_score <= 100 then 1 else 0 end) as "[85,100]",
       CONCAT(ROUND(SUM(case when s.s_score >= 85 and s.s_score <= 100 then 1 else 0 end)/count(*)*100, 2), '%') as Percent,
       SUM(case when s.s_score >= 70 and s.s_score < 85 then 1 else 0 end) as "[70,85)",
       CONCAT(ROUND(SUM(case when s.s_score >= 70 and s.s_score < 85 then 1 else 0 end)/count(*)*100, 2), '%') as Percent,
       SUM(case when s.s_score >= 60 and s.s_score < 70 then 1 else 0 end) as "[60,70)",
       CONCAT(ROUND(SUM(case when s.s_score >= 60 and s.s_score < 70 then 1 else 0 end)/count(*)*100, 2), '%') as Percent,
       SUM(case when s.s_score >= 0 and s.s_score < 60 then 1 else 0 end) as "[0,60)",
       CONCAT(ROUND(SUM(case when s.s_score >= 0 and s.s_score < 60 then 1 else 0 end)/count(*)*100, 2), '%') as Percent
       from score s
    join course c on s.c_id = c.c_id
group by c.c_id;

select m.c_id  课程编号  , m.c_name  课程名称  , (
  case when n.s_score >= 85 then '85-100'
       when n.s_score >= 70 and n.s_score < 85 then '70-85'
       when n.s_score >= 60 and n.s_score < 70 then '60-70'
       else '0-60'
  end) 分数段,
  count(1) 数量 ,
  cast(count(1) * 100.0 / (select count(1) from score where c_id = m.c_id) as decimal(18,2))  百分比
from Course m , score n
where m.c_id = n.c_id
group by m.c_id , m.c_name , (
  case when n.s_score >= 85 then '85-100'
       when n.s_score >= 70 and n.s_score < 85 then '70-85'
       when n.s_score >= 60 and n.s_score < 70 then '60-70'
       else '0-60'
  end)
order by m.c_id , m.c_name , 分数段;

# select distinct f.c_name,a.c_id,b.`85-100`,b.百分比,c.`70-85`,c.百分比,d.`60-70`,d.百分比,e.`0-60`,e.百分比 from score a
# left join (select c_id,SUM(case when s_score >85 and s_score <=100 then 1 else 0 end) as `85-100`,
#                             ROUND(100*(SUM(case when s_score >85 and s_score <=100 then 1 else 0 end)/count(*)),2) as 百分比
#                 from score GROUP BY c_id)b on a.c_id=b.c_id
# left join (select c_id,SUM(case when s_score >70 and s_score <=85 then 1 else 0 end) as `70-85`,
#                             ROUND(100*(SUM(case when s_score >70 and s_score <=85 then 1 else 0 end)/count(*)),2) as 百分比
#                 from score GROUP BY c_id)c on a.c_id=c.c_id
# left join (select c_id,SUM(case when s_score >60 and s_score <=70 then 1 else 0 end) as `60-70`,
#                             ROUND(100*(SUM(case when s_score >60 and s_score <=70 then 1 else 0 end)/count(*)),2) as 百分比
#                 from score GROUP BY c_id)d on a.c_id=d.c_id
# left join (select c_id,SUM(case when s_score >=0 and s_score <=60 then 1 else 0 end) as `0-60`,
#                             ROUND(100*(SUM(case when s_score >=0 and s_score <=60 then 1 else 0 end)/count(*)),2) as 百分比
#                 from score GROUP BY c_id)e on a.c_id=e.c_id
# left join course f on a.c_id = f.c_id;
-- 24、查询学生平均成绩及其名次 *************************************
select stu.s_id,
       stu.s_name,
       s.s_score,
       avg(IFNULL(s.s_score, 0)) vscore,
       (select count(distinct sc.s_score) from score sc where sc.c_id = s.c_id and sc.s_score > s.s_score) +
       1 ranking
from score s
join student stu on s.s_id = stu.s_id
group by stu.s_id,stu.s_name
order by ranking;

-- 25、查询各科成绩前三名的记录
select s.s_id,
       s.c_id,
       s.s_score,
       (select count(distinct sc.s_score) from score sc where sc.c_id=s.c_id and sc.s_score > s.s_score) + 1 ranking
from score s
order by s.c_id,s.s_score desc;

select stu.s_name,m.c_id,m.s_score,m.ranking from student stu
    join (select s.s_id,
                 s.c_id,
       s.s_score,
       (select count(distinct sc.s_score) from score sc where sc.c_id=s.c_id and sc.s_score > s.s_score) + 1 ranking
from score s
order by s.c_id, s.s_score desc) m
on stu.s_id = m.s_id
where m.ranking <= 3
order by m.c_id,m.s_score;

-- 26、查询每门课程被选修的学生数
select
       c.c_name,
    count(s.s_id)
    from score s
    join course c on s.c_id = c.c_id
group by c.c_id;

-- 27、查询出只有两门课程的全部学生的学号和姓名
select stu.*
from student stu
         join score sc on stu.s_id = sc.s_id
group by stu.s_id
having count(sc.c_id) = 2;
-- 28、查询男生、女生人数
select stu.s_sex,count(stu.s_sex) from student stu group by stu.s_sex;
-- 29、查询名字中含有"风"字的学生信息
select * from student where s_name like '%风%';
-- 30、查询同名同性学生名单，并统计同名人数
select stu1.s_id,stu1.s_name,count(1) from student stu1
    join student stu2
        on stu1.s_id != stu2.s_id and stu1.s_name = stu2.s_name and stu1.s_sex = stu2.s_sex
group by stu1.s_name;
-- 31、查询1990年出生的学生名单
select * from student where s_birth like '1990%';
-- 32、查询每门课程的平均成绩，结果按平均成绩降序排列，平均成绩相同时，按课程编号升序排列
select c.c_name, avg(s.s_score) avg_score from course c
    left join score s on c.c_id = s.c_id
    group by c.c_id order by avg_score desc, c.c_id asc;
-- 33、查询平均成绩大于等于85的所有学生的学号、姓名和平均成绩
select stu.s_id, stu.s_name, avg(s.s_score) avg_score
from student stu
         join score s on stu.s_id = s.s_id
where s.s_score >= 85
group by stu.s_id;
-- 34、查询课程名称为"数学"，且分数低于60的学生姓名和分数
select stu.s_name, s.s_score
from student stu
         join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
where c.c_name = '数学'
  and s.s_score < 60;
-- 35、查询所有学生的课程及分数情况；
select stu.s_id,
       stu.s_name,
       SUM(IF(c.c_name = '语文', s.s_score, 0)) 语文,
       SUM(IF(c.c_name = '数学', s.s_score, 0)) 数学,
       SUM(IF(c.c_name = '英语', s.s_score, 0)) 英语,
       SUM(s.s_score)                         总分
from student stu
         left join score s on stu.s_id = s.s_id
         left join course c on s.c_id = c.c_id
group by stu.s_id;
-- 36、查询任何一门课程成绩在70分以上的姓名、课程名称和分数；
select stu.s_name, c.c_name, s.s_score
from student stu
         join score s on stu.s_id = s.s_id
         join course c on s.c_id = c.c_id
where s.s_score > 70;
-- 37、查询不及格的课程
select stu.s_name, c.c_name, s.s_score
from student stu
         left join score s on stu.s_id = s.s_id
         left join course c on s.c_id = c.c_id
where s.s_score < 60;
-- 38、查询课程编号为01且课程成绩在80分以上的学生的学号和姓名；
select stu.s_id,stu.s_name from student stu
    join score s on stu.s_id = s.s_id
where s.c_id = '01' and s.s_score > 80;
-- 39、求每门课程的学生人数
select c.c_id,c.c_name,count(s.s_score) from score s
    join course c on s.c_id = c.c_id
group by c.c_id;
-- 40、查询选修"张三"老师所授课程的学生中，成绩最高的学生信息及其成绩
select stu.s_id, s.s_score from student stu
    join score s on stu.s_id = s.s_id
    join course c on s.c_id = c.c_id
    join teacher t on c.t_id = t.t_id
where t.t_name = '张三'
group by stu.s_id;

select stu.s_id, stu.s_name, s.s_score from student stu
    join score s on stu.s_id = s.s_id
    join course c on s.c_id = c.c_id
    join teacher t on c.t_id = t.t_id
where t.t_name = '张三' and s.s_score in(select MAX(s_score) from score sc where sc.c_id = c.c_id) # 注意有可能有多个最高分
group by stu.s_id;
-- 41、查询不同课程成绩相同的学生的学生编号、课程编号、学生成绩
select distinct stu.s_id, s.c_id, s.s_score
from score s
         join score s2 on s.c_id != s2.c_id
         join student stu on s.s_id = stu.s_id
where s.s_score = s2.s_score;

-- 42、查询每门功成绩最好的前两名
select s.s_id,s.s_score
from score s
where (select count(s.s_score) from score sc where sc.c_id = s.c_id and sc.s_score >= s.s_score) <= 2
order by s.s_score desc;
-- 43、统计每门课程的学生选修人数（超过5人的课程才统计）。要求输出课程号和选修人数，查询结果按人数降序排列，若人数相同，按课程号升序排列
select s.c_id, count(1) ct
from score s
group by s.c_id
having ct > 5
order by ct desc, c_id asc;
-- 44、检索至少选修两门课程的学生学号
select * from student stu
    left join score s on stu.s_id = s.s_id
group by stu.s_id
having count(1) > 2;

-- 45、查询选修了全部课程的学生信息
select * from student stu
    left join score s on stu.s_id = s.s_id
group by stu.s_id
having count(1) = (select count(1) from course);
-- 46、查询各学生的年龄 ************************************************************
select stu.s_id,stu.s_name,
       FLOOR(datediff(NOW(), stu.s_birth) / 365)
from student stu;
-- 47、查询本周过生日的学生
select *
from student
where WEEK(DATE_FORMAT(NOW(), '%Y%m%d')) = WEEK(s_birth);
-- 48、查询下周过生日的学生
select *
from student
where WEEK(DATE_FORMAT(NOW(), '%Y%m%d')) + 1 = WEEK(s_birth);
-- 49、查询本月过生日的学生
select * from student where MONTH(DATE_FORMAT(NOW(),'%Y%m%d')) =MONTH(s_birth);
-- 50、查询下月过生日的学生
select * from student where MONTH(DATE_FORMAT(NOW(),'%Y%m%d'))+1 =MONTH(s_birth)