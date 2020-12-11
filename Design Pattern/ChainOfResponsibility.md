# ChainOfResponsibility

> 责任链模式给请求创建了一个接收对象的链  
> 形成以个链条, 对象依次被链条上得到对象处理 

```java
class Request {
    private String request;

    public Request() {
    }

    public Request(String request) {
        this.request = request;
    }

    public String getRequest() {
        return request;
    }

    public void setRequest(String request) {
        this.request = request;
    }

    @Override
    public String toString() {
        return "Request{" +
                "request='" + request + '\'' +
                '}';
    }
}

class Response {
    private String response;

    public Response() {
    }

    public Response(String response) {
        this.response = response;
    }

    public String getResponse() {
        return response;
    }

    public void setResponse(String response) {
        this.response = response;
    }

    @Override
    public String toString() {
        return "Response{" +
                "response='" + response + '\'' +
                '}';
    }
}

interface Filter {
    boolean doFilter(Request request, Response response, FilterChain filterChain);
}

class FilterChain implements Filter{

    private List<Filter> filterList = new ArrayList<>();
    private int index;//定义index来记录链条执行到哪里了

    public FilterChain add(Filter filter){
        filterList.add(filter);
        return this;
    }

    @Override
    public boolean doFilter(Request request, Response response, FilterChain filterChain) {
        if(index == filterList.size()) return false;//执行到链条最后时, 就不执行了
        Filter filter = filterList.get(index);
        index++;
        return filter.doFilter(request, response, filterChain);
    }
}

class HTMLFilter implements Filter{
    @Override
    public boolean doFilter(Request request, Response response, FilterChain filterChain) {
        String str = request.getRequest();
        request.setRequest(str.replace("<","[").replace(">", "]"));
        //类似于递归的方式, 在filter中的response执行之前调用, 执行链条的下一个, 最后就会形成一个闭环
        //最先执行完成的response是链条的最后一项
        filterChain.doFilter(request, response, filterChain);
        String newRe = response.getResponse();
        response.setResponse(newRe+="--HTMLFilter");
        return true;
    }
}
class WordFilter implements Filter{
    @Override
    public boolean doFilter(Request request, Response response, FilterChain filterChain) {
        String newRe = response.getResponse();
        if(request.getRequest().contains("996")){
            request.setRequest(request.getRequest().replace("996", "995"));
            filterChain.doFilter(request, response, filterChain);
            response.setResponse(newRe += "--WordFilter");
            return false;
        }
        filterChain.doFilter(request, response, filterChain);
        response.setResponse(newRe += "--WordFilter");
        return true;
    }
}
```

```java
public class Main {
    public static void main(String[] args) {
        FilterChain chain1 = new FilterChain();
        FilterChain chain2 = new FilterChain();
        chain1.add(new HTMLFilter())
                .add(chain2.add(new WordFilter()));
//        chain1.add(new WordFilter())
//                .add(new HTMLFilter());
//        Message message = new Message("<script>, 996");
        Request request = new Request("<script>, 996");
        Response response = new Response("");
        chain1.doFilter(request, response, chain1);
        System.out.println(request);
        System.out.println(response);

    }
}
```

