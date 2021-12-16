# Springboot SSE

> SSE Server Send Event
>
> 类似长轮询, 但是只需要发送一次请求, 没有值得时候, 阻塞, 有值返回.  一次请求对应多次数据
>
> 长轮询是服务端响应后, 再发一次请求.  一次请求多次轮询得到结果

## 坑!

1. produces设置为"text/event-stream;charset=utf-8"
2. 返回的结果必须以`data:`开头, `\n\n`结尾, 才算一条数据

## Code

```kotlin
@RestController
class TestSSEController {

    @GetMapping(value = ["/listener/sse"], produces = ["text/event-stream;charset=utf-8"])
    fun listenSSE(): String {
        println("sse hello")
        return "data:" + Math.random().toString() + "\n\n"
    }
}
```

