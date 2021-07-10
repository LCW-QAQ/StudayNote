# SpringSecurity

## Csrf  配置(新版本自动开启CSRF) 与简单权限认证配置

```java
@Configuration
@EnableWebSecurity
public class MyWebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    private PasswordEncoder encoder;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        // 哪些请求需要登录
        // PS: 需要配置路径的地方前面必须有 '/' 左斜杠
        http.authorizeRequests()
                // 任何请求
                .anyRequest()
                .authenticated()
                .and()
                .csrf().csrfTokenRepository(new HttpSessionCsrfTokenRepository())
                .and()
                // 配置登录
                .formLogin()
                // 配置登录页账号密码的参数名
                .usernameParameter("userName")
                .passwordParameter("pwd")
                // 自定义登录页面
                .loginPage("/login.html")
                // 登录处理请求
                .loginProcessingUrl("/login")
                // 登录成功页面
                .defaultSuccessUrl("/home", true)
                // 登录失败页面 无法获取错误信息
                .failureForwardUrl("/login.html?error")
                .failureHandler(new AuthenticationEntryPointFailureHandler(new AuthenticationEntryPoint() {
                    @Override
                    public void commence(HttpServletRequest httpServletRequest,
                                         HttpServletResponse httpServletResponse,
                                         AuthenticationException e) throws IOException, ServletException {
                        e.printStackTrace();
                        httpServletRequest.setAttribute("e", e);
                        httpServletRequest.setAttribute("msg", "权限认证出错");
                        httpServletRequest.getRequestDispatcher("error.html")
                                .forward(httpServletRequest, httpServletResponse);
                    }
                }))
                // 必须允许登录请求, 不然就无限转发了
                .permitAll();
    }

    // 配置权限认证
    // encoder加密的时候, 别把用户名加密了
    @Override
    protected void configure(AuthenticationManagerBuilder auth) throws Exception {
        auth.inMemoryAuthentication()
                .withUser("lcw").password(encoder.encode("lcw")).roles("admin")
                .and()
                .withUser("hello").password(encoder.encode("hello")).roles("user");
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
```

## 控制用户权限存储位置

### 内存

```java
@Bean
public UserDetailsService userDetailsService(DataSource dataSource) {
    // 基于内存存储用户
    InMemoryUserDetailsManager manager = new InMemoryUserDetailsManager();
    User user = new User("lcw",
                         encoder.encode("lcw"),
                         true, true, true, true,
                         Collections.singletonList(new SimpleGrantedAuthority("admin")));
    manager.createUser(user);
    manager.createUser(User.withUsername("hello").password(encoder.encode("hello")).build());
}
```

### 数据库

数据库DLL在`org.springframework.security.core.userdetails.jdbc.users.ddl`

```java
@Bean
public UserDetailsService userDetailsService(DataSource dataSource) {
    // 基于数据库存储用户
    JdbcUserDetailsManager manager = new JdbcUserDetailsManager(dataSource);
    manager.createUser(User.withUsername("hello")
                       .password(encoder.encode("hello"))
                       .roles("user")
                       .build());
    return manager;
}
```

## 权限控制忽略静态资源

```java
@Override
public void configure(WebSecurity web) throws Exception {
    // 忽略静态资源, 不需要权限认证
    web.ignoring().antMatchers("/img/**");
}
```

