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

## RememberMe

```java
@Override
protected void configure(HttpSecurity http) throws Exception {
    // 开启记住用户功能
    http.rememberMe();
}
```

```html
<!-- 表单中使用remember-me控制是否记住 -->
<form action="/login" method="post">
    <input type="text" name="userName"><br>
    <input type="password" name="pwd"><br>
    <input type="checkbox" name="remember-me">记住我<br>
    <!-- 开启csrf后, 请求需要带上token -->
    <input type="text" name="#(_csrf.parameterName)" value="#(_csrf.token)"><br>
    <input type="submit">
</form>
```

## 自定义登录/登出

登录

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Login</title>
</head>
<body>
<form action="/login" method="post">
    <input type="text" name="userName"><br>
    <input type="password" name="pwd"><br>
    <input type="checkbox" name="remember-me">记住我<br>
    <input type="text" name="#(_csrf.parameterName)" value="#(_csrf.token)"><br>
    <input type="submit">
</form>
</body>
</html>
```

自定义页面后, 登出必须使用Post请求

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Title</title>
</head>
<body>
<form action="#(ctx.getContextPath())/logout" method="post">
    <input type="text" name="#(_csrf.parameterName)" value="#(_csrf.token)"><br>
    <input type="submit" value="POST Logout">
</form>
</body>
</html>
```

## Config类中权限控制

```java
protected void configure(HttpSecurity http) throws Exception {
    http.authorizeRequests()
        // 指定角色才能访问
        // Role => URL
        // 有具体权限才能访问
        // Authority => URL
        .antMatchers("/admin/**").hasRole("admin")
        .antMatchers("/user/**").hasRole("user")
}
```

## 角色权限继承

```java
// 配置角色继承关系
@Bean
public RoleHierarchy roleHierarchy() {
    RoleHierarchyImpl roleHierarchy = new RoleHierarchyImpl();
    // 父继承关系包含所有子角色的权限
    roleHierarchy.setHierarchy("ROLE_admin > ROLE_user > ROLE_guest");
    return roleHierarchy;
}
```

## 在Controller中权限控制

需要在Config类中开启@EnableGlobalMethodSecurity(securedEnabled = true, prePostEnabled = true)

```java
@Controller
public class MainController {
    // 无需权限
    @GetMapping("/hi")
    @ResponseBody
    public String hi() {
        System.out.println("来了老弟");
        return "hi";
    }

    @GetMapping("/admin/hi")
    @ResponseBody
    // 或者关系 不支持并且
    @Secured({"ROLE_admin"})
    public String adminHi() {
        return "hi";
    }

    @GetMapping("/user/hi")
    @ResponseBody
    // 使用SpringEL表达式, 支持并且关系
    @PreAuthorize("hasRole('ROLE_user')")
    public String userHi() {
        return "hi";
    }

    @GetMapping("/adminUser/hi")
    @ResponseBody
    // 如果配置了权限继承, 会按照继承关系匹配多个角色
    @PreAuthorize("hasRole('ROLE_user') and hasRole('ROLE_admin')")
    public String adminUserHi() {
        return "hi";
    }

    @GetMapping("/guest/hi")
    @ResponseBody
    @PreAuthorize("hasAnyRole('ROLE_admin', 'ROLE_user', 'ROLE_guest')")
    public String guestHi() {
        return "hi";
    }
}
```

## @PostAuthorize注解

```java
// 当PostAuthorize注解中的表达式值为true时, 正常返回, 否则403
// 使用场景: 挂系统的权限认证, 通过对方返回的值, 认证权限
@GetMapping("testPostAuthorize")
@ResponseBody
@PostAuthorize("returnObject == 1")
public int testPostAuthorize() {
    return new Random().nextInt(2);
}
```

