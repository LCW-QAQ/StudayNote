# Prototype

> 原型模式经常用于Clone, 继承链的概念

```java
public class Person implements Cloneable{
    String name;
    int age;
    Address address;

    public Person(String name, int age, Address address) {
        this.name = name;
        this.age = age;
        this.address = address;
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        Person person = (Person) super.clone();
        person.address = (Address) this.address.clone();
        return person;
    }

    @Override
    public String toString() {
        return "Person{" +
                "name='" + name + '\'' +
                ", age=" + age +
                ", address=" + address +
                '}';
    }
}
```

```java
public class Address implements Cloneable{
    String loc;
    int roomNum;

    public Address(String address, int roomNum) {
        this.loc = address;
        this.roomNum = roomNum;
    }

    @Override
    protected Object clone() throws CloneNotSupportedException {
        Address address = (Address) super.clone();
        return address;
    }

    @Override
    public String toString() {
        return "Address{" +
                "loc='" + loc + '\'' +
                ", roomNum=" + roomNum +
                '}';
    }
}
```

```java
public class Main {
    public static void main(String[] args) {
        Person p1 = new Person("lcw", 16, new Address("wuhan", 1));
        try {
            Person p2 = (Person) p1.clone();
            System.out.println(p1 == p2);
            System.out.println(p1.address == p2.address);
            System.out.println(p1);
        } catch (CloneNotSupportedException e) {
            e.printStackTrace();
        }

    }
}
```

