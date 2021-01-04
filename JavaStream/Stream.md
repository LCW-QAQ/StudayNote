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

### Stream.generate

> 根据Suppiler生成一个无线无序流

```java
public void test16() {
    System.out.println(Arrays.toString(Stream.generate(Math::random).limit(10).toArray()));
}
```

### Stream.iterate

> 按照给定种子生成无限顺序流, 按照UnaryOperator计算, 下一个元素

```java
public void test17() {
    System.out.println(Arrays.toString(Stream.iterate(1, item -> ++item).limit(10).toArray()));
}
```

### Stream.of

> 将多参列表中元素构建成流

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

### filter

> 按条件过滤流, 条件为true保留, 反之丢弃

```java
public void test09() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5).filter(item -> item > 3).toArray()));
}
```

### flatMap

> 遍历流元素, 将每个元素转换成另一个不同或相同类型的流

```java
public void test12() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4).flatMap(new Function<Integer, Stream<?>>() {
        @Override
        public Stream<?> apply(Integer integer) {
            return Stream.of(integer + "$");
        }
    }).toArray()));
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4).flatMap(item -> Stream.of(item + "$")).toArray()));
}
```

### flatMapToDouble

> 遍历流中元素, 将每个元素转换为DoubleStream

```java
public void test13() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5, 6)
                                       .flatMapToDouble(new Function<Integer, DoubleStream>() {
                                           @Override
                                           public DoubleStream apply(Integer integer) {
                                               return DoubleStream.of(integer);
                                           }
                                       }).toArray()));

    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5, 6)
                                       .flatMapToDouble(DoubleStream::of).toArray()));
}
```

### flatMapToLong

### flatMapToInt

### map

> 遍历每个元素, 返回一个不同或相同类型的结果

```java
public void test19() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
                                       .map(new Function<Integer, String>() {
                                           @Override
                                           public String apply(Integer integer) {
                                               return integer.toString() + "$";
                                           }
                                       }).toArray()));

    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
                                       .map(integer -> integer.toString() + "$").toArray()));
}
```

### mapToDouble

> 遍历每个元素, 返回Double类型的结果

```java
public void test20() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
                                       .mapToDouble(item -> 1.0 + item)
                                       .toArray()));
}
```

### mapToLong

### mapToInt

### limit

> 截取流中元素

```java
public void test18() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4).limit(2).toArray()));
}
```

### skip

> 跳过流中n个元素

```java
public void test23() {
    System.out.println(Arrays.toString(Stream.of(9, 1, 2, 7, 3, 4).skip(1).toArray()));
}
```

### sorted

> 排序流中的元素, 元素必须实现Comparable接口, 或者指定Comparator

```java
public void test24() {
    System.out.println(Arrays.toString(Stream.of(2, 1, 4, 1, 2).sorted().toArray()));
    System.out.println(Arrays.toString(Stream.of(2, 1, 4, 1, 2).sorted(Comparator.reverseOrder()).toArray()));
}
```

### peek

> 遍历每个元素, 类似forEach, 但是不是终结操作

