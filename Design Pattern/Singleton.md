[toc]

# Singleton

> 有些类的对象不需要创建多个, 我们也不能保证别人不去创建新的对象, 因此诞生了单例设计模式  
> Singleton保障了一个类只有一个对象实例.

## 懒汉式

### 私有静态常量Instance

> 在类加载时就创建对象, 要使用时可以直接使用
>
> 这种方式是JVM保障单例, 因为一个类JVM只会被加载一次.
>
> 这种方式不仅实现了单例, 同时也比较简单, 但是可能会浪费资源  
> 我们不一定会用到这个类对象, 但是它在类加载是就创建了.

>这种方式会被反射, 反序列化, 克隆破坏

```java
public class Singleton {
    private static final Singleton INSTANCE = new Singleton();

    private Singleton(){}

    public static Singleton getInstance(){
        return INSTANCE;
    }

    public static void main(String[] args) {
        Singleton m1 = Singleton.getInstance();
        Singleton m2 = Singleton.getInstance();
        System.out.println(m1 == m2);
    }
}
```

## 饿汉式

### null判断

> 这种方式在getInstance时才会创建类的实例
>
> 但是在多线程访问时会出现问题, 当多个线程执行到if(INSTANCE == null) 空时可能出现问题
>
> 这种方式会被反射, 反序列化, 克隆破坏

```java
public class Singleton{
    private static Singleton INSTANCE;
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        if(INSTANCE == null){
            INSTANCE = new Singleton();
        }
        return INSTANCE;
    }
}
```

### synchronized方法null判断

> 这种方式虽然多线程不会出现问题, 但是因为是方法锁, 所以效率低下
>
> 这种方式会被反射, 反序列化, 克隆破坏

```java
public class Singleton{
    private static Singleton INSTANCE;
    
    private Singleton(){}
    
    public static synchronized Singleton getInstance(){
        if(INSTANCE == null){
            INSTANCE = new Singleton();
        }
        return INSTANCE;
    }
}
```

### synchronized块null判断

> 这种方式实际上不是线程安全的, 有可能有两个线程都通过了null判断, 然后枪锁, new对象

```java
public class Singleton{
    private static Singleton INSTANCE;
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        if(INSTANCE == null){
            synchronized(Singleton.class){
                INSTANCE = new Singleton();   
            }
        }
        return INSTANCE;
    }
}
```

### 双重检查

> 这种方式多线线程访问不会出现问题
>
> 第一个null判断, 是为了节约时间, 提升性能不用频繁获取锁
>
> 第二个则是为了保障, 不会出现多个对象通过null判断出现的问题
>
> 这种方式会被反射, 反序列化, 克隆破坏

```java
public class Singleton{
    private static Singleton INSTANCE;
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        if(INSTANCE == null){
            synchronized(Singleton.class){
                if(INSTANCE == null){
                	INSTANCE = new Singleton();   
                }
            }
        }
        return INSTANCE;
    }
}
```

- 双重检查也可能出现问题, java有指令重排优化, 需要加入volatile强制INSTANCE是一个原子操作

```java
public class Singleton{
    private static volatile Singleton INSTANCE;
    
    private Singleton(){}
    
    public static Singleton getInstance(){
        if(INSTANCE == null){
            synchronized(Singleton.class){
                if(INSTANCE == null){
                	INSTANCE = new Singleton();   
                }
            }
        }
        return INSTANCE;
    }
}
```

### 私有静态内部类

> JVM保障SingletonHolder只加载一次, 同时JVM也保障线程安全
>
> 这种方式会被反射, 反序列化, 克隆破坏

```java
public class Singleton{
    private Singleton(){}
    
    private static class SingletonHolder{
        private static final Singleton INSTANCE = new Singleton();
    }
    
    public static Singleton getInstance(){
        return SingletonHolder.INSTANCE;
    }
}
```

### 枚举单例

> 枚举类天生就是单例的, 并且枚举类可以防止反射, 反序列化, 克隆破坏单例

```java
public enum Singleton{
    INSTANCE;
    
    public static Singleton getInstance(){
        return INSTANCE;
    }
}
```

