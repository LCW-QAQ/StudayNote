-- 临时设置group_concat()函数能连接的长度(若表结构过长可增加)
SET SESSION group_concat_max_len = 204800;
-- 【mysql to hive 建表语句生成脚本】
select group_concat(create_ddl separator '')
from (SELECT concat
                 ('create table ', table_name, ' (', group_concat(field_name ORDER BY ORDINAL_POSITION ASC),
                  ')row format delimited fields terminated by "\\t" stored as orc tblproperties ("orc.compress"="ZLIB");')
                 AS create_ddl
      FROM (SELECT b.TABLE_NAME,
                   b.ORDINAL_POSITION,
                   concat_ws(
                           ' ',
                           b.COLUMN_NAME,
                           CASE
                               WHEN data_type IN ('varchar', 'NVARCHAR2', 'char') THEN
                                   'string'
                               when DATA_TYPE = 'NUMBER' and ifnull(NUMERIC_SCALE, 0) > 0 then 'numeric'
                               -- 数字类型
                               when DATA_TYPE in ('tinyint', 'int', 'smallint') then 'int'
                               when DATA_TYPE = 'decimal' and ifnull(NUMERIC_SCALE, 0) = 0 then 'int'
                               WHEN DATA_TYPE = 'decimal' THEN
                                   'decimal(11,2)'
                               WHEN DATA_TYPE = 'boolean' THEN
                                   'tinyint'
                               WHEN DATA_TYPE = 'double' THEN
                                   'double'
                               WHEN DATA_TYPE = 'FLOAT' THEN
                                   'FLOAT'
                               WHEN DATA_TYPE = 'tinyint' THEN
                                   'tinyint'
                               WHEN DATA_TYPE = 'int' THEN
                                   'int'
                               WHEN DATA_TYPE = 'bit' THEN
                                   'tinyint'
                               WHEN DATA_TYPE = 'smallint' THEN
                                   'smallint'
                               -- 日期相关
                               WHEN DATA_TYPE = 'date' THEN
                                   'date'
                               WHEN DATA_TYPE = 'time' THEN
                                   'string'
                               WHEN DATA_TYPE IN ('datetime', 'TIMESTAMP(6)', 'timestamp') THEN
                                   'TIMESTAMP'
                               WHEN DATA_TYPE IN ('text', 'longblob', 'tinytext', 'mediumtext', 'longtext') THEN
                                   'string'
                               ELSE '字段类型映射异常'
                               END,
                           'comment ',
                           concat('''', b.column_comment, '''')
                       ) AS field_name
            FROM information_schema.COLUMNS b
            WHERE b.TABLE_SCHEMA = 'teach' -- 选择要批量生成表的库
-- AND b.TABLE_NAME IN ( 't_brand' ) -- 指定要生成的表
           ) tt
      GROUP BY table_name) _temp;

-- 生成表注释信息
select group_concat(alter_sql separator '')
from (select concat('alter table ', TABLE_NAME, ' set TBLPROPERTIES("comment"="', TABLE_COMMENT, '");') as alter_sql
      from information_schema.tables b
      where b.TABLE_SCHEMA = 'nev'
-- and b.TABLE_NAME in ('t_goods_collect'); -- 指定要生成注释的表
     ) _temp;