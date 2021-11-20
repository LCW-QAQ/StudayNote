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

### Security相关Properties

```java
@Getter
@Setter
@Component
@ConfigurationProperties(prefix = "jwt")
public class SecurityProperties {
    /**
     * 令牌头
     */
    private String tokenHeader;

    /**
     * 令牌前缀
     */
    private String tokenStartWith;

    /**
     * 令牌过期时间 单位: 毫秒
     */
    private Long tokenExpiration;

    /**
     * redis 在线用户key前缀
     */
    private String onlineKey;

    /**
     * redis 验证码key前缀
     */
    private String codeKey;

    /**
     * jwt 盐
     */
    private String base64Secret;

    /**
     * 允许续约间隔 单位: 毫秒
     */
    private Long detect;

    /**
     * 续约多久 单位: 毫秒
     */
    private Long renew;

    public String getTokenStartWith() {
        return tokenStartWith + " ";
    }
}
```

### Token工具类

```java
@Component
@RequiredArgsConstructor
public class TokenProvider implements InitializingBean {
    private final SecurityProperties securityProperties;

    private final RedisTemplate<Object, Object> redisTemplate;

    private final RoleService roleService;

    public static final String AUTHORITIES_KEY = "user";

    private JwtParser jwtParser;

    private JwtBuilder jwtBuilder;

    @Override
    public void afterPropertiesSet() throws Exception {
        // 服务端盐
        final byte[] keyBytes = Decoders.BASE64.decode(securityProperties.getBase64Secret());
        SecretKey key = Keys.hmacShaKeyFor(keyBytes);
        jwtParser = Jwts.parserBuilder()
                .setSigningKey(key)
                .build();
        jwtBuilder = Jwts.builder()
                .signWith(key, SignatureAlgorithm.HS512);
    }

    public String createToken(Authentication authentication) {
        return jwtBuilder
                // 加入uuid 确保每次生成的token都不一样
                .setId(IdUtil.simpleUUID())
                .claim(AUTHORITIES_KEY, authentication.getName())
                .setSubject(authentication.getName())
                .compact();
    }

    public Authentication token2Authentication(String token) {
        final Claims claims = getClaims(token);
        final List<GrantedAuthority> gratedAuthorities
                = roleService.findGratedAuthorityByUsername(claims.getSubject());
        return new UsernamePasswordAuthenticationToken(claims.getSubject(), token, gratedAuthorities);
    }

    public Claims getClaims(String token) {
        return jwtParser.parseClaimsJws(token).getBody();
    }

    public void checkRenewal(String token) {
        // 还有多久毫秒过期
        Long time = redisTemplate.getExpire(securityProperties.getOnlineKey() + token, TimeUnit.MILLISECONDS);
        // 获取具体过期时间
        DateTime date = DateUtil.offset(new Date(), DateField.MILLISECOND, Math.toIntExact(time));
        // 计算离过期时间还有多久
        long diff = date.getTime() - System.currentTimeMillis();
        // 在续约范围内, 就续约
        if (diff >= 0 && diff <= securityProperties.getDetect()) {
            long renew = time + securityProperties.getRenew();
            redisTemplate.expire(securityProperties.getOnlineKey() + token, renew, TimeUnit.MILLISECONDS);
        }
    }

    public String getTokenFromRequest(HttpServletRequest req) {
        final String token = req.getHeader(securityProperties.getTokenHeader());
        if (token != null && token.startsWith(securityProperties.getTokenStartWith())) {
            return token.substring(7);
        }
        return null;
    }
}
```

### 处理Token

