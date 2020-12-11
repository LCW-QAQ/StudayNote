# Builder

> 构建器模式常用在, 复杂类的创建中, 一个类的结构比较复杂, 有些参数需要设置, 有些又可以不用设置, 重写多个构造方法就显得很臃肿
>
> 这时可以使用构建器去创建对象, 根据构建器的方法, 构建对象的属性

```java
public class Person {
    private Integer id;
    private String name;
    private Integer age;
    private String loc;
    private String birth;
    private Integer roomNum;

    private Person(){}

    public static class PersonBuilder{
        Person p = new Person();

        public PersonBuilder basicInfo(int id, String name, int age){
            p.id = id;
            p.name = name;
            p.age = age;
            return this;
        }

        public PersonBuilder location(String loc){
            p.loc = loc;
            return this;
        }

        public PersonBuilder birth(String birth){
            p.birth = birth;
            return this;
        }

        public PersonBuilder roomNum(int roomNUm){
            p.roomNum = roomNUm;
            return this;
        }

        public Person build(){
            return p;
        }

    }

    @Override
    public String toString() {
        return "Person{" +
                "id=" + id +
                ", name='" + name + '\'' +
                ", age=" + age +
                ", loc='" + loc + '\'' +
                ", birth='" + birth + '\'' +
                ", roomNum=" + roomNum +
                '}';
    }
}

```

```java
public class Main {
    public static void main(String[] args) {
        //根据需求构建对象
        Person p = new Person.PersonBuilder().basicInfo(1, "xiaozhang", 17)
//                .birth("2020/010/21")
                .location("HuBei")
//                .roomNum(1)
                .build();
        System.out.println(p);
    }
}
```