```java
public void test26() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4).peek(System.out::println).toArray()));
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

### toArray

> 将流转换为数组, 可以对每个元素转换时进行精准控制 

```java
public void test25() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5).toArray()));
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5).toArray(item -> new Integer[]{item+1})));
}
```

### count

> 返回流中元素的个数

```java
public void test07() {
    System.out.println(Stream.iterate(0, item -> item++).limit(100).count());
}
```

### findAny

> 随机获取流中的元素, 常用于并行操作 
>
> 底层还是按一定算法(规则), 获取元素的

```java
public void test10() {
    Thread[] threads = {new Thread("t1"), new Thread("t2"), new Thread("t3")};
    System.out.println(Stream.of(threads)
                       .parallel()
                       .findAny().get().getName());
    System.out.println(Stream.of(threads)
                       .parallel()
                       .findAny().get().getName());
}
```

### findFirst

> 获取流中第一个元素

```java
public void test11() {
    System.out.println(Stream.of(10, 2, 3).findFirst().get());
}
```

### forEach

> 遍历流中的元素
>
> forEach是并行的, 在并行流中, 不一定会顺序遍历元素

```java
public void test14() {
    Stream.of(1,2,3,4).forEach(item -> System.out.print(item + " "));
}
```

### forEachOrdered

> 按顺序遍历流中元素
>
> forEach是强制串行遍历, 在并行流中也会按顺序输出

```java
public void test15() {
    Stream.of(4,3,2,1).parallel().forEach(item -> System.out.print(item + " "));
    System.out.println();
    Stream.of(4,3,2,1).parallel().forEachOrdered(item -> System.out.print(item + " "));
}
```

### max

> 按照指定比较器, 返回流中最大值

```java
public void test21() {
    System.out.println(Stream.of(1, 2, 3, 4).max(Comparator.naturalOrder()).get());
    System.out.println(Stream.of(1, 2, 3, 4).max(Comparator.reverseOrder()).get());
    System.out.println(Stream.of(1, 2, 3, 4).max(Integer::compare).get());
}
```

### min

> 按照指定比较器, 返回流中最小值

```java
public void test22() {
    System.out.println(Stream.of(1, 2, 3, 4).min(Comparator.naturalOrder()).get());
    System.out.println(Stream.of(1, 2, 3, 4).min(Comparator.reverseOrder()).get());
    System.out.println(Stream.of(1, 2, 3, 4).min(Integer::compare).get());
}
```

### reduce

> 汇聚操作, 遍历流中的元素, 结果作为下一个元素的参数
>
> 可以指定初始值, 在初始值上进行操作

```java
public void test27() {
    System.out.println(Stream.of(1, 2, 3, 4, 5)
            .reduce((a, b) -> a + b).get());

    System.out.println(Stream.of(1, 2, 3, 4, 5)
            .reduce(100, (a, b) -> a + b));

    System.out.println(Stream.of(2, 3, 4)
            .reduce(new ArrayList<>(),
                    (list, item) -> {
                        list.add(item);
                        return list;
                    }, (list1, list2) -> {
                        return null;
                    }));
}
```

# Collectors





---


# Question

## 有关流反转集合的操作

```java
public class StreamReverseDemo {

    // 反转排序, 性能低
    @Test
    public void test01() {
        Object[] arr = Stream.iterate(1, item -> ++item)
                .limit(10000000)
                .sorted(Comparator.reverseOrder())
                .toArray();

        Arrays.stream(arr).limit(10).forEach(System.out::println);
    }

    // 如果排序的是 连续 有序 可计算 序列, 可以优化算法, 不需要排序, 只需要计算, 性能更高
    @Test
    public void test2() {
        int start = 1, end = 10000001;
        int[] arr = IntStream.range(start, end)
                .map(item -> end - item + start - 1).toArray();

        Arrays.stream(arr).limit(10).forEach(System.out::println);
    }

    // 适合现存的有序集合或数组反转
    @Test
    public void test3() {
        int[] arr = IntStream.range(1, 10000001).toArray();
        Object[] reverseArr = IntStream.range(0, arr.length)
                .mapToObj(index -> arr[arr.length - index - 1]).toArray();
        Arrays.stream(reverseArr).limit(10).forEach(System.out::println);
    }

    // 适合于任何情况的反转方法, 但是因为使用的是ArrayList, 在数量级大的时候, 会出现大量扩容, 性能极低
    @Test
    public void test4() {
        ArrayList<Object> arr = IntStream.range(1, 10000001)
                .collect(ArrayList::new,
                        (list, item) -> list.add(0, item),
                        (l1, l2) -> l1.addAll(0, l2));
        arr.stream().limit(10).forEach(System.out::println);
    }

    // 适合任何情况反转, 使用双向链表可以再方便的在head添加元素
    @Test
    public void test05() {
        long time = System.currentTimeMillis();
        LinkedList<Object> arr = IntStream.range(1, 10000001)
                .collect(LinkedList::new,
                        (linked, item) -> linked.add(0, item),
                        (l1, l2) -> l1.add(0, l2));
        System.out.println(System.currentTimeMillis() - time);
        arr.stream().limit(10).forEach(System.out::println);
    }

    // 适合任何情况反转, 使用数组实现的 双端队列 实现, (这个案例中)平均性能比双向链表高
    @Test
    public void test06() {
        long time = System.currentTimeMillis();
        ArrayDeque<Object> deque = IntStream.range(1, 10000001)
                .collect(ArrayDeque::new,
                        ArrayDeque::offerFirst,
                        ArrayDeque::offer);
        System.out.println(System.currentTimeMillis() - time);
        deque.stream().limit(10).forEach(System.out::println);
    }
}
```