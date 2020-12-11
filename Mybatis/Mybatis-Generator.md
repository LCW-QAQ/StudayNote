# 逆向工程配置文件

```xml
<!DOCTYPE generatorConfiguration PUBLIC
        "-//mybatis.org//DTD MyBatis Generator Configuration 1.0//EN"
        "http://mybatis.org/dtd/mybatis-generator-config_1_0.dtd">
<generatorConfiguration>
    <!--具体配置的上下文环境-->
    <context id="simple" targetRuntime="MyBatis3Simple">
        <!--指向需要连接的数据库-->
        <jdbcConnection driverClass="com.mysql.jdbc.Driver"
                        connectionURL="jdbc:mysql://localhost:3306/test?serverTimezone=UTC"
                        userId="root" password="tiger"/>

        <!--生成对应的实体类-->
        <!--
            targetPackage:指定存放的包
            targetProject:指定当前项目路径
        -->
        <javaModelGenerator targetPackage="com.lcw.bean" targetProject="src/main/java"/>

        <!--生成对应的Sql映射文件-->
        <sqlMapGenerator targetPackage="com.lcw.dao" targetProject="src/main/resources"/>

        <!--生成对应的Dao接口-->
        <javaClientGenerator type="XMLMAPPER" targetPackage="com.lcw.dao" targetProject="src/main/java"/>

        <!--指定需要生成的表-->
        <table tableName="emp" />
        <table tableName="dept" />
    </context>
</generatorConfiguration>
```

# 生成Bean和Dao以及dao/xml

```java
//运行根据mbg.xml生成Bean和Dao以及dao/xml
public static void main(String[] args) throws IOException, XMLParserException, InvalidConfigurationException, SQLException, InterruptedException {
        List<String> warnings = new ArrayList<String>();
        boolean overwrite = true;
        File configFile = new File("mbg.xml");
        ConfigurationParser cp = new ConfigurationParser(warnings);
        Configuration config = cp.parseConfiguration(configFile);
        DefaultShellCallback callback = new DefaultShellCallback(overwrite);
        MyBatisGenerator myBatisGenerator = new MyBatisGenerator(config, callback, warnings);
        myBatisGenerator.generate(null);
    }
```

