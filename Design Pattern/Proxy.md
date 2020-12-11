# Proxy

> 代理模式可以代理一个类, 在类的方法, 调用时进行一些操作, SpringAOP就是使用了动态代理的方式实现

## 静态代理

> 静态有局限性, 只能事先写好代理类, 而不能在运行时动态创建, 兼容性差

```java
public interface Movable {
    void move();
}
```

```java
public class Tank implements Movable{
    @Override
    public void move() {
        System.out.println("Tank move...");
        try {
            Thread.sleep((long) (Math.random()*10000+1));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class TankProxy implements Movable{

    private Movable movable;

    public TankProxy() {
    }

    public TankProxy(Movable movable) {
        this.movable = movable;
    }

    @Override
    public void move() {
        long time = System.currentTimeMillis();
        movable.move();;
        time = System.currentTimeMillis()-time;
        System.out.println("Tank运行了"+time+"毫秒");
    }
}
```

```java
public class TankProxyTwo implements Movable{

    private Movable movable;

    public TankProxyTwo() {
    }

    public TankProxyTwo(Movable movable) {
        this.movable = movable;
    }

    @Override
    public void move() {
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd hh:mm:ss");
        System.out.println(LocalDateTime.now().format(dtf)+"程序开始运行");
        movable.move();
        System.out.println(LocalDateTime.now().format(dtf)+"程序结束运行");
    }

}
```

```java
public class Main {
    public static void main(String[] args) {
        new TankProxyTwo(new TankProxy(new Tank())).move();
    }
}
```

## 动态代理

> 无论是JDK还是cglib的动态代理, 底层都使用了ASM字节码操作框架, 动态生成class文件

### JDK动态代理

> JDK动态代理需要一个顶级接口才能代理
>
> 在源码中JDK动态创建的代理类是继承自Proxy, 只需要实现接口, 就可以代理接口中的方法

```java
public interface Movable {
    void move();
}
```

```java
public class Tank implements Movable{
    @Override
    public void move() {
        System.out.println("Tank move...");
        try {
            Thread.sleep((long) (Math.random()*10000+1));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class TankTwo {
    public void move(){
        System.out.println("Tank move...");
    }
}
```

```java
public class Main {
    public static void main(String[] args) {
        Tank tank = new Tank();
        Movable movable = (Movable)Proxy.newProxyInstance(tank.getClass().getClassLoader(),
                tank.getClass().getInterfaces(), 
                (proxy, method, parameters) -> {
                    DateTimeFormatter dtf = DateTimeFormatter.ofPattern("yyyy/MM/dd hh:mm:ss");
                    //输入方法何时开始运行
                    System.out.println(method.getName() + "--" + LocalDateTime.now().format(dtf) + "方法开始运行");
                    //用来记录方法运行了多久
                    long time = System.currentTimeMillis();
                    Object result = method.invoke(tank, parameters);
                    double spendTime = time - System.currentTimeMillis();
                    //精确计算方法运行时间
                    BigDecimal bigDecimal = new BigDecimal(Double.toString(spendTime));
                    System.out.println("运行耗时"+bigDecimal.divide(new BigDecimal(1000), MathContext.DECIMAL32));
                    System.out.println(method.getName() + LocalDateTime.now().format(dtf) + "方法结束运行");
                    return result;
                });
        movable.move();
    }
}
```

#### JDK动态代理对象分析

