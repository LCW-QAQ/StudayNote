# Facade

> 门面模式为客户提供一个Facade接口, 这个接口是为子系统功能提供的公共接口
>
> 我们只需调用Facade接口, 就可以实现子系统功能, 而不需要将各种功能耦合到客户中

```java
public enum  GamerDrawer {
    GAMER_DRAWER;
    public void drawGamer(){
        System.out.println("drawGamer");
    }
}
```

```java
public enum  WindowFrame {
    WINDOW_FRAME;
    public void drawFrame(){
        System.out.println("drawFrame");
    }

    public void setCoordinate(){
        System.out.println("setCoordinate");
    }
}
```

```java
public class MyGUIDrawer {
    public GamerDrawer gamerDrawer = GamerDrawer.GAMER_DRAWER;
    public WindowFrame windowFrame = WindowFrame.WINDOW_FRAME;

    public void drawGUI(){
        gamerDrawer.drawGamer();
        windowFrame.drawFrame();
    }
}
```

```java
public class GameMain {
    public static void main(String[] args) {
        MyGUIDrawer myGUIDrawer = new MyGUIDrawer();
        myGUIDrawer.drawGUI();
    }
}
```

