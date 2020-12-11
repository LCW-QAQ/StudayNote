# Factory

## 普通工厂

```java
public class Factory{
    public Object getObject(){
        return new Object();
    }
}
```

## 静态工厂

```java
public class StaticFactory{
    public static Object getObject(){
        return new Object();
    }
}
```

> ​	静态工厂使用的不多, 静态方法不能被重写, 影响扩展性

## 工厂方法

> 抽象工厂在创建多个实体, 多个产品工厂是更加方便, 只需要创建实体对象, 然后再创建实体对应的工厂即可

```java
class Apple{
    public int weight;
    public double price;
}
class AppleFactory{
    public Apple getApple(){
        return new Apple();
    }
}
```

## 抽象工厂

> 抽象工厂适合创建一类产品, 可以在工厂里创建出一个产品簇, 然后再细分为多个实体产品

```java
class Food{
    public double price;
}
class Apple extends Food{
    public int weight;
    public double price;
}
abstract class AbstratFactory{
    abstract Food getFood();
}
class AppleFactory extends AbstratFactory{
    Food getFood(){
        return new Apple();
    }
}
```

