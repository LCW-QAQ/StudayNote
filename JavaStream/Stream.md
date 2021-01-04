# Java Stream

# 常用的Stream创建

```java
public class CreateStreamDemo {

    //通过集合的stream方法创建
    @Test
    public void test01(){
        ArrayList<Integer> list = new ArrayList<Integer>();
        Stream<Integer> stream = list.stream();
        Stream<Integer> integerStream = list.parallelStream();
    }

    //Arrays工具类中的stream方法
    @Test
    public void tes02(){
        Integer[] nums = new Integer[]{1,2,3,4};
        Stream<Integer> stream = Arrays.stream(nums);
    }

    //通过Stream中的静态方法创建
    @Test
    public void test03(){
        Stream<Integer> integerStream = Stream.of(1, 2, 3, 4, 5, 6, 7);
        Stream.iterate(0, (t) -> ++t).limit(10).forEach(item -> System.out.print(item + " "));
        System.out.println();
        Stream.generate(() -> Math.round(Math.random()*101)).limit(10).forEach(item -> System.out.print(item + " "));
    }
}
```

# StreamAPI

## 构建型

### Stream.builder

> 返回一个Stream.Builder对象
>
> 用来创建流对象, `add`方法向流中添加元素, `accpet`方法也可以添加元素, 但是没有返回Stream.Builder对象

```java
public void test04() {
    Stream.Builder<Object> builder = Stream.builder();
    builder.add(1).add(2).add(3).accept(4);
    builder.build().forEach(System.out::println);
}
```

### Stream.concat

> 连接连个相同类型的流

```java
public void test06() {
    System.out.println(Arrays.toString(Stream.concat(Stream.of(1, 2, 3), Stream.of(4, 5, 6)).toArray()));
}
```

### Stream.empty

> 返回一个空流

## 中间操作

### distinct

> 对流进行去重操作, 调用Objects.equals比较

```java
public void test08() {
    System.out.println(Arrays.toString(Stream.of(1, 1, 2, 2).distinct().toArray()));
    String s1 = new String("s");
    String s2 = new String("s");
    System.out.println(Arrays.toString(Stream.of(s1, s2).distinct().toArray()));
}
```

## 结束操作

### allMath

> 按指定条件匹配所有元素
>
> 当所有条件都满足时返回true, 否则返回false
>
> 一个条件不满足就直接返回false

```java
public void test01() {
    boolean flag = Stream.of(1, 2, 3, 4, 5).allMatch(item -> {
        int r = (int) (Math.random() * 5);
        System.out.println(r);
        return item > r;
    });
    System.out.println(flag);
}
```

### anyMath

> 流中任意一个元素满足条件就返回true

### noneMath

> 流中所有元素都不满足条件返回true

### collect

- collect(Collector<? super T,A,R> collector)

  - > 传入一个Collector对象, 指定生成的集合类型

  - ```java
    public void test05() {
        System.out.println(Stream.of(1, 2, 3, 4, 5, 6)
                           .collect(Collectors.toList()));
    }
    ```

- collect(Supplier<R> supplier, BiConsumer<R,? super T> accumulator, BiConsumer<R,R> combiner)

  - > 根据自己指定的容器, 收集结果

  - ```java
    List<String> asList = stringStream.collect(ArrayList::new, ArrayList::add,
                                               ArrayList::addAll);
    ```

    ```java
    String concat = stringStream.collect(StringBuilder::new, StringBuilder::append,
                                         StringBuilder::append).toString();
    ```

### count

> 返回流中元素的个数

```java
public void test07() {
    System.out.println(Stream.iterate(0, item -> item++).limit(100).count());
}
```



# Collectors