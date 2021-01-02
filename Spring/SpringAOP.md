# SpringAOP

## 核心概念

| Aspect 切面            | 切面是由多个切点组成, 列如我们的日志类, 权限管理类, 多个切入点方法组成了切面类 |
| ---------------------- | ------------------------------------------------------------ |
| Join Point 连接点      | 连接点是指可以切入方法的地方, 列如在方法前执行的权限管理, 方法异常进行的异常处理 |
| Advice 通知            | 通知是值在每个切入点上具体的执行动作, SpringAOP有多种通知, `Around` `before` `after`.... |
| Pointcut 切入点        | 切入点是指实际执行方法的地方, 可以通过SpringAOP的切点表达式来切入方法 |
| Introduction 引入      | SpringAOP可以额外引入新的接口到被通知的类上                  |
| Target Object 目标对象 | 被代理的对象                                                 |
| AOP Proxy 代理对象     | 代理对象, 实际执行方法的对象                                 |
| Weaving 织入           | 织入是SpringAOP切入方法的整个过程, 在类加载时或运行时完成    |

## 断点表达式

- **`*`**可以匹配一个或多个字符
  - **`*.*`**匹配双层路径
- 如果相匹配所有权限修饰符, 直接不写即可
- **`..`**可以匹配任意字符,任意层路径
  - **`*(..)`**可以匹配任意参数类型, 任意参数个数
- 表达式也支持`!` `||` `&&`

## 通知

### 注解方式

- 通知类型:
  - **Before**
    - 前置通知, 在方法执行前运行
  - **AfterReturning**
    - 后置返回通知, 在方法返回结果后执行
  - **AfterThrowing**
    - 后置异常通知, 在方法抛出异常后执行
  - **After**
    - 后置通知, 在方法结束后运行
  - **Around**
    - 环绕通知, 最强的通知, 相当于自定义通知, 包括前面所有的通知, 并且运行顺序优先于其他通知
- 可以使用Pointcut注解定义一个切入点, 以便复用

```java
import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.Signature;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Aspect
@Component
public class LogUtil {

    @Pointcut("execution(* com.lcw.service..*(..))")
    public void myPointCut(){}

    @Before("myPointCut()")
    public static void start(JoinPoint joinPoint){
        Signature signature = joinPoint.getSignature();
        Object[] args = joinPoint.getArgs();
        System.out.println(signature.getName()+"()方法开始执行, 参数为:"+ Arrays.asList(args));
    }

    @AfterReturning(value = "execution(public double com.lcw.service.CalculatorImpl.*(double, double))", returning = "result")
    public static void stop(JoinPoint joinPoint, Object result){
        Signature signature = joinPoint.getSignature();
        System.out.println(signature.getName()+"方法返回, 结果为:"+result);
    }

    @AfterThrowing(value = "execution(public double com.lcw.service.CalculatorImpl.*(double, double))", throwing = "e")
    public static void exception(JoinPoint joinPoint, Exception e){
        Signature signature = joinPoint.getSignature();
        System.out.println(signature.getName()+"方法异常"+e.getMessage());
    }

    @After("execution(public double com.lcw.service.CalculatorImpl.*(double, double))")
    public static void last(JoinPoint joinPoint){
        Signature signature = joinPoint.getSignature();
        System.out.println(signature.getName()+"方法执行完成");
    }
    
    @Around("myPointCut()")
    public Object around(ProceedingJoinPoint pjp){
        Signature signature = pjp.getSignature();
        Object[] args = pjp.getArgs();
        Object result = null;
        try {
            System.out.println(signature.getName()+"开始执行(环绕通知), 参数为:"+Arrays.asList(args));
            result = pjp.proceed(args);
//            result = 100;
            System.out.println(signature.getName()+"方法返回(环绕通知), 结果为:"+result);
        } catch (Throwable throwable) {
            System.out.println(signature.getName()+"方法异常"+", "+throwable.getMessage());
        }finally {
            System.out.println(signature.getName()+"执行完毕(环绕通知)");
        }
        return result;
    }
}

```

### xml的方式配置

```xml
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:aop="http://www.springframework.org/schema/aop"
       xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans.xsd http://www.springframework.org/schema/aop https://www.springframework.org/schema/aop/spring-aop.xsd">

    <!--装配两个util类-->
    <bean id="logUtil" class="com.lcw.util.LogUtil"></bean>
    <bean id="securityUtil" class="com.lcw.util.SecurityUtil"></bean>

    <!--装配需要代理的对象-->
    <bean id="calculatorImpl" class="com.lcw.service.CalculatorImpl"></bean>

    <aop:config>
        <!--定义一个切点, 以便后面复用-->
        <aop:pointcut id="calcPointcut" expression="execution(* com.lcw.service..*(..))"/>
        <aop:aspect ref="logUtil">
            <aop:around method="around" pointcut-ref="calcPointcut"></aop:around>
            <aop:before method="start" pointcut-ref="calcPointcut"></aop:before>
            <aop:after-returning method="stop" pointcut-ref="calcPointcut" returning="result"></aop:after-returning>
            <aop:after-throwing method="exception" pointcut-ref="calcPointcut" throwing="e"></aop:after-throwing>
            <aop:after method="last" pointcut-ref="calcPointcut"></aop:after>
        </aop:aspect>
        <aop:aspect ref="securityUtil" order="10">
            <aop:before method="checkSecurity" pointcut-ref="calcPointcut"></aop:before>
        </aop:aspect>
    </aop:config>

</beans>
```

