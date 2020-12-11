# Print函数的格式化输出

:[parameter]

```rust
//错误格式化时,会报错,下面列举除了所有格式化字符
//注意格式化字符,区分大小写
the only appropriate formatting traits are:
           - ``, which uses the `Display` trait
           - `?`, which uses the `Debug` trait
           - `e`, which uses the `LowerExp` trait
           - `E`, which uses the `UpperExp` trait
           - `o`, which uses the `Octal` trait
           - `p`, which uses the `Pointer` trait
           - `b`, which uses the `Binary` trait
           - `x`, which uses the `LowerHex` trait
           - `X`, which uses the `UpperHex` trait
```

| 格式化字符 | 描述                                               |
| :--------- | :------------------------------------------------- |
| :          | 直接打印该结果(调用ToString)                       |
| :?         | 用于Debug(打印字符串时会打印引号,可用于打印struct) |
| :e         | 以科学计数法打印数值(e小写)                        |
| :E         | 以科学计数法打印数值(E大写)                        |
| :o         | 十进制数转换到八进制打印                           |
| :p         | 想要打印指针地址需要:p                             |
| :b         | 十进制数转换到二进制打印                           |
| :x         | 十进制数转换到十六进制(字母小写)                   |
| :X         | 十进制数转换到十六进制(字母大写)                   |

