# SpringIOC

> **使用前需要导入这些依赖包**
>
> 1. commons-logging-1.2.jar 
> 2. spring-beans-5.2.3.RELEASE.jar
> 3. spring-context-5.2.3.RELEASE.jar
> 4. spring-core-5.2.3.RELEASE.jar
> 5. spring-expression-5.2.3.RELEASE.jar

## 在IOC容器中注册对象

### 使用xml的方式

#### 属性名方式给对象赋值

```xml
<bean id="classId" class="classFullyQualifiedName">
   <property name="classField1" value="value"></property>
   <property name="classField2" value="value"></property>
   <property name="classField3" value="value"></property>
</bean>
```

#### 构造方法给对象赋值

```xml
<bean id="classId" class="classFullyQualifiedName">
    <constructor-arg value="value"></constructor-arg>
    <constructor-arg value="value"></constructor-arg>
    <constructor-arg value="value"></constructor-arg>
</bean>
```

直接使用需要按构造方法顺序, 写arg标签, IOC会自动寻找符合顺序的构造方法, 去构造对象  
如果没有找到对应的构造方法, 则会报错.

```xml
<--可以通过index标签属性来设置arg的顺序-->
<bean id="person4" class="com.mashibing.bean.Person">
    <constructor-arg value="lisi" index="1"></constructor-arg>
    <constructor-arg value="1" index="0"></constructor-arg>
    <constructor-arg value="女" index="3"></constructor-arg>
    <constructor-arg value="20" index="2"></constructor-arg>
</bean>
```

当有多个参数个数相同，不同类型的构造器的时候，可以通过type来强制类型

```java
//将person的age类型设置为Integer类型
public Person(int id, String name, Integer age) {
    this.id = id;
    this.name = name;
    this.age = age;
    System.out.println("Age");
}

public Person(int id, String name, String gender) {
    this.id = id;
    this.name = name;
    this.gender = gender;
    System.out.println("gender");
}
```

```xml
<bean id="person5" class="com.mashibing.bean.Person">
    <constructor-arg value="1"></constructor-arg>
    <constructor-arg value="lisi"></constructor-arg>
    <constructor-arg value="20" type="java.lang.Integer"></constructor-arg>
</bean>
<!--如果不修改为integer类型，那么需要type跟index组合使用-->
<bean id="person5" class="com.mashibing.bean.Person">
    <constructor-arg value="1"></constructor-arg>
    <constructor-arg value="lisi"></constructor-arg>
    <constructor-arg value="20" type="int" index="2"></constructor-arg>
</bean>
```

#### p命名空间

```xml
<bean id="person6" class="com.mashibing.bean.Person" p:id="3" p:name="wangwu" p:age="22" p:gender="男"></bean>
```

### 使用注解的方式

```java
/*在类上方添加注解即可:
	@Component 组件
	@Service 服务
	@Repository dao层
	@Controller 控制层
*/
@Component
public class yourClass{}
```



