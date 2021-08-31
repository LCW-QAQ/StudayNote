# 响应式Web

## SSE (ServerSentEvent)

> 服务端消息推送

http请求无法做到服务器主动推送消息, SSE本质就是一个数据流, 不断的发送数据包, 客户端连接不会关闭, 会一直等待新的数据包发过来

最典型的例子就是视频播放, 视频就是数据流, 不停的获取新的字节信息, 渲染显示

### SSE 与  WebSocket的区别

1. WebSocket更加强大灵活, ws可以双端通信, 而SSE则是服务端可以主动推送消息, 客户端无法发送, 因为数据流的本质就是下载, 不停的下载, 如果发送消息, 就相当于发送一次http请求, 无法长连接

2. SSE就是一个http请求, 大多数服务器软件都支持, WS是一个独立的协议
3. SSE更加轻量级, 而WS很复杂
4. SSE默认就支持断线重连, WS需要手动实现
5. SSE只能发送文本, 二进制需要编码, 而WS支持传输二进制数据

### 服务端代码

```java
@RestController
public class MainController {

    private static ConcurrentHashMap<Integer, SseEmitter> sseMap = new ConcurrentHashMap<>();

    /**
     * 前端长轮询, 模拟长连接. 模拟异步
     * 真正的异步不能使用http, http是短连接
     */
    @RequestMapping(value = "sse", produces = "text/event-stream;charset=utf-8")
    public Object xxoo() {
        // event-stream, 一定要加`data:`, 表示返回的数据, 结尾两个\n表示该数据流结束了
        return "data: " + new Date() + "\n\n";
    }

    /**
     * 客户端订阅服务器
     * @param id 客户端唯一标识
     * @return 返回SSE对象
     */
    @GetMapping("subscribe")
    public SseEmitter subscribe(Integer id) {
        // 设置一个小时过期
        SseEmitter sse = new SseEmitter(3600000L);
        sseMap.put(id, sse);
        sse.onTimeout(() -> {
            sseMap.remove(id);
        });
        /*sse.onCompletion(() -> {
            System.out.println("完成!");
        });*/
        return sse;
    }

    /**
     * 服务端手动发送消息给指定id的客户端
     * @param id 客户端id
     * @param content 消息
     * @return don't care
     */
    @GetMapping("push")
    public String push(Integer id, String content) {
        SseEmitter sse = sseMap.get(id);
        if (sse != null) {
            try {
                sse.send(content);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return "over";
    }

    /**
     * 服务端发送消息给所有订阅的客户端
     * @param content 消息
     * @return don't care
     */
    @GetMapping("pushAll")
    public String pushAll(String content) {
        sseMap.forEach((id, sse) -> {
            try {
                sse.send(content);
            } catch (IOException e) {
                e.printStackTrace();
            }
        });
        return "over";
    }
}

```

### 前端代码

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>User1</title>
</head>
<script>
  let sse = new EventSource("http://localhost:8080/subscribe?id=1"); // 开启多个页面给定不同id即可
  sse.onmessage = function (event) {
    console.log(event);
    let res = document.getElementById("res").innerText;
    res += "\n" + event.data;
    document.getElementById("res").innerText = res;
  }
</script>
<body>
<span id="res"></span>
</body>
</html>
```

