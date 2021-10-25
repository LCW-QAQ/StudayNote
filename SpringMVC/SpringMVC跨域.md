## mvc 跨域配置

```java
/*
web mvc 配置
 */
@Configuration
@EnableWebMvc
public class ConfigurerAdapter implements WebMvcConfigurer {
    /*
    配置跨域
     */
    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        CorsConfiguration config = new CorsConfiguration();
        // 允许请求带有验证信息
        config.setAllowCredentials(true);
        // 允许所有客户端
        config.addAllowedOrigin("*");
        // 允许任何请求头
        config.addAllowedHeader("*");
        // 允许所有方法
        config.addAllowedMethod("*");
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
```