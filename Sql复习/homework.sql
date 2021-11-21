select * from Student where GradeId = 1;

select StudentName,phone from Student where GradeId = 2;

select * from Student where GradeId = 1 and Sex = '女';

select * from Subject where ClassHour > 60;

select * from Subject where GradeId = 1;

select StudentName,Address from Student where GradeId = 2;

select * from Student where Email is null;

select * from Student where datepart(yy,BornDate) > 1990;

select s.* from Result join Student S on Result.StudentNo = S.StudentNo where ExamDate = CONVERT(smalldatetime,'2013-02-15');

select CONVERT(smalldatetime,'2013-02-15');

select * from Result order by ExamDate asc,StudentResult desc;

select top 5 * from Result where ExamDate = CONVERT(smalldatetime,'2013-03-22');

select top 1 * from Subject order by ClassHour desc;

select top 1 * from Student order by BornDate desc;

select * from Subject where SubjectId in(select top 1 SubjectId from Result order by StudentResult asc);

select * from Result where StudentNo = 1001 order by ExamDate asc;

select top 1 * from Result where StudentNo = 1001 order by StudentResult desc;








