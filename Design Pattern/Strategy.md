# Stategy

- 策略模式其实就是将一种行为或者算法, 封装起来, 要使用时就可以直接使用封装好的类(策略)

```java
public class Animal {
    public int weight;
}
/*--------------------------------------*/
public class Cat extends Animal{
    public Cat(int weight) {
        this.weight = weight;
    }

    @Override
    public String toString() {
        return "Cat{" +
                "weight=" + weight +
                '}';
    }
}
/*--------------------------------------*/
public class Dog extends Animal{
    public int weight;

    public int foodWeight;

    public Dog(int weight, int foodWeight) {
        this.weight = weight;
        this.foodWeight = foodWeight;
    }

    @Override
    public String toString() {
        return "Dog{" +
                "weight=" + weight +
                ", foodWeight=" + foodWeight +
                '}';
    }
}
```

## Animal实现Comparable接口

> 如果现在要给Animal排序, 那么可以让Animal或子类实现Comparable接口, 后进行排序

```java
public class Animal implements Comparable<Animal>{
    public int weight;
    
    @Override
    public int comparaTo(Animal animal){
        return this.weight-animal.weight;
    }
}
```

```java
//用于排序的泛型Sorter
public class Sorter<T> {
    public void sort(Comparable[] arr){
        for (int i = 0; i < arr.length; i++) {
            for (int j = arr.length-1; j > i; j--) {
                if(arr[j].comparaTo(arr[j-1]) < 0){
                    T temp = arr[j];
                    arr[j] = arr[j-1];
                    arr[j-1] = temp;
                }
            }
        }
    }
}
```

## Comparator接口实现类(Strategy)

> 该接口其实就是一个Strategy模式
>
> 可以灵活创建Comparable的实现类, 来自定义满足需求

```java
public class DefaultAnimalSorter implements Comparator<Animal> {
    @Override
    public int compare(Animal o1, Animal o2) {
        return o1.weight-o2.weight;
    }
}
```

```java
public class Sorter<T> {
    public void sort(T[] arr, Comparator<T> comparator){
        for (int i = 0; i < arr.length; i++) {
            for (int j = arr.length-1; j > i; j--) {
                if(comparator.compare(arr[j], arr[j-1]) < 0){
                    T temp = arr[j];
                    arr[j] = arr[j-1];
                    arr[j-1] = temp;
                }
            }
        }
    }
}
```

```java
/*测试*/
public static void main(){
    	Sorter<Animal> catSorter = new Sorter<>();
        Cat[] cats = new Cat[]{new Cat(2), new Cat(1), new Cat(5)};
        catSorter.sort(cats, new DefaultAnimalSorter());
        System.out.println(Arrays.toString(cats));
}
```

> 每次排序时都需要new一个实例, 其实是不需要多个实例的, 可以将DefaultAnimalSorter设计成单例
>
> 这里使用枚举的方式

```java
public enum DefaultAnimalSorter implements Comparator<Animal> {
    DEFAULT_ANIMAL_SORTER;
    @Override
    public int compare(Animal o1, Animal o2) {
        return o1.weight-o2.weight;
    }
}
```

```java
/*测试*/
public static void main(){
    Sorter<Animal> catSorter = new Sorter<>();
        Cat[] cats = new Cat[]{new Cat(2), new Cat(1), new Cat(5)};
        catSorter.sort(cats, DefaultAnimalSorter.DEFAULT_ANIMAL_SORTER);
        System.out.println(Arrays.toString(cats));
}
```

