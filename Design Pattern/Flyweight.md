# Flyweight

> 享元模式应用于大量对象需求的场景, 共享对象, 需要使用时, 从对象池中拿取, 不使用后, 返还给对象池, 下次需要直接拿取
>
> Flyweight就是池化思想

```java
public class Flyweight {
    private String msg;

    public Flyweight() {
    }

    public Flyweight(String msg) {
        this.msg = msg;
    }

    public String getMsg() {
        return msg;
    }

    public void setMsg(String msg) {
        this.msg = msg;
    }
}
```

```java
public class FlyweightFactory {
    private HashMap<String, Flyweight> map = new HashMap<>();

    public Flyweight createFlyweight(String str){
        if(!map.containsKey(str)){
            map.put(str, new Flyweight(str));
        }
        return map.get(str);
    }
}
```

```java
public class Main {
    public static void main(String[] args) {
        FlyweightFactory factory = new FlyweightFactory();
        Flyweight hello = factory.createFlyweight("hello");
        System.out.println(hello.getMsg());
        Flyweight hello1 = factory.createFlyweight("hello");
        System.out.println(hello1.getMsg());
        System.out.println(hello==hello1);
    }
}
```

