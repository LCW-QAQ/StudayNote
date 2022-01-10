# Mycat

> Java语言编写的MySQL数据库网络协议的开源中间件
>
> 支持分库分表, 跨库join等操作
>
> [Mycat官网](http://www.mycat.org.cn/)

## mycat 1.6

现在是2022/1/6 mycat 2.0已经发布了, 但是仍然不够成熟

### 配置

主要的配置文件有三个

* server.xml
* schema.xml
* rule.xml

简单配置

在server.xml中配置虚拟schema映射

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- - - Licensed under the Apache License, Version 2.0 (the "License"); 
	- you may not use this file except in compliance with the License. - You 
	may obtain a copy of the License at - - http://www.apache.org/licenses/LICENSE-2.0 
	- - Unless required by applicable law or agreed to in writing, software - 
	distributed under the License is distributed on an "AS IS" BASIS, - WITHOUT 
	WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. - See the 
	License for the specific language governing permissions and - limitations 
	under the License. -->
<!DOCTYPE mycat:server SYSTEM "server.dtd">
<mycat:server xmlns:mycat="http://io.mycat/">
	<user name="root" defaultAccount="true">
		<property name="password">tiger</property>
        <!-- 这个是虚拟schema对应实际数据库中的一个db -->
		<property name="schemas">TESTDB</property>
		<property name="defaultSchema">TESTDB</property>
		<!--No MyCAT Database selected 错误前会尝试使用该schema作为schema，不设置则为null,报错 -->
		
		<!-- 表级 DML 权限设置 -->
		<!-- 		
		<privileges check="false">
			<schema name="TESTDB" dml="0110" >
				<table name="tb01" dml="0000"></table>
				<table name="tb02" dml="1111"></table>
			</schema>
		</privileges>		
		 -->
	</user>
</mycat:server>
```

在schema.xml中配置详细的数据库设置

```xml
<?xml version="1.0"?>
<!DOCTYPE mycat:schema SYSTEM "schema.dtd">
<mycat:schema xmlns:mycat="http://io.mycat/">
	<schema name="TESTDB" checkSQLschema="false" sqlMaxLimit="100" dataNode="dn1">
	</schema>
	<dataNode name="dn1" dataHost="localhost1" database="mycat_demo" />
	<dataHost name="localhost1" maxCon="1000" minCon="10" balance="0"
			  writeType="0" dbType="mysql" dbDriver="native" switchType="1"  slaveThreshold="100">
		<heartbeat>select user()</heartbeat>
		<!-- can have multi write hosts -->
		<writeHost host="hostM1" url="192.168.150.102:3306" user="root"
				   password="tiger">
		</writeHost>
		<!-- <writeHost host="hostM2" url="localhost:3316" user="root" password="123456"/> -->
	</dataHost>
</mycat:schema>
```

配置完成后运行mycat/bin/mycat console即可在前台(控制台)云心mycat

使用`mysql -uroot -ptiger -P 9066 -h 192.168.150.102`连接mycat管理端口

使用`mysql -uroot -ptiger -P 8066 -h 192.168.150.102`连接mycat数据库端口