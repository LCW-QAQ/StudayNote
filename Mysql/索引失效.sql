CREATE TABLE `user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_bin DEFAULT NULL,
  `age` int DEFAULT '0',
  `name` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  `height` int DEFAULT '0',
  `address` varchar(30) COLLATE utf8mb4_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_code_age_name` (`code`,`age`,`name`),
  KEY `idx_height` (`height`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

INSERT INTO `user` (id, CODE, age, NAME, height,address) VALUES (1, '101', 21, '周星驰', 175,'香港');
INSERT INTO `user` (id, CODE, age, NAME, height,address) VALUES (2, '102', 18, '周杰伦', 173,'台湾');
INSERT INTO `user` (id, CODE, age, NAME, height,address) VALUES (3, '103', 23, '苏三', 174,'成都');

explain select * from user where code='101';

explain select * from user where code='101' and age=21;

explain select * from user where code='101' and age=21 and name='周星驰';

explain select * from user where age=21 and name='周星驰';

explain select age, address from user where name='苏三';

explain select * from user where code like "%hello";

explain select * from user  where id=1 or height='175' or address = "北京";


explain select * from user where height in (173,174,175,176);

explain select * from user t1 
	where exists (select 1 from user t2 where t2.height=173 and t1.id=t2.id)
	
explain select * from user where height not in (173,174,175,176);
EXPLAIN select * from user where height not in (1, 2, 3, 4, 5);

explain select * from user where card_id not in (173,174,175,176);
explain select * from user where id  not in (173,174,175,176);

explain select * from user  t1
		where  not exists (select 1 from user t2 where t2.height=173 and t1.id=t2.id)
		
explain select * from user where code='101' order by name;

explain select * from user order by code, name;


explain select * from user order by code limit 100;

explain select * from user order by code,age limit 100;

explain select * from user order by code,age,name limit 100;



