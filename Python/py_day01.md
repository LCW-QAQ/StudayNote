# 函数

## 函数参数

### 形参默认值

python的函数支持形参默认值

```python
def f(a,b=1):
    print(a,b)
```

### 传参时指定形参列表

```python
def f(a, b):
    print(a, b)
```

调用时可以

```python
f(b=1,a=2) --> 1 2
f(a=2,b=1) --> 2 1
```

### 控制强制显示/非显示传参

```python
# 传参时, 不能直接传入, 必须显示传入f(a=1)
def f(*, a):
    print(a)
    
# f(1)
# Traceback (most recent call last):
#   File "<input>", line 1, in <module>
# TypeError: f() takes 0 positional arguments but 1 was given
```

```python
# 传参时, 不能显示传入值, f(a=1)会报错
def f(a, /):
    print(a)
    
# f(a=1)
# Traceback (most recent call last):
#   File "<input>", line 1, in <module>
# TypeError: f() got some positional-only arguments passed as keyword arguments: 'a'
```

```python
# a不能显示传入, bcd都必须显示传入
def f(a, /, *, b, c, d='default'):
    print(a,b,c,d)    
    
f(1,b=2,c=3) --> successed    
```

## 作用域

```python
def scope_test():
    def do_local():
        spam = "local spam"

    def do_nonlocal():
        nonlocal spam
        spam = "nonlocal spam"

    def do_global():
        global spam
        spam = "global spam"

    # 这是一个当前函数作用域中的spam
    spam = "test spam"
    # 这个操作只会更改do_local函数作用域中的spam
    do_local()
    print("After local assignment:", spam)
    # 会更改当前函数作用域中的spam
    do_nonlocal()
    print("After nonlocal assignment:", spam)
    # 会更改全局变量spam
    do_global()
    # 上面虽然更改了全局的spam, 但是这里仍然还是打印的,当前函数作用域中的spam
    print("After global assignment:", spam)

scope_test()
print("In global scope:", spam)
```