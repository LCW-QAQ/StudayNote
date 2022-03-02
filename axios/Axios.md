# Axios

## get

`axios.get(url, config)`

注意get请求不能发送request body, 所以也不能发送json数据

使用案例:

`axios.get("/", {params: {name: "hello"}})`

## delete

`axios.delete(url, config)`

delete与get类似, 但是可以发送json

发送form-data `axios.get("/", {params: {name: "hello"}})`

发送json `axios.get("/", {data: {name: "hello"}})`

## post put patch

`axios.post(url, data, config)`

`axios.put(url, data, config)`

`axios.patch(url, data, config)`

其中data与config可以缺省

axios会自动判断发送什么Content-Type形式的数据, 默认无需设置

发送json ``axios.post("/", {name: "hello"}, {headers: {"Content-Type": "application/json"}})``

发送form-data ``axios.post("/", Qs.stringify({name: "hello"}))``

## axios传数组参数

默认以form-data传数组参数时, 会议`参数名 + []`的形式命名, 列如`ids[]`

springmvc可能不允许这种命名方式

解决方案

1. 可以使用json的方式

    - axios.post("/", [1,2,3,4])

2. 使用qs格式化

    - get与delete

    	- ```js
        axios.get(url, {
            params: {
                ids: [1,2,3],
                type: 1
            },
            paramsSerializer: params => {
                return qs.stringify(params, { indices: false })
            }})
        ```
      
    - post put patch
    
      - ```js
        axios.post(url, qs.stringify(
            params: {
             ids: [1,2,3],
             type: 1
            }, { indices: false }))
        
         axios.put(url, qs.stringify(params: {
             ids: [1,2,3],
             type: 1
            }, { indices: false }))
        ```
