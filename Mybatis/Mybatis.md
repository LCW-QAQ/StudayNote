# 细节点

## 插入对象时获取自增的主键

```xml
<insert id="saveUser" useGeneratedKeys="true" keyProperty="id">
    insert into user(user_name) values(#{userName})
</insert>
```

## 结果对象包含其他引用类型时, 自定义ResultMap

普通的查询返回一个结果集合, 不需要使用ResultMap, 直接使用ResultType即可

```xml
<select id="selectAll" resultType="Emp">
    select * from emp
</select>
```

```java
@Test
public void test07(){
    SqlSession sqlSession = sqlSessionFactory.openSession();
    EmpDao mapper = sqlSession.getMapper(EmpDao.class);
    List<Emp> emps = mapper.selectAll();
    emps.forEach(System.out::println);
    sqlSession.close();
}
```

## #与$表达式的区别

- `#`使用了参数预编译, 可以防止sql注入
- `$`直接拼接sql语句, 可能出现sql注入风险

## dao中的方法有多个参数时, 需要使用arg

```java
List<Emp> selectAllByTblName(String tblName, Integer id);
```

下面这个写法会报错

```xml
<select id="selectAllTblName">
    select * from ${tblName} where id = #{id}
</select>
```

如果方法有多个参数就必须要使用arg

```xml
<select id="selectAllTblName">
    select * from ${arg0} where id = #{arg1}
</select>
```

如果不想使用arg, 可以在方法参数上使用@Param注解

```java
List<Emp> selectAllByTblName(@Param("tblName") String tblName, @Param("id") Integer id);
```

```xml
<select id="selectAllTblName">
    select * from ${tblName} where id = #{id}
</select>
```

还可以传入Map来达到目的

JavaCode:

```java
public void test(){
        SqlSession sqlSession = sqlSessionFactory.openSession();
        EmpDao mapper = sqlSession.getMapper(EmpDao.class);
        Emp emp = new Emp();
        emp.setEmpno(7369);
        Map<String, Object> map = new HashMap<>();
        map.put("tblName", "emp");
        map.put("emp", emp);
        mapper.selectEmpByTblNameAndEmpno2(map);
        sqlSession.close();
    }
```

```java
List<Emp> selectAllByTblName(Map<String, Object> map);
```

```xml
<select id="selectAllTblName">
    select * from ${tblName} where id = #{id}
</select>
```

## sql语句返回指定Map<Object, Object>

```java
//只要必须指定Key, value默认为Emp对象
@MapKey("ename")
Map<String, Object> selectAll2();
```

# 缓存

- 一级缓存
  - 表示**SqlSession级别**的缓存, 每次查询都会开启一个会话, 相当于一次连接, 会话结束之后, 一级缓存失效
  - 查询传递的**对象属性值**发生了**变化**, 也**不会走缓存**
  - 如果在一个会话中**修改了数据**, 一级缓存会直接**失效**
- 二级缓存
  - 全局范围内的缓存, sqlSession关闭后才会生效
  - 想要使用二级缓存需要在, 全局配置文件中配置, **`cacheEnabled`** 为 **`true`**, 然后在sql映射文件中添加 `<cache/>`
- 第三方缓存
  - 使用第三方组件如Redis
- 查询缓存时会优先查询二级缓存, 然后再去查询一级缓存

