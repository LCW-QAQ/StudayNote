# Mysql小技巧

## 处理排名

1.rank() over：排名相同的两名是并列，但是占两个名次，1 1 3 4 4 6这种

2.dense_rank() over：排名相同的两名是并列，共占一个名词，1 1 2 3 3 4这种

3.row_number() over这个函数不需要考虑是否并列，哪怕根据条件查询出来的数值相同也会进行连续排名 1 2 3 4 5

例如[参考leetcode排名](https://leetcode-cn.com/problems/rank-scores/solution/dense_rank-overpai-ming-de-shi-yong-by-q-mq4s/)

```sql
# 根据成绩从搞到低排名，相同成绩并列且不占用名次
select score, (dense_rank() over (order by score desc)) as 'rank' from Scores;

# 下面这个适合在mysql8.0以下版本使用, mysql8.0以下没有rank函数
# 思路: 查询比你成绩高的人有多少，那就是你的排名。列如你的分数为90，比你高的人有2个，那么你排名第三。很简单对吧，注意等于区间就行。
select s.score, (
    select count(distinct ss.score) from Scores ss where ss.score >= s.score
) as 'rank' from Scores s order by score desc
```