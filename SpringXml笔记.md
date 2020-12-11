# Spring Xml Note

## 常见设置例子

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xmlns:context="http://www.springframework.org/schema/context" xmlns:tx="http://www.springframework.org/schema/tx"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/context http://www.springframework.org/schema/context/spring-context.xsd http://www.springframework.org/schema/tx http://www.springframework.org/schema/tx/spring-tx.xsd">

    <!-- 配置使用额外的properties -->
    <context:property-placeholder file-encoding="UTF-8" location="classpath:/properties/druid.properties"/>

    <!-- 配置Druid数据库连接池 -->
    <bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource" init-method="init" destroy-method="close">
        <property name="driverClassName" value="com.mysql.cj.jdbc.Driver" />
        <property name="url" value="jdbc:mysql://39.108.164.150:3306/rbac_mine?characterEncoding=UTF-8&amp;useUnicode=true" />
        <property name="username" value="root" />
        <property name="password" value="jcx120708" />
        <property name="filters" value="stat,wall" />
        <property name="initialSize" value="5" />
        <property name="maxActive" value="10" />
        <property name="maxWait" value="60000" />
        <property name="minIdle" value="3" />
    </bean>

    <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      -            druid监控配置                 　　　　         　-
      - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
    <bean id="statFilter" class="com.alibaba.druid.filter.stat.StatFilter" >
        <property name="logSlowSql" value="true" /> <!-- log记录慢sql -->
        <property name="slowSqlMillis" value="3000" /> <!-- 定义多长时间为慢sql，单位毫秒 -->
        <property name="mergeSql" value="true" /> <!-- 多行sql合并一行 -->
    </bean>
    <bean id="wallFilter" class="com.alibaba.druid.wall.WallFilter">
        <property name="dbType" value="mysql" />
    </bean>

    <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      -            配置Mybatis的SqlSessionFactory　　　　         　-
      - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
    <bean id="sqlSessionFactory" class="org.mybatis.spring.SqlSessionFactoryBean">
        <property name="configLocation" value="classpath:/mybatis/mybatis-config.xml" />
        <property name="dataSource" ref="dataSource" />
        <property name="mapperLocations" value="classpath:/mybatis/mappers/*.xml" />
    </bean>
    <!-- 配置Mybatis的mapper接口地址 -->
    <bean class="org.mybatis.spring.mapper.MapperScannerConfigurer">
        <property name="basePackage" value="pro.onlyou.rbac.mine.mapper" />
        <property name="sqlSessionFactory" ref="sqlSessionFactory" />
    </bean>

    <!-- - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      -            配置事物管理器                  　　　　         　-
      - - - - - - - - - - - - - - - - - - - - - - - - - - - - -->
    <bean id="transactionManager" class="org.springframework.jdbc.datasource.DataSourceTransactionManager">
        <property name="dataSource" ref="dataSource"/>
    </bean>
    <!-- 配置注解驱动事物管理 -->
    <tx:annotation-driven transaction-manager="transactionManager"/>
</beans>
```