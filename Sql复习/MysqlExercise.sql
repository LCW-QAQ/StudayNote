-- 1����ѯ"01"�γ̱�"02"�γ̳ɼ��ߵ�ѧ������Ϣ���γ̷���
-- 01 02 if 01.score > 02.score show msg and score
select * from student std
    left join score s on std.s_id = s.s_id and s.c_id = '01'
    left join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
    where s.s_score > s2.s_score;
-- 2����ѯ"01"�γ̱�"02"�γ̳ɼ��͵�ѧ������Ϣ���γ̷���
-- 01 02 if 01.score > 02.score show msg and score
select std.*, s.s_score '01', s2.s_score '02' from student std
    left join score s on std.s_id = s.s_id and s.c_id = '01'
    left join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
    where s.s_score < s2.s_score;
-- 3����ѯƽ���ɼ����ڵ���60�ֵ�ͬѧ��ѧ����ź�ѧ��������ƽ���ɼ�
-- avg if avg >= 60 show msg and avg
select std.s_id, std.s_name, avg(s.s_score)
from student std
         left join score s on std.s_id = s.s_id
group by std.s_id
having avg(s.s_score) >= 60;
-- 4����ѯƽ���ɼ�С��60�ֵ�ͬѧ��ѧ����ź�ѧ��������ƽ���ɼ�
-- (�����гɼ��ĺ��޳ɼ���)
-- avg if avg < 60 show msg and avg
select std.s_id,std.s_name,round(avg(ifnull(s.s_score, 0)), 2) v_score
from student std
         left join score s on std.s_id = s.s_id
group by std.s_id
having v_score < 60;

-- union ����, union all ȫ��

select b.s_id,b.s_name,ROUND(AVG(a.s_score),2) as avg_score from
    student b
    left join score a on b.s_id = a.s_id
    GROUP BY b.s_id,b.s_name HAVING ROUND(AVG(a.s_score),2)<60
    union
select a.s_id,a.s_name,0 as avg_score from
    student a
    where a.s_id not in (
                select distinct s_id from score);
-- 5����ѯ����ͬѧ��ѧ����š�ѧ��������ѡ�����������пγ̵��ܳɼ�
-- all show id,name,count(c_id),sum(s_score)
select std.s_id,std.s_name,count(s.c_id),sum(ifnull(s.s_score, 0)) from student std
    left join score s on std.
        s_id = s.s_id group by std.s_id;
-- 6����ѯ"��"����ʦ������
select count(1) from teacher where t_name like('��%');
-- 7����ѯѧ��"����"��ʦ�ڿε�ͬѧ����Ϣ
-- std if list(c_id) not contain '����'
select std.* from student std
    join score s on std.s_id = s.s_id
    join course c on s.c_id = c.c_id
    join teacher t on c.t_id = t.t_id and t.t_name = '����' group by std.s_id;

select std.*
from student std
         join score s on std.s_id = s.s_id
        where s.c_id in(select c.c_id from course c where c.t_id = (select t_id from teacher where t_name = '����'));
-- 8����ѯûѧ��"����"��ʦ�ڿε�ͬѧ����Ϣ
-- std if '����' not in list(course)
select *
from student std
where std.s_id not in (
    select std.s_id
    from student std
             join score s on std.s_id = s.s_id
    where s.c_id in (
        select c.c_id from course c where c.t_id = (select t.t_id from teacher t where t.t_name = '����'))
);

select *
from student std
where std.s_id not in (
    select std.s_id
    from student std
             join score s on std.s_id = s.s_id
             join course c on s.c_id = c.c_id
             join teacher t on c.t_id = t.t_id and t.t_name = '����'
    group by std.s_id
);
-- 9����ѯѧ�����Ϊ"01"����Ҳѧ�����Ϊ"02"�Ŀγ̵�ͬѧ����Ϣ
-- std if 01 02 in list(course) show msg
select std.*,s.c_id,s2.c_id from student std
    join score s on std.s_id = s.s_id and s.c_id = '01'
    join score s2 on std.s_id = s2.s_id and s2.c_id = '02'
group by std.s_id;

-- 10����ѯѧ�����Ϊ"01"����û��ѧ�����Ϊ"02"�Ŀγ̵�ͬѧ����Ϣ
-- std if 01 in course and o2 not in course show msg
select *
from student std
where std.s_id in (select s.s_id from score s where s.c_id = '01')
  and std.s_id not in (select s.s_id from score s where s.c_id = '02');

-- 11����ѯû��ѧȫ���пγ̵�ͬѧ����Ϣ, ������û��ѧ�κοε�ͬѧ
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
-- 12����ѯ������һ�ſ���ѧ��Ϊ"01"��ͬѧ��ѧ��ͬ��ͬѧ����Ϣ
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

-- 13����ѯ��"01"�ŵ�ͬѧѧϰ�Ŀγ���ȫ��ͬ������ͬѧ����Ϣ
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
-- 14����ѯûѧ��"����"��ʦ���ڵ���һ�ſγ̵�ѧ������
-- ��ѯ������ʦ�����Ŀ�
-- ��ѯ����ѧ�����Ͽμ�¼

-- ��ѯ##ѧ��##"����"��ʦ���ڵ���һ�ſγ̵�ѧ������
-- ��ѯû��ѧ��"����"��ʦ���ڵ���һ�ſγ̵�ѧ������

-- 15����ѯ���ż������ϲ�����γ̵�ͬѧ��ѧ�ţ���������ƽ���ɼ�
-- ��ѯ>=���Ų������ѧ��
-- ͬѧ��ѧ�ţ���������ƽ���ɼ�

-- 16������"01"�γ̷���С��60���������������е�ѧ����Ϣ

-- 17����ƽ���ɼ��Ӹߵ�����ʾ����ѧ�������пγ̵ĳɼ��Լ�ƽ���ɼ�
-- ��ѯ����ѧ������ѧ�Ŀγ̵ĳɼ�

/* 18.��ѯ���Ƴɼ���߷֡���ͷֺ�ƽ���֣���������ʽ��ʾ���γ�ID���γ�name����߷֣���ͷ֣�ƽ���֣������ʣ��е��ʣ������ʣ�������
����Ϊ>=60���е�Ϊ��70-80������Ϊ��80-90������Ϊ��>=90 */
-- 19�������Ƴɼ��������򣬲���ʾ����(ʵ�ֲ���ȫ)
-- mysqlû��rank����
-- 20����ѯѧ�����ܳɼ�����������







