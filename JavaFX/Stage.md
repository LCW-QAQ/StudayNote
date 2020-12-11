# JFX Stage

```java
package day01;

import javafx.application.Application;
import javafx.scene.Group;
import javafx.scene.Scene;
import javafx.scene.image.Image;
import javafx.stage.Stage;

/**
 * @author lcw
 * @date 2020-12-03
 */
public class StageDemo extends Application {
    @Override
    public void start(Stage primaryStage) throws Exception {
        primaryStage.setTitle("HelloWorld");
        primaryStage.getIcons().add(new Image("file:src/icon/a1.png"));
//        primaryStage.setIconified(true);//最小化
//        primaryStage.setMaximized(true);//最大化
//        primaryStage.setResizable(false);//设置窗口大小不可更改
        primaryStage.setWidth(500);
        primaryStage.setHeight(500);
//        primaryStage.setMaxWidth(800);
//        primaryStage.setMaxHeight(800);
//        System.out.println("width:"+primaryStage.getWidth());
//        System.out.println("height:"+primaryStage.getHeight());
        primaryStage.setFullScreen(true);//设置全屏
        primaryStage.setScene(new Scene(new Group()));//设置全屏必须添加一个Scene
        primaryStage.show();
    }

    public static void main(String[] args) {
        launch(args);
    }
}
```

