# Mybatis

## mybatis-config 基础配置

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE configuration
        PUBLIC "-//mybatis.org//DTD Config 3.0//EN"
        "http://mybatis.org/dtd/mybatis-3-config.dtd">
<configuration>
    <properties resource="db.properties"/>

    <settings>
        <setting name="mapUnderscoreToCamelCase" value="true"/>
    </settings>

    <typeAliases>
        <package name="com.lcw.bean"/>
    </typeAliases>

    <environments default="development">
        <environment id="development">
            <transactionManager type="JDBC"/>
            <!--配置数据库连接-->
            <dataSource type="POOLED">
                <property name="driver" value="${jdbc.driverClassName}"/>
                <property name="url" value="${jdbc.url}"/>
                <property name="username" value="${jdbc.userName}"/>
                <property name="password" value="${jdbc.password}"/>
            </dataSource>
        </environment>
    </environments>

    <!--
 在不同的数据库中，可能sql语句的写法是不一样的，为了增强移植性，可以提供不同数据库的操作实现
 在编写不同的sql语句的时候，可以指定databaseId属性来标识当前sql语句可以运行在哪个数据库中
 -->
    <databaseIdProvider type="DB_VENDOR">
        <property name="MySQL" value="mysql"/>
        <property name="SQL Server" value="sqlserver"/>
        <property name="Oracle" value="orcl"/>
    </databaseIdProvider>

    <mappers>
<!--        <mapper resource="com/lcw/dao/EmpDao.xml"/>-->
        <package name="com.lcw.dao"/>
    </mappers>
</configuration>
```

## 完成自增主键插入操作， 可以获取自增的主键

```xml
<!--
	useGenerateKeys 设置是否保存自增的主键
	keyProperty     制定需要保存的自增主键
-->
<insert id="saveUser" useGeneratedKeys="true" keyProperty="id">
    insert into user(user_name)
    values (#{userName})
</insert>
```

## 返回结果为Map需要使用MapKey注解， 来表示那个属性为Key

```java
@MapKey("eid")
Map<String, Object> selectAllReturnMap();
```

## 延时加载

###  lazyLoadingEnabled

```xml
<!--
对于嵌套Sql, 只会在需要用到关联结果时, 才回去连表, 否则不会连表
-->
<settings>
    <setting name="lazyLoadingEnabled" value="true"/>
</settings>
```

### fetchType

- eager 无论是否需要关联结果都进行连表
- lazy 需要使用关联结果时, 进行连表

```xml
<collection property="emps"
            column="deptno"
            ofType="com.lcw.bean.Emp"
            select="com.lcw.dao.EmpDao.selectEmpByStep2"
            fetchType="lazy"/>
```