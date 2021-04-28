# SpringMVC

## DispatcherServlet Url Pattern 注意事项

```
/* 和 / 都是拦截所有请求，/ 会拦截的请求不包含*.jsp,而  /* 的范围更大，还会拦截*.jsp这些请求
<!--匹配servlet的请求，
    /：标识匹配所有请求，但是不会jsp页面
    /*：拦截所有请求，拦截jsp页面

     但是需要注意的是，当配置成index.html的时候，会发现请求不到
     原因在于，tomcat下也有一个web.xml文件，所有的项目下web.xml文件都需要继承此web.xml
     在服务器的web.xml文件中有一个DefaultServlet用来处理静态资源，但是url-pattern是/
     而我们在自己的配置文件中如果添加了url-pattern=/会覆盖父类中的url-pattern，此时在请求的时候
     DispatcherServlet会去controller中做匹配，找不到则直接报404
     而在服务器的web.xml文件中包含了一个JspServlet的处理，所以不过拦截jsp请求
    -->
```

## RequestMapping 模糊匹配

```
@Request包含三种模糊匹配的方式，分别是：
?：能替代任意一个字符
*: 能替代任意多个字符和一层路径
**：能代替多层路径
```

## 下载文件

```java
@RequestMapping("download")
public ResponseEntity<byte[]> download(HttpServletRequest req) {
    ServletContext context = req.getServletContext();
    String realPath = context.getRealPath("/files/DBUtils-1.0-SNAPSHOT.jar");
    byte[] bytes = null;
    try (BufferedInputStream bis = new BufferedInputStream(new FileInputStream(realPath))) {
        bytes = new byte[bis.available()];
        bis.read(bytes);
    } catch (IOException e) {
        e.printStackTrace();
    }
    HttpHeaders httpHeaders = new HttpHeaders();
    httpHeaders.set("Content-Disposition", "attachment:filename=DBUtils-1.0-SNAPSHOT.jar");
    return new ResponseEntity<byte[]>(bytes, httpHeaders, HttpStatus.OK);
}
```

## 上传文件

```java
// 多文件上传
@RequestMapping("/upload")
public String upload(@RequestParam("file") MultipartFile[] multipartFile,
                     @RequestParam(value = "desc", required = false) String desc) {
    for (MultipartFile mf : multipartFile) {
        try {
            if (mf != null) {
                mf.transferTo(
                        new File("D:\\study\\reivew\\springmvc_json\\web\\files\\" +
                                mf.getOriginalFilename()));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    return "success";
}
```