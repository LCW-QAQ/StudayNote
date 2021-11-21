create sequence seq_id
increment by 1
start with 1;

alter sequence seq_id increment by 1;

select seq_id.currval from dual;
select seq_id.nextval from dual;
insert into psn values(seq_id.nextval,'hehe');
select * from psn;















