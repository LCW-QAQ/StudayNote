# Servlet生命周期

1. 在Tomcat接收到第一次请求之后, 才会初始化Servlet对象, 之后再接收请求就不会执行Init了
2. Servlet在Tomcat容器销毁后才会销毁
3. 在xml配置中配置了load on startup后, 在tomcat创建之后Servlet就会直接初始化, 而不会等到接收到第一个请求

![Servlet生命周期](Servlet生命周期.assets/Servlet生命周期.png)