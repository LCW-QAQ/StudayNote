# 关于mapstruct动态生成的实现类, 没有注入属性, 只有父类属性或子类属性等问题

```xml
<!-- lombok -->
<dependency>
    <groupId>org.projectlombok</groupId>
    <artifactId>lombok</artifactId>
    <optional>true</optional>
</dependency>

<!-- !!!!!!!!!!!!!!!!!!!!!啊啊啊啊啊啊啊啊啊啊啊啊啊啊 -->
        <!--
        惊天巨坑
        - lombok必须在mapstruct前面不然会出问题
        - 更合适的解决方案是引入Lombok Mapstruct Binding插件
            - <groupId>org.projectlombok</groupId>
                    <artifactId>lombok-mapstruct-binding</artifactId>
              <version>Version</version> 
        必须保证lombok在mapstruct之前生成类
         -->

<!-- map struct -->
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct</artifactId>
    <version>${mapstruct.version}</version>
</dependency>
<dependency>
    <groupId>org.mapstruct</groupId>
    <artifactId>mapstruct-processor</artifactId>
    <version>${mapstruct.version}</version>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>javax.inject</groupId>
    <artifactId>javax.inject</artifactId>
    <version>1</version>
</dependency>
```