> 可以通过设置System.getProperties().put("sun.msic.ProxyGenerator.saveGeneratedFiles",'"true");
>
> 来保存运行时创建的动态代理对象

```java
package com.sun.proxy;

import com.lcw.proxy.dynamicj_proxy.Movable;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;

public final class $Proxy0 extends Proxy implements Movable {
    private static Method m1;
    private static Method m3;
    private static Method m2;
    private static Method m0;

    public $Proxy0(InvocationHandler var1) throws  {
        super(var1);
    }

    public final boolean equals(Object var1) throws  {
        try {
            return (Boolean)super.h.invoke(this, m1, new Object[]{var1});
        } catch (RuntimeException | Error var3) {
            throw var3;
        } catch (Throwable var4) {
            throw new UndeclaredThrowableException(var4);
        }
    }

    public final void move() throws  {
        try {
            super.h.invoke(this, m3, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final String toString() throws  {
        try {
            return (String)super.h.invoke(this, m2, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final int hashCode() throws  {
        try {
            return (Integer)super.h.invoke(this, m0, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    static {
        try {
            m1 = Class.forName("java.lang.Object").getMethod("equals", Class.forName("java.lang.Object"));
            m3 = Class.forName("com.lcw.proxy.dynamicj_proxy.Movable").getMethod("move");
            m2 = Class.forName("java.lang.Object").getMethod("toString");
            m0 = Class.forName("java.lang.Object").getMethod("hashCode");
        } catch (NoSuchMethodException var2) {
            throw new NoSuchMethodError(var2.getMessage());
        } catch (ClassNotFoundException var3) {
            throw new NoClassDefFoundError(var3.getMessage());
        }
    }
}
```

> **从上面反编译的文件会发现, JDK就是通过定义一个Proxy子类, 实现接口, 代理接口中的所有方法, 因此JDK动态代理必须有接口**

### cglib动态代理

> cglib动态代理是通过继承被代理类实现的

```java
public class Tank {
    public void move(){
        System.out.println("Tank move...");
    }
}
```

```java
public class Main {
    public static void main(String[] args) {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(Tank.class);
        enhancer.setCallback(new MethodInterceptor() {
            public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
                System.out.println(obj.getClass().getSuperclass().getName());
                System.out.println("before");
                Object result = proxy.invokeSuper(obj, args);
                System.out.println("after");
                return result;
            }
        });
        Tank tank = (Tank)enhancer.create();
        tank.move();
    }
}
```



#### cglib动态代理对象分析

> 设置System.setProperty(DebuggingClassWriter.DEBUG_LOCATION_PROPERTY, "C:\\Users\\user\\Desktop"); 保存cglib对象

> 可以通过HSDB创建cglib的动态代理对象
>
> jsp -l 查看详细java程序uid
>
> java -cp "%JAVA_HOME%\lib\sa-jdi.jar" sun.jvm.hotspot.HSDB

```java
package com.lcw.proxy.cglib;

import java.lang.reflect.Method;
import net.sf.cglib.core.ReflectUtils;
import net.sf.cglib.core.Signature;
import net.sf.cglib.proxy.Callback;
import net.sf.cglib.proxy.Factory;
import net.sf.cglib.proxy.MethodInterceptor;
import net.sf.cglib.proxy.MethodProxy;

public class Tank$$EnhancerByCGLIB$$d7bbb02a extends Tank implements Factory {
    private boolean CGLIB$BOUND;
    public static Object CGLIB$FACTORY_DATA;
    private static final ThreadLocal CGLIB$THREAD_CALLBACKS;
    private static final Callback[] CGLIB$STATIC_CALLBACKS;
    private MethodInterceptor CGLIB$CALLBACK_0;
    private static Object CGLIB$CALLBACK_FILTER;
    private static final Method CGLIB$move$0$Method;
    private static final MethodProxy CGLIB$move$0$Proxy;
    private static final Object[] CGLIB$emptyArgs;
    private static final Method CGLIB$equals$1$Method;
    private static final MethodProxy CGLIB$equals$1$Proxy;
    private static final Method CGLIB$toString$2$Method;
    private static final MethodProxy CGLIB$toString$2$Proxy;
    private static final Method CGLIB$hashCode$3$Method;
    private static final MethodProxy CGLIB$hashCode$3$Proxy;
    private static final Method CGLIB$clone$4$Method;
    private static final MethodProxy CGLIB$clone$4$Proxy;

    public Tank$$EnhancerByCGLIB$$d7bbb02a() {
        CGLIB$BIND_CALLBACKS(this);
    }

    static {
        CGLIB$STATICHOOK1();
    }

    public final boolean equals(Object var1) {
        MethodInterceptor var10000 = this.CGLIB$CALLBACK_0;
        if (var10000 == null) {
            CGLIB$BIND_CALLBACKS(this);
            var10000 = this.CGLIB$CALLBACK_0;
        }

        if (var10000 != null) {
            Object var2 = var10000.intercept(this, CGLIB$equals$1$Method, new Object[]{var1}, CGLIB$equals$1$Proxy);
            return var2 == null ? false : (Boolean)var2;
        } else {
            return super.equals(var1);
        }
    }

    public final String toString() {
        MethodInterceptor var10000 = this.CGLIB$CALLBACK_0;
        if (var10000 == null) {
            CGLIB$BIND_CALLBACKS(this);
            var10000 = this.CGLIB$CALLBACK_0;
        }

        return var10000 != null ? (String)var10000.intercept(this, CGLIB$toString$2$Method, CGLIB$emptyArgs, CGLIB$toString$2$Proxy) : super.toString();
    }

    public final int hashCode() {
        MethodInterceptor var10000 = this.CGLIB$CALLBACK_0;
        if (var10000 == null) {
            CGLIB$BIND_CALLBACKS(this);
            var10000 = this.CGLIB$CALLBACK_0;
        }

        if (var10000 != null) {
            Object var1 = var10000.intercept(this, CGLIB$hashCode$3$Method, CGLIB$emptyArgs, CGLIB$hashCode$3$Proxy);
            return var1 == null ? 0 : ((Number)var1).intValue();
        } else {
            return super.hashCode();
        }
    }

    protected final Object clone() throws CloneNotSupportedException {
        MethodInterceptor var10000 = this.CGLIB$CALLBACK_0;
        if (var10000 == null) {
            CGLIB$BIND_CALLBACKS(this);
            var10000 = this.CGLIB$CALLBACK_0;
        }

        return var10000 != null ? var10000.intercept(this, CGLIB$clone$4$Method, CGLIB$emptyArgs, CGLIB$clone$4$Proxy) : super.clone();
    }

    public Object newInstance(Class[] var1, Object[] var2, Callback[] var3) {
        CGLIB$SET_THREAD_CALLBACKS(var3);
        Tank$$EnhancerByCGLIB$$d7bbb02a var10000 = new Tank$$EnhancerByCGLIB$$d7bbb02a;
        switch(var1.length) {
        case 0:
            var10000.<init>();
            CGLIB$SET_THREAD_CALLBACKS((Callback[])null);
            return var10000;
        default:
            throw new IllegalArgumentException("Constructor not found");
        }
    }

    public Object newInstance(Callback var1) {
        CGLIB$SET_THREAD_CALLBACKS(new Callback[]{var1});
        Tank$$EnhancerByCGLIB$$d7bbb02a var10000 = new Tank$$EnhancerByCGLIB$$d7bbb02a();
        CGLIB$SET_THREAD_CALLBACKS((Callback[])null);
        return var10000;
    }

    public Object newInstance(Callback[] var1) {
        CGLIB$SET_THREAD_CALLBACKS(var1);
        Tank$$EnhancerByCGLIB$$d7bbb02a var10000 = new Tank$$EnhancerByCGLIB$$d7bbb02a();
        CGLIB$SET_THREAD_CALLBACKS((Callback[])null);
        return var10000;
    }

    public void setCallback(int var1, Callback var2) {
        switch(var1) {
        case 0:
            this.CGLIB$CALLBACK_0 = (MethodInterceptor)var2;
        default:
        }
    }

    public final void move() {
        MethodInterceptor var10000 = this.CGLIB$CALLBACK_0;
        if (var10000 == null) {
            CGLIB$BIND_CALLBACKS(this);
            var10000 = this.CGLIB$CALLBACK_0;
        }

        if (var10000 != null) {
            var10000.intercept(this, CGLIB$move$0$Method, CGLIB$emptyArgs, CGLIB$move$0$Proxy);
        } else {
            super.move();
        }
    }

    public void setCallbacks(Callback[] var1) {
        this.CGLIB$CALLBACK_0 = (MethodInterceptor)var1[0];
    }

    public Callback[] getCallbacks() {
        CGLIB$BIND_CALLBACKS(this);
        return new Callback[]{this.CGLIB$CALLBACK_0};
    }

    public Callback getCallback(int var1) {
        CGLIB$BIND_CALLBACKS(this);
        MethodInterceptor var10000;
        switch(var1) {
        case 0:
            var10000 = this.CGLIB$CALLBACK_0;
            break;
        default:
            var10000 = null;
        }

        return var10000;
    }

    public static void CGLIB$SET_STATIC_CALLBACKS(Callback[] var0) {
        CGLIB$STATIC_CALLBACKS = var0;
    }

    public static void CGLIB$SET_THREAD_CALLBACKS(Callback[] var0) {
        CGLIB$THREAD_CALLBACKS.set(var0);
    }

    private static final void CGLIB$BIND_CALLBACKS(Object var0) {
        Tank$$EnhancerByCGLIB$$d7bbb02a var1 = (Tank$$EnhancerByCGLIB$$d7bbb02a)var0;
        if (!var1.CGLIB$BOUND) {
            var1.CGLIB$BOUND = true;
            Object var10000 = CGLIB$THREAD_CALLBACKS.get();
            if (var10000 == null) {
                var10000 = CGLIB$STATIC_CALLBACKS;
                if (var10000 == null) {
                    return;
                }
            }

            var1.CGLIB$CALLBACK_0 = (MethodInterceptor)((Callback[])var10000)[0];
        }

    }

    static void CGLIB$STATICHOOK1() {
        CGLIB$THREAD_CALLBACKS = new ThreadLocal();
        CGLIB$emptyArgs = new Object[0];
        Class var0 = Class.forName("com.lcw.proxy.cglib.Tank$$EnhancerByCGLIB$$d7bbb02a");
        Class var1;
        Method[] var10000 = ReflectUtils.findMethods(new String[]{"equals", "(Ljava/lang/Object;)Z", "toString", "()Ljava/lang/String;", "hashCode", "()I", "clone", "()Ljava/lang/Object;"}, (var1 = Class.forName("java.lang.Object")).getDeclaredMethods());
        CGLIB$equals$1$Method = var10000[0];
        CGLIB$equals$1$Proxy = MethodProxy.create(var1, var0, "(Ljava/lang/Object;)Z", "equals", "CGLIB$equals$1");
        CGLIB$toString$2$Method = var10000[1];
        CGLIB$toString$2$Proxy = MethodProxy.create(var1, var0, "()Ljava/lang/String;", "toString", "CGLIB$toString$2");
        CGLIB$hashCode$3$Method = var10000[2];
        CGLIB$hashCode$3$Proxy = MethodProxy.create(var1, var0, "()I", "hashCode", "CGLIB$hashCode$3");
        CGLIB$clone$4$Method = var10000[3];
        CGLIB$clone$4$Proxy = MethodProxy.create(var1, var0, "()Ljava/lang/Object;", "clone", "CGLIB$clone$4");
        CGLIB$move$0$Method = ReflectUtils.findMethods(new String[]{"move", "()V"}, (var1 = Class.forName("com.lcw.proxy.cglib.Tank")).getDeclaredMethods())[0];
        CGLIB$move$0$Proxy = MethodProxy.create(var1, var0, "()V", "move", "CGLIB$move$0");
    }

    public static MethodProxy CGLIB$findMethodProxy(Signature var0) {
        String var10000 = var0.toString();
        switch(var10000.hashCode()) {
        case -508378822:
            if (var10000.equals("clone()Ljava/lang/Object;")) {
                return CGLIB$clone$4$Proxy;
            }
            break;
        case 1243513348:
            if (var10000.equals("move()V")) {
                return CGLIB$move$0$Proxy;
            }
            break;
        case 1826985398:
            if (var10000.equals("equals(Ljava/lang/Object;)Z")) {
                return CGLIB$equals$1$Proxy;
            }
            break;
        case 1913648695:
            if (var10000.equals("toString()Ljava/lang/String;")) {
                return CGLIB$toString$2$Proxy;
            }
            break;
        case 1984935277:
            if (var10000.equals("hashCode()I")) {
                return CGLIB$hashCode$3$Proxy;
            }
        }

        return null;
    }

    final String CGLIB$toString$2() {
        return super.toString();
    }

    final int CGLIB$hashCode$3() {
        return super.hashCode();
    }

    final boolean CGLIB$equals$1(Object var1) {
        return super.equals(var1);
    }

    final Object CGLIB$clone$4() throws CloneNotSupportedException {
        return super.clone();
    }

    final void CGLIB$move$0() {
        super.move();
    }
}

```

