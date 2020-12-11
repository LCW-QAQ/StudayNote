# Servlet乱码

## Request

### Get请求

1. 使用new String(str.getBytes("iso-8859-1"), "utf-8"); 解析字符串为uft-8
2. 设置request.setCharacterEncoding("utf-8");并且在server.xml中\<encoding\>中添加useBodyEncodingForURI=true;
3. 在server.xml中设置URIEncoding='utf-8'

### Post请求

1. 设置request.setCharacterEncoding("utf-8");

## Response

1. 设置response.setCharacterEncoding("gbk");