# SwaggerQuickStart

引入一下依赖

```xml
<properties>
    <!-- 注意高版本依赖可能出现问题 -->
    <swagger.version>2.10.5</swagger.version>
</properties>

<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger2</artifactId>
    <version>${swagger.version}</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-swagger-ui</artifactId>
    <version>${swagger.version}</version>
</dependency>
<dependency>
    <groupId>io.springfox</groupId>
    <artifactId>springfox-spring-webmvc</artifactId>
    <version>${swagger.version}</version>
</dependency>
```

配置类

```java
@Configuration
@EnableSwagger2WebMvc
public class SwaggerConfig {

    @Bean
    public Docket createRestApi() {
        return new Docket(DocumentationType.SWAGGER_2)
                .apiInfo(apiInfo())
                .select()
                .apis(RequestHandlerSelectors.basePackage("com.demo.temactivitiesboot.controller"))
//                .apis(RequestHandlerSelectors.withClassAnnotation(Api.class))
                .paths(PathSelectors.any())
                .build()
	            // 开启全站认证
                // .securityContexts(List.of(securityContext()))
                // 配置下面这个，只有在@APIOperation(authorizations = @Authorization("Token"))才会校验
                // ApiKey的name需与SecurityReference的reference保持一致
                .securitySchemes(List.of(
                        new ApiKey("Token", "Token", "header")
                ));;
    }
    
    private SecurityContext securityContext() {
        return SecurityContext.builder()
                .securityReferences(defaultAuth())
                .build();
    }

    private List<SecurityReference> defaultAuth() {
        AuthorizationScope authorizationScope
                = new AuthorizationScope("global", "accessEverything");
        AuthorizationScope[] authorizationScopes = {authorizationScope};
        return Collections.singletonList(
                new SecurityReference("Token", authorizationScopes)
        );
    }

    public ApiInfo apiInfo() {
        System.out.println("------------------" + port);
        return new ApiInfoBuilder()
                .title("接口文档")
                .description("swagger自动生成的接口文档")
                .version("1.0")
                .build();
    }
}
```

