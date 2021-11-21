delimiter //
create procedure cc()
begin
    declare done int default 0;
    declare o int;
    declare sumIdList CURSOR FOR
    select StuId from student;
    open sumIdList;
    REPEAT
        FETCH sumIdList INTO o;
        IF NOT done THEN
            select o;
        END IF;
    UNTIL done END REPEAT;
    close sumIdList;
end //
delimiter ;

drop procedure cc;

call cc();














