# CPP 程序 对象内存模型

- **非静态成员变量总合**。
- **加上编译器为了CPU计算，作出的数据对齐处理。**
- **加上为了支持虚函数，产生的额外负担。**

总结：

空的类是会占用内存空间的，而且大小是1，原因是C++要求每个实例在内存中都有独一无二的地址。

（一）类内部的成员变量：

- 普通的变量：是要占用内存的，但是要注意对齐原则（这点和struct类型很相似）。
- static修饰的静态变量：不占用内容，原因是编译器将其放在全局变量区。

（二）类内部的成员函数：

- 普通函数：不占用内存。
- 虚函数：要占用4个以上字节，用来指定虚函数的虚拟函数表的入口地址。所以一个类的虚函数所占用的地址是不变的，和虚函数的个数是没有关系的。

```cpp
#include <iostream>

using namespace std;

class BaseClass {};

void demo1() {
    BaseClass bc;
    cout << sizeof(bc) << endl;// 1
}

class BaseClass2 {
    int a;// int 占用4个字节
    int b;
};


void demo2() {
    BaseClass2 bc;
    cout << sizeof (bc) << endl;// 8 : 两个int占用4个字节
}

class BaseClass3 {
    int a;
    int b;
    static int c;
};

void demo3() {
    BaseClass3 bc;
    cout << sizeof (bc) << endl;// 8 : 输出结果还是8, 因为静态字段不属于实例类
}

class BaseClass4 {
    int a;
    int b;
    static int c;
    char d;
};

void demo4() {
    BaseClass4 bc;
    // 12 : 两个int占用8字节, static忽略, char类型占用1字节, 但是编译进行了数据对齐优化, 所以这个char占用4字节
    cout << sizeof(bc) << endl;
}

// 数据对齐是编译器为了方便CPU执行, 进行的优化, 默认情况下, 类或结构体的对齐值是按照占用最大的变量来对齐
// 数据对齐Demo
class A {
    // 该类占用最大的字段是int a, 所以按照int 4byte 对齐
    int a;
    char b;// char只占用一个字节，补齐3个字节
};

void testA() {
    A a;
    cout << sizeof a << endl;// 占用8byte
}

class B {
    // 该类占用最大字段是b 8byte, 故按照8byte对齐
    int a;// 补齐4个字节
    double b;
    char c;// 补齐7个字节
};

void testB() {
    B b;
    cout << sizeof b << endl;
}

// 上面的例子一共占用了24个字节，但是可以优化
class B_O {
    char c;// 补齐3个字节, 和后的int组成8个字节对齐
    int a;
    double b;
};

void testB_O() {
    B_O bo;
    cout << sizeof bo << endl;// 16 : 经过优化, 这个类就只占用了16个字节
}

// 发现可用将较小的字段放在前面，让他们组成一个对齐位，这个就可以节省内存了

class B_O2 {
    char c;// 补齐3个字节, 和后的int组成8个字节对齐
    char chs[3];
    int a;
    double b;
};

void testB_O2() {
    B_O2 bo;
    cout << sizeof bo << endl;// 16 : 与B_O占用同样的空间，但是却多给出了一个chs字段
}

// 编译器对类进行对齐时，分配的空间对我们来说是隐式的，我们也无法操控对齐的空间
// 因此可以考虑可以分配空间，做好对齐优化，这样可以充分利用空间

class C {
    // 编译器是根据数据类型的最大占用，来确定对齐值，所以这里没有按照数据的40字节来对齐
    int a;
    int arr[10];// 占用40个字节
    char c;// 补齐三个字节
};

void testC() {
    C c;
    cout << sizeof c << endl;
}

// 下面来演示一下复杂类型的对齐

class A_F {
    char a;// 占用一个字节,补齐3字节
    int b;// 和char a补齐8字节
    double arr[3];// 24字节
};

class B_S {
    char c;// 4
    A_F af;// 32
    int a;// 4
};

void testAB() {
    A_F af;
    B_S bs;
    cout << sizeof af << endl;// 32byte
    cout << sizeof bs << endl;// 48byte : 说明不是按照A_F占用的字节来对齐，猜测？ 可能是按照A_F的对齐值来对齐
}

class A_F2 {
    char a;
    int b;
    int arr[3];// 12byte
};

class B_S2 {
    char c;// 4
    A_F2 af;// 20byte
    int a;// 4
};

void testAB2() {
    A_F2 af;
    B_S2 bs;
    cout << sizeof af << endl;
    cout << sizeof bs << endl;// 28 : 简单验证了之前的猜想,在复杂对象对齐时是按照复杂类型的对齐值来对齐
}

// 在复杂对象对齐时是按照复杂类型的对齐值来对齐

class FunctionObj {
public:
    FunctionObj(){}
    ~FunctionObj(){}
    void show();
};

void testFuncObj() {
    FunctionObj fo;
    cout << sizeof fo << endl;// 1byte : 这占用1byte, 因为非虚函数是不会占用对象空间的
}

class VirObj {
public:
    VirObj(){}
    ~VirObj(){}
    virtual void show(){};
};

void testVirObj() {
    VirObj vo;
    cout << sizeof vo << endl;// 4byte ：为了支持虚函数，多出来了指向virtual table的指针占用4个字节
}
//为了支持虚函数，多出来了指向virtual table的指针占用4个字节

class VirObjSon: VirObj {
public:
    VirObjSon(void){};
    ~VirObjSon(){};
    void show() override {
        cout << "show" << endl;
    };
private:
    int b;
};

void testVirObjSon() {
    VirObjSon vos;
    cout << sizeof vos << endl;// 8byte : 派生类和基类共享一个虚表指针
}

int main()
{
//    demo4();
    testVirObjSon();
    return 0;
}

```