```java
@RequiredArgsConstructor
@Slf4j
public class JwtTokenFilter extends GenericFilterBean {

    private final TokenProvider tokenProvider;
    private final SecurityProperties securityProperties;
    private final OnlineUserService onlineUserService;
    private final UserCacheClean userCacheClean;

    @Override
    public void doFilter(ServletRequest servletReq, ServletResponse resp, FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) servletReq;
        // 从请求重提取token
        String token = resolveToken(req);
        // 如果有token
        if (StringUtils.hasText(token)) {
            OnlineUserDto onlineUserDto;
            // 根据token获取redis中的用户信息
            onlineUserDto = onlineUserService.getOne(securityProperties.getOnlineKey() + token);
            // redis中有对应的token
            if (onlineUserDto != null && StringUtils.hasText(token)) {
                // 根据token生成Authentication验证信息类, 包括用户信息, 权限等
                Authentication authentication = tokenProvider.token2Authentication(token);
                // 设置Authentication信息
                SecurityContextHolder.getContext().setAuthentication(authentication);
                // 续约
                tokenProvider.checkRenewal(token);
            }
        }
        chain.doFilter(req, resp);
    }

    /*
    解析token
     */
    private String resolveToken(HttpServletRequest req) {
        String tokenWithBearer = req.getHeader(securityProperties.getTokenHeader());
        if (StringUtils.hasText(tokenWithBearer) && tokenWithBearer.startsWith(securityProperties.getTokenStartWith())) {
            return tokenWithBearer.replace(securityProperties.getTokenStartWith(), "");
        } else {
            log.error("非法token: {}", tokenWithBearer);
        }
        return null;
    }
}
```

### 在线用户服务 (redis中用户Token的服务)

```java
@Service
@RequiredArgsConstructor
public class OnlineUserService {

    private final RedissonClient redissonClient;
    private final SecurityProperties securityProperties;

    public OnlineUserDto getOne(String onlineKey) {
        return onlineKey == null ? null : redissonClient.<OnlineUserDto>getBucket(onlineKey).get();
    }

    public void save(JwtUserDto jwtUserDto, String token) {
        RBucket<OnlineUserDto> onlineUserDtoBucket
                = redissonClient.getBucket(securityProperties.getOnlineKey() + token);
        final OnlineUserDto onlineUserDto = new OnlineUserDto(
                jwtUserDto.getUsername(),
                jwtUserDto.getUserDto().getNickName(),
                "", "", "", "", token, new Date()
        );
        onlineUserDtoBucket.set(onlineUserDto, securityProperties.getTokenExpiration(), TimeUnit.MILLISECONDS);
    }

    public void logout(String token) {
        final RBucket<OnlineUserDto> onlineUserDtoRBucket =
                redissonClient.getBucket(securityProperties.getOnlineKey() + token);
        onlineUserDtoRBucket.delete();
    }
}
```

### Security配置类

```java
@Configuration
@RequiredArgsConstructor
@EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true)
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    // 跨域过滤器
    private final CorsFilter corsFilter;

    // 用户访问但没有token或鉴权失败
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;

    // 用户没有权限访问该URL
    private final JwtAccessDeniedHandler jwtAccessDeniedHandler;

    // token工具
    private final TokenProvider tokenProvider;

    // Security相关配置
    private final SecurityProperties securityProperties;

    // 在线用户服务
    private final OnlineUserService onlineUserService;

    // useless
    private final UserCacheClean userCacheClean;

    /*
    去除 ROLE_ 前缀
     */
    @Bean
    GrantedAuthorityDefaults grantedAuthorityDefaults() {
        return new GrantedAuthorityDefaults("");
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable() // 关闭csrf
                // 跨域过滤器
                .addFilterBefore(corsFilter, UsernamePasswordAuthenticationFilter.class)
                .exceptionHandling()
                .authenticationEntryPoint(jwtAuthenticationEntryPoint)
                .accessDeniedHandler(jwtAccessDeniedHandler)
                .and()
                // 防止iframe 造成跨域
                .headers()
                .frameOptions()
                .disable()
                .and()
                // 无状态, 不创建session
                .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                .and()
                // 配置无需鉴权的url
                .authorizeRequests()
                .antMatchers(HttpMethod.POST,
                        "/auth/login", "/auth/logout").permitAll()
                .antMatchers(HttpMethod.GET, "/auth/code", "/hello*").permitAll()
                .antMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                .anyRequest().authenticated()
                .and()
                .apply(tokenConfigurer());
    }

    // 其他配置
    private TokenConfigurer tokenConfigurer() {
        return new TokenConfigurer(
                tokenProvider, securityProperties,
                onlineUserService, userCacheClean
        );
    }
}
```

