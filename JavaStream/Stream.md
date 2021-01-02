# Java Stream

## 常用的Stream创建

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

## 