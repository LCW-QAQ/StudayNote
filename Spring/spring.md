# SpringIOC

## SpringIOC 中的对象在什么时候被创建

1. 默认情况下IOC容器中的对象是单例的, 在IOC容器创建时, 被创建
2. 如果对象scope属性被设置为property, 则对象将会是多例, 在需要时, 被创建

## SpringIOC Bean对象init和destroy方法

1. singleton
    - 初始化和销毁都会调用, 对象想创建时init, IOC容器销毁时destroy
2. prototype
    - 初始化方法会调用, 销毁方法不会调用

## SpringIOC 和 DI 是什么

IOC指的是 Iversion Of Control 即控制翻转, 应用自己不再负责依赖对象的创建和维护, 依赖对象是IOC容器来负责的, 这样一来控制权就从应用转移到了外部容器

DI值得是 Dependency Injection 即依赖注入, 程序运行期间, 动态的将依赖对象注入(创建)到程序中, 通过反射完成

## SpringIOC容器的初始化过程

1. 设置首先会去创建扫描Xml的类对象 资源匹配处理器 ResourcePatternResolver
2. setConfigLocations 配置初始化
    1. 获取系统环境变量
    2. 加载 application.xml
        1. 处理application.xml
            1. resloverPlaceholder 解析 SpringEL
3. refresh 刷新过程有synchronized同步代码块 保证容器状态不会出错
    1. prepareRefresh 准备刷新Context
        1. 设置启动时间 开启 关闭 状态
        2. initPropertySources 初始化占位符资源
            - 默认没有实现留给子类实现, 方便扩展, 替换其他的资源占位符, 列如自定义的表达式或其他框架的占位符(表达式)处理
        3. validateRequiredProperties 验证环境对象中必要的配置是否加载成功
        4. 存储预创建的程序程序监听器
    2. obtainFreshBeanFactory 刷新内部的Bean工厂

