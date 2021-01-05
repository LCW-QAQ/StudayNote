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

### Stream.ofNullable

> Stream.of中如果只存一个null, 会NullPointerException
>
> Stream.ofNullable中只存一个null, 不会NullPointerException, 而是会返回一个empty流

```java
public void test31() {
    try {
        System.out.println(Stream.of(null).count());// Exception
    } catch (Exception e) {
        e.printStackTrace();
    }
    System.out.println(Stream.ofNullable(null).count());
}
```

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

### takeWhile

> 如果是有序流, 则顺序获取一个满足条件的元素, 非顺序流随机获取一个满足条件的元素, 不建议在并行流中使用, 性能极低

```java
public void test30() {
    Stream.of(2, 1, 3, 4, 2, 2, 2, 2, 312, 11, 0, 0)
        .takeWhile(item -> item == 2).forEach(item -> System.out.println(item + " "));
}
```

### dropWhile

>如果是有序流, 则顺序删除一个满足条件的元素, 非顺序流随机删除一个满足条件的元素, 不建议在并行流中使用, 性能极低

```java
public void test29() {
    Stream.of(2, 1, 3, 4, 2, 2, 2, 2, 312, 11, 0, 0)
        .dropWhile(item -> item == 2).forEach(item -> System.out.print(item + " "));
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
>
> reduce, 三个参数的重载, 只对并行流有影响, 后面两个二元运算函数, 必须兼容

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
                        // fork1 和 fork2 代表 并行流的两个子任务(并行流使用了ForkJion)
                    }, (fork1, fork2) -> {
                        return null;
                    }));
}
```

# Collectors

> 该类就是为了收集流中的元素而诞生的
>
> Collectors提供了丰富的收集器, 可以按不同要求收集结果

### toCollection

> 将指定集合转换为收集器

```java
public void test19() {
    TreeSet<Integer> treeSet = Stream.of(1, 2, 3, 4)
            .collect(Collectors.toCollection(TreeSet::new));
    treeSet.forEach(item -> System.out.print(item + " "));
}
```

### toList

> 将流中元素包装成一个List

### toSet

> 将流中元素包装成一个Set

### toMap

> 将流中元素包装成一个Map
>
> 需要映射key和value
>
> 可以在遍历过程中, 执行二元运算函数
>
> 也可以指定Map收集

```java
public void test20() {
    Map<Integer, Integer> map = Stream.of(1, 2, 3, 4, 5)
        .collect(Collectors.toMap(item -> item + 1, item -> item));
    System.out.println(map);

    Map<String, String> map1 = Stream.of(1, 2, 3, 4, 5)
        .map(String::valueOf)
        .collect(Collectors.toMap(item -> item + "-key", item -> item + "-value", (a, b) -> {
            a = a.concat("-a");
            b = b.concat("-b");
            return null;
        }));
    System.out.println(map1);

    Map<String, String> map2 = Stream.of(1, 2, 3, 4, 5)
        .map(String::valueOf)
        .collect(Collectors.toMap(item -> item + "-key", item -> item + "-value",
                                  (a, b) -> {
                                      a = a.concat("-a");
                                      b = b.concat("-b");
                                      return null;
                                  }, ConcurrentHashMap::new));

    System.out.println(map2);
}
```

### toConcurrentMap

> 将流中元素包装成一个线程安全的Map, 调用toMap方法, 指定线程安全的Map, 可以达到同样的效果

### toUnmodifiableList

> 将流中元素包装成一个不可修改的List

### toUnmodifiableSet

> 将流中元素包装成一个不可修改的Set

### toUnmodifiableMap

> 将流中元素包装成一个不可修改的Map

### averagingDouble

> 遍历流中的数据, 每次返回一个Double值, 最后计算出平均值

```java
public void test01() {
    System.out.println(Stream.of(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
                       .collect(Collectors.averagingDouble(Double::valueOf)));
}
```

### averagingInt

### averagingLong

### summingInt

> 映射流中每个元素返回一个Int, 将所有int汇总

```java
public void test17() {
    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.summingInt(item -> item + 10)));
}
```

### summingDouble

### summingLong

### summarizingInt

> 映射流中每个元素返回一个int, 返回一个包含 数量, 总和, 最小值, 最大值, 平均值

```java
public void test18() {
    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.summarizingInt(item -> item + 10)));
}
```

### summarizingDouble

### summarizingLong

### collectingAndThen

> 用给定容器收集元素, 收集完成后, 执行一个操作, 返回结果

```java
public void test02() {
    Stream.of(1, 2, 3, 4, 1, 5, 6)
        .collect(Collectors.collectingAndThen(
            Collectors.toCollection(ArrayList::new),
            (list) -> {
                list.add(999);
                return list;
            }
        )).forEach(item -> System.out.print(item + " "));
}
```

### counting

> 返回集合中元素的数量

```java
public void test03() {
    System.out.println(Stream.of(1, 2, 3, 4, "1").collect(Collectors.counting()));
}
```

### filtering

> 只有满足条件的元素, 才会被用指定容器收集

```java
public void test04() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
                                       .collect(Collectors.filtering(item -> item > 2, Collectors.toCollection(ArrayList::new))).toArray()));
}
```

### flatMapping

> 遍历流, 将每个元素转换成流, 最后用指定收集器收集元素

```java
public void test05() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
		.collect(Collectors.flatMapping(item -> Stream.of(++item),
			Collectors.toCollection(ArrayList::new))).toArray()));
}
```

### mapping

> 遍历流, 对每个元素进行操作, 返回操作后的结果, 用指定容器收集起来

