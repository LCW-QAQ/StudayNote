# SpringSecurityQuickStart

## 有状态会话

>创建SecurityConfig类并继承WebSecurityConfigurerAdapter

```java
@Configuration
public class SecurityConfig extends WebSecurityConfigurerAdapter {}
```

* 通常使用的都是自定的用户类， 所以需要使用自定义的UserDetailsService

    * 定义UserService并实现UserDetailsService接口

        * UserDetailsService接口中的loadUserByUsername方法的实现就决定了user存储的位置， 不需要再配置InMemory, InJDBC等

        * ```java
            @Component
            public class MyUserDetailsService implements UserDetailsService {
            
                @Autowired
                UserMapper userMapper;
            
                @Autowired
                RoleMapper roleMapper;
            
                @Override
                public UserDetails loadUserByUsername(String s) throws UsernameNotFoundException {
                    QueryWrapper<User> qwUser = new QueryWrapper<>();
                    qwUser.eq("username", s);
                    User user = userMapper.selectOne(qwUser);
                    if (user == null) {
                        throw new UsernameNotFoundException("用户名不存在!");
                    }
                    user.setRoles(roleMapper.getRolesByUserId(user.getId()));
                    return user;
                }
            }
            ```

* 自定义密码编码器

    * ```java
        @Bean
        PasswordEncoder passwordEncoder() {
            return new BCryptPasswordEncoder();
        }
        ```

* 重写参数为WebSecurity的configure方法, 可以配置忽略哪些请求

    * ```java
        public void configure(WebSecurity web) throws Exception {
            web.ignoring().antMatchers("/css/**", "/js/**", "/favicon.ico");
        }
        ```

* 重写参数为HttpSecurity的configure方法，这里有关于HttpSecurity的详细配置

    * ```java
        protected void configure(HttpSecurity http) throws Exception {
                // 鉴权所有请求
                http.authorizeRequests()
                        .anyRequest()
                        .authenticated() // 其余请求都需要鉴权
                        .and()
                        .formLogin()
                        .loginPage("/login")
        //                .loginPage("/login.html") // 具体的登录页面记得前面加上 `/`
                        .loginProcessingUrl("/doLogin")
        //                .successForwardUrl("/index")
                        // 登录成功处理
                        .successHandler((req, resp, auth) -> {
                            Cookie cookie = new Cookie("user", ((User) auth.getPrincipal()).getUsername());
                            cookie.setMaxAge((int) TimeUnit.MINUTES.toMillis(10));
                            resp.addCookie(cookie);
                            resp.sendRedirect("index");
                        })
                        // 登录失败处理
                        .failureHandler((req, resp, e) -> {
                            final PrintWriter out = resp.getWriter();
                            out.print("登录失败, " + e.getMessage());
                            out.close();
                        })
                        .permitAll() // 访问login doLogin 无需登录
                        .and()
                        // 有关登出的配置
                        .logout()
                        // 登出的处理
                        .logoutSuccessHandler((req, resp, auth) -> {
                            resp.setContentType("application/json;charset=utf-8");
                            PrintWriter out = resp.getWriter();
                            out.write(new ObjectMapper().writeValueAsString(ResultBean.ok("注销成功")));
                            out.flush();
                            out.close();
                        })
                        .permitAll() // 访问logout 无需登录
                        .and()
                        .csrf()
                        .disable() // 关闭csrf防护
                        // 有关异常处理
                        .exceptionHandling()
                        // 没有登录的时候，如何处理
                        .authenticationEntryPoint((req, resp, e) -> {
                            resp.setContentType("application/json;charset=utf-8");
                            resp.setStatus(401);
                            PrintWriter out = resp.getWriter();
                            ResultBean<Object> resBean = ResultBean.error("访问失败!");
                            if (e instanceof InsufficientAuthenticationException) {
                                resBean.setMsg("请求失败，请联系管理员! " + e.getMessage());
                            }
                            out.write(new ObjectMapper().writeValueAsString(resBean));
                            out.flush();
                            out.close();
                        });
            }
        ```

* 自定义登录逻辑 登录过滤器

    * ```java
        public class LoginFilter extends UsernamePasswordAuthenticationFilter {
        
            @Autowired
            MyUserDetailsService userDetailsService;
        
            @Autowired
            PasswordEncoder passwordEncoder;
        
            /*
            重写认证方法
             */
            @Override
            public Authentication attemptAuthentication(HttpServletRequest req, HttpServletResponse response) throws AuthenticationException {
                // 只支持使用POST请求
                if (!"POST".equals(req.getMethod())) {
                    throw new AuthenticationServiceException("not support method " + req.getMethod());
                }
                String code = req.getParameter("code");
                // 验证码
                checkCode(code);
                Optional<Cookie> userCookie = Arrays.stream(req.getCookies() != null ? req.getCookies() : new Cookie[]{})
                        .filter(c -> "user".equals(c.getName()))
                        .findFirst();
                String username;
                String password;
                if (userCookie.isPresent()) {
                    System.out.println(userCookie);
                    String uName = userCookie.get().getValue();
                    UserDetails userDetails = userDetailsService.loadUserByUsername(uName);
                    username = userDetails.getUsername();
                    password = username;
                } else {
                    username = req.getParameter("username");
                    password = req.getParameter("password");
                    if (username == null) username = "";
                    if (password == null) password = "";
                }
                username = username.trim();
                // SpringSecurity鉴权必备token对象
                UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(username, password);
                return this.getAuthenticationManager().authenticate(authToken);
            }
        
            public void checkCode(String code) {
                if (!code.equals(MainController.codeMap.get("code"))) {
                    throw new AuthenticationServiceException("验证码错误");
                }
            }
        }
        ```

    * 配置 loginFilter

        * ```java
            @Bean
            public LoginFilter loginFilter() throws Exception {
                LoginFilter loginFilter = new LoginFilter();
                // 登录成功处理
                loginFilter.setAuthenticationSuccessHandler((req, resp, auth) -> {
                    Cookie cookie = new Cookie("user", ((User) auth.getPrincipal()).getUsername());
                    cookie.setMaxAge((int) TimeUnit.MINUTES.toMillis(10));
                    resp.addCookie(cookie);
                    resp.sendRedirect("index");
                });
                // 登录失败处理
                loginFilter.setAuthenticationFailureHandler((req, resp, e) -> {
                    Optional<Cookie> userCookie = Arrays.stream(req.getCookies() != null ? req.getCookies() : new Cookie[]{})
                            .filter(c -> "user".equals(c.getName()))
                            .findFirst();
                    userCookie.ifPresent(c ->
                            c.setMaxAge(0));
                    resp.setContentType("application/json;charset=utf-8");
                    PrintWriter out = resp.getWriter();
                    out.print("登录失败, " + e.getMessage());
                    out.close();
                });
                // 登录请求
                loginFilter.setFilterProcessesUrl("/doLogin");
                // 配置鉴权管理器 使用默认的即可
                loginFilter.setAuthenticationManager(authenticationManagerBean());
                return loginFilter;
            }
            ```

        * 添加loginFilter过滤器

            * protected void configure(HttpSecurity http) 方法中添加过滤器

            * ```java
                http.addFilterAt(loginFilter(), UsernamePasswordAuthenticationFilter.class);
                ```
        

## 无状态会话
