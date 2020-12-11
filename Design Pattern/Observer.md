# Observer

> 观察者模式可以在某个对象执行一个操作后, 做出一个反应
>
> Observer Event Source的依赖关系, Observer是观察者, Event是事件, 而Source是被观察对象

```java
public interface ChildObserver {
    void actionOnWkeUp(Event event);
}
public class Dad implements ChildObserver{
    @Override
    public void actionOnWkeUp(Event event) {
        System.out.println("f k y o u r m o n t h e r");
    }
}
```

```java
public interface Event<T> {
    T getSource();
}

public class WakeEvent implements Event<Child>{
    private long time;
    private Child source;

    public WakeEvent(){};

    public WakeEvent(long time) {
        this.time = time;
    }

    @Override
    public Child getSource() {
        return source;
    }
}
```



```java
public class Child {
    private Boolean cry;
    private List<ChildObserver> observers = new ArrayList<>();

    {
        observers.add(new Dad());
    }

    public boolean isCry() {return cry;}

    public void wakeUp(){
        cry = true;
        WakeEvent wakeEvent = new WakeEvent(System.currentTimeMillis());
        for(ChildObserver observer : observers){
            observer.actionOnWkeUp(wakeEvent);
        }
    }

    public Boolean getCry() {
        return cry;
    }

    public void setCry(Boolean cry) {
        this.cry = cry;
    }
}
```

```java
public static void main(String[] args) {
    Child child = new Child();
    child.wakeUp();
}
```

