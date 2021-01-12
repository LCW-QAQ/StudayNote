# Springboot跨域配置

```java
package com.lcw.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.filter.CorsFilter;

/**
 * @author lcw
 * @since 2021-01-05
 */
@Configuration
public class CorsConfig {

    private CorsConfiguration buildCorsConfig() {
        CorsConfiguration corsConfiguration = new CorsConfiguration();
        /*设置跨域需要的属性*/
        //允许跨域请求的地址, *表示所有
        corsConfiguration.addAllowedOriginPattern("*");
        //配置跨域的请求头
        corsConfiguration.addAllowedHeader("*");
        //配置跨域的请求方法
        corsConfiguration.addAllowedMethod("*");
        //表示跨域请求是否使用的是 同一个Session
        corsConfiguration.setAllowCredentials(true);
        return corsConfiguration;
    }

    @Bean
    public CorsFilter corsFilter() {
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", buildCorsConfig());
        return new CorsFilter(source);
    }
}
```