```java
@RequiredArgsConstructor
public class TokenConfigurer extends SecurityConfigurerAdapter<DefaultSecurityFilterChain, HttpSecurity> {

    private final TokenProvider tokenProvider;

    private final SecurityProperties securityProperties;

    private final OnlineUserService onlineUserService;

    private final UserCacheClean userCacheClean;

    @Override
    public void configure(HttpSecurity http) throws Exception {
        final JwtTokenFilter tokenFilter = new JwtTokenFilter(tokenProvider, securityProperties,
                onlineUserService, userCacheClean);
        // 配置自定义过滤器
        http.addFilterBefore(tokenFilter, UsernamePasswordAuthenticationFilter.class);
    }
}
```

### 权限Api Demo

```java
@RestController
@RequestMapping("/auth")
@RequiredArgsConstructor
public class AuthorizationController {

    private final LoginProperties loginProperties;
    private final SecurityProperties securityProperties;
    private final RedissonClient redissonClient;
    private final AuthenticationManagerBuilder authenticationManagerBuilder;
    private final TokenProvider tokenProvider;
    private final OnlineUserService onlineUserService;
    private final SecurityUtilService securityUtilService;

    @PostMapping("login")
    public ResponseEntity<Object> login(@RequestBody @Valid AuthUserDto authUserDto, HttpServletRequest req) {
        RBucket<String> codeBucket = redissonClient.getBucket(authUserDto.getUuid());
        // 获取验证码
        String code = codeBucket.get();
        // 删除验证码
        codeBucket.delete();
        if (!StringUtils.hasText(code)) {
            return ResponseEntity.badRequest().body("验证码不存在或已过期");
        }
        if (!StringUtils.hasText(authUserDto.getCode()) || !authUserDto.getCode().equalsIgnoreCase(code)) {
            return ResponseEntity.badRequest().body("验证码错误");
        }
        // 创建security token对象, 由spring security authenticationManagerBuilder 认证
        final UsernamePasswordAuthenticationToken authToken =
                new UsernamePasswordAuthenticationToken(authUserDto.getUsername(), authUserDto.getPassword());
        Authentication authenticate;
        try {
            // 调用鉴权方法, 认证失败会抛出AuthenticationException
            authenticate = authenticationManagerBuilder.getObject().authenticate(authToken);
        } catch (AuthenticationException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
        SecurityContextHolder.getContext().setAuthentication(authenticate);
        // 运行到这里登陆成功, 如果用户名或密码错误, 在上面认证的时候就会抛出异常
        // 创建令牌
        String token = tokenProvider.createToken(authenticate);
        JwtUserDto jwtUserDto = (JwtUserDto) authenticate.getPrincipal();
        onlineUserService.save(jwtUserDto, token);
        // 返回token与用户信息
        Map<String, Object> authInfo = new HashMap<String, Object>() {{
            put("token", securityProperties.getTokenStartWith() + token);
            put("user", jwtUserDto);
        }};
        return ResponseEntity.ok(authInfo);
    }

    @GetMapping("code")
    public ResponseEntity<Object> getCode() {
        Captcha captcha = loginProperties.getCaptcha();
        String uuid = securityProperties.getCodeKey() + IdUtil.simpleUUID();
        String captchaValue = captcha.text();
        // 当验证码类型为 ARITHMETIC 且 length>=2 时, 结果有可能是浮点数
        if (captcha.getCharType() - 1 == LoginCodeEnum.ARITHMETIC.ordinal() && captchaValue.contains(".")) {
            // 去除小数点
            captchaValue = captchaValue.split("\\.")[0];
        }
        final RBucket<String> captchaBucket = redissonClient.getBucket(uuid);
        captchaBucket.set(captchaValue, loginProperties.getLoginCode().getExpiration(), TimeUnit.MINUTES);
        Map<String, String> imgResult = new HashMap<String, String>(2) {{
            put("img", captcha.toBase64());
            put("uuid", uuid);
        }};
        return ResponseEntity.ok(imgResult);
    }

    // 获取用户信息
    @GetMapping("info")
    public ResponseEntity<Object> getUserInfo() {
        HashMap<String, Object> map = new HashMap<String, Object>(){{
            put("user", securityUtilService.getCurrentUser());
        }};
        return ResponseEntity.ok(map);
    }

    // 登出
    @PostMapping("logout")
    public ResponseEntity<Object> logout(HttpServletRequest req) {
        onlineUserService.logout(tokenProvider.getTokenFromRequest(req));
        return ResponseEntity.ok().build();
    }
}
```