```java
public void test06() {
    System.out.println(Arrays.toString(Stream.of(1, 2, 3, 4, 5)
            .collect(Collectors.mapping(item -> ++item, Collectors.toCollection(ArrayList::new)))
            .toArray()));
}
```

### groupingBy

> 遍历流, 根据每次遍历的结果分组

- groupingBy(Fuction<? super T,? extends K> classifier)

  - ```java
    public void test07() {
        Map<String, List<Integer>> map = Stream.of(1, 2, 3, 4, 5)
                .collect(Collectors.groupingBy(item -> {
                    if (item < 3) {
                        return "第一组";
                    } else {
                        return "第二组";
                    }
                }));
    
        System.out.println(map);
    }
    ```

- groupingBy(Function<? super T,? extends K> classifier, Collector<? super T,A,D> downstream)

  - > 使用收集器分组

  - ```java
    public void test08() {
        Map<String, List<Integer>> map = Stream.of(1, 2, 3, 4, 5)
            .collect(Collectors.groupingBy(item -> {
                if (item < 3) {
                    return "第一组";
                } else {
                    return "第二组";
                }
            }, Collectors.toCollection(Vector::new)));
    
        System.out.println(map);
    }
    ```

- groupingBy(Function<? super T,? extends K> classifier, Suppiler\<M\> mapFactory, Collector<? super T,A,D> downstream)

  - > 使用指定map映射, 指定收集器

  - ```java
    public void test09() {
        Map<String, List<Integer>> map = Stream.of(1, 2, 3, 4, 5)
            .collect(Collectors.groupingBy(item -> {
                if (item < 3) {
                    return "第一组";
                } else {
                    return "第二组";
                }
            }, ConcurrentHashMap::new,Collectors.toCollection(Vector::new)));
    
        System.out.println(map);
    }
    ```

### groupingByConcurrent

> 同上, 也是分组, 返回线程安全map, 调用groupingBy方法传入线程安全的集合, 效果是一样的, 这个方法更加语义化

### joining

> 将字符序列流, 连接, 返回一个字符序列

- joining()

  - > 直接连接字符序列流

  - ```java
    public void test11() {
        System.out.println(Stream.of(1, 2, 3, 4)
                           .map(String::valueOf)
                           .collect(Collectors.joining()));
    }
    ```

- joining(CharSequence delimiter)

  - > 用指定字符序列, 连接流中元素

  - ```java
    public void test11() {
        System.out.println(Stream.of(1, 2, 3, 4)
                           .map(String::valueOf)
                           .collect(Collectors.joining("-")));
    }
    ```

- joining(CharSequence delimiter, CharSequence prefix, CharSequence suffix)

  - > 用指定字符序列, 连接流中元素, 给结果加上一个前缀和后缀

  - ```java
    public void test12() {
        System.out.println(Stream.of(1, 2, 3, 4, 5)
                           .map(String::valueOf)
                           .collect(Collectors.joining(", ", "[", "]")));
    }
    ```

### maxBy

> 按照指定比较器, 比较元素, 返回最大值

```java
public void test13() {
    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.maxBy(Comparator.naturalOrder())).get());
}
```

### minBy

### partitioningBy

- partitioningBy(Predicate<? super T> predicate)

  - > 根据true, false, 分区, 就是只有固定两组的groupingBy

  - ```java
    public void test14() {
        Map<Boolean, List<Integer>> map = Stream.of(1, 2, 3, 4, 5)
            .collect(Collectors.partitioningBy(item -> item < 3));
        System.out.println(map);
    }
    ```

- partitioningBy(predicate<? super T> predicate, Collector<?  super T,A,D>  downstream)

  - > 根据true, false分区, 使用指定收集器收集

  - ```java
    public void test15() {
        Map<Boolean, Stack<Integer>> map = Stream.of(1, 2, 3, 4, 5)
            .collect(Collectors.partitioningBy(item -> item < 3, Collectors.toCollection(Stack::new)));
        System.out.println(map);
    }
    ```

### reducing

> 汇聚操作, 与reduce类似

```java
public void test16() {
    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.reducing(Integer::sum)).get());

    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.reducing(10, Integer::sum)));

    System.out.println(Stream.of(1, 2, 3, 4, 5)
                       .collect(Collectors.reducing( 0, item -> ++item, (a, b) -> a + b)));;
}
```

# Other Stream

## BaseStream

### close

> 关闭流

### isParallel

> 判断是否是并行流

### iterator

> 返回当前流的迭代器

```java
public void test01() {
    Iterator<Integer> it = Stream.of(1, 2, 3, 4, 5).iterator();
    while(it.hasNext()) {
        int cur = it.next();
        if(cur != 4) {
            System.out.print(cur + " ");
        }
    }
}
```

### onClose

> 在流关闭时被调用(手动关闭), 平常使用流都必须要关闭

### parallel

> 返回并行流

### sequential

> 返回一个有序流

### unordered

> 返回一个无序流

### spliterator

> 返回一个可拆分的迭代器, JDK8中出现的新接口, 为了实现多线程计算, 充分利用多线程提高性能

## DoubleStream

### average

> 返回流中所有元素的平均值

### max

> 返回流中的最大值

### min

> 返回流中的最小值

### sum

> 返回流中元素的总和

### summaryStatistics

> 返回流中的总计摘要, (数量, 总和, 最小值, 最大值, 平均值)

### mapToObj

> 将流中元素映射成其他Obj类型

### boxed

> 将流转换成T类型的 Stream 流

```java
public void test07() {
    DoubleStream.of(1, 2, 3, 4, 5)
        .boxed().forEach(item -> System.out.print(item + " "));
}
```

## IntStream

## LongStream

## ParallelStream

# ParallelStream

# [先挖一个坑, 以后再填.....]()



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