# Adapter

> 适配器模式类似于我们使用的转接头, 两个不能直接关联/连接的接口, 可以通过Adapter中间适配, 来达到连接效果

```java
public static void main(String[] args) {
        BufferedInputStream bis = null;
        BufferedReader br = null;
        try {
            bis = new BufferedInputStream(new FileInputStream("src/main/java/com/lcw/adapter/text.txt"));
            //InputStreamReader就是一个适配器
            br = new BufferedReader(new InputStreamReader(bis));
            char[] buf = new char[16];
            int len;
            while((len = br.read(buf)) != -1){
                System.out.print(new String(buf, 0, len));
            }
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
```

> 主要WindowAdapter不是一个适配器模式, 它也是一种设计思想, 用来解决我们的需求不一定要实现接口所有方法的问题
>
> 如下案列, 我们在添加WindowListener不一定需要使用里面的所有方法
>
> 但是直接实现WindowListener就必须实现所有方法
>
> 因此我们可以通过抽象类WindowAdapter来简化, 在WindowAdapter中只是实现了WindowListener的所有方法, 但是没有具体操作
>
> 我们只需要按需求重写WindowsAdapter的方法即可, 不再需要重写所有方法

```java
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.event.WindowListener;

public class Test {
    public static void main(String[] args) {
        new Frame().addWindowListener(new WindowListener() {
            @Override
            public void windowOpened(WindowEvent e) {}

            @Override
            public void windowClosing(WindowEvent e) {}

            @Override
            public void windowClosed(WindowEvent e) {}

            @Override
            public void windowIconified(WindowEvent e) {}

            @Override
            public void windowDeiconified(WindowEvent e) {}

            @Override
            public void windowActivated(WindowEvent e) {}

            @Override
            public void windowDeactivated(WindowEvent e) {}
        });
        //WindowAdapter不是Adapter模式
        new Frame().addWindowListener(new WindowAdapter() {
            @Override
            public void windowOpened(WindowEvent e) {}
        });
    }
}

```

