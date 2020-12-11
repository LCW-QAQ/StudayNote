# ASM

> Java字节码操作框架
>
> Jdk和cglib动态代理底层都使用了ASM

## ASM访问class的方式

```java
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.FieldVisitor;
import org.objectweb.asm.MethodVisitor;

import java.io.IOException;

import static org.objectweb.asm.Opcodes.ASM4;

public class ClassPrinter extends ClassVisitor {

    public ClassPrinter() {
        //这里传参是指使用按个版本的API
        super(ASM4);
    }

    //访问class文件的头结构
    @Override
    public void visit(int version, int access, String name, String signature, String superName, String[] interfaces) {
        System.out.println("class "+name+" extends "+superName+"{");
    }

    //访问属性结构
    @Override
    public FieldVisitor visitField(int access, String name, String descriptor, String signature, Object value) {
        System.out.println("\t"+access+" "+name);
        return null;
    }

    //访问方法结构
    @Override
    public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
        System.out.println("\t"+name+"()");
        return null;
    }

	//类结束
    @Override
    public void visitEnd() {
        System.out.println("}");
    }

    public static void main(String[] args) throws IOException {
        ClassPrinter cp = new ClassPrinter();
        //通过ClassReader读取类
        ClassReader cr = new ClassReader("java.lang.Runnable");
        //调用accept方法(ClassVisitor cp, int parsingOptions)
        /*parsingOptions the options to use to parse this class.
        One or more of {@link#SKIP_CODE},
        			   {@link #SKIP_DEBUG},
        			   {@link #SKIP_FRAMES} or {@link #EXPAND_FRAMES}.
   		*/
        cr.accept(cp, 0);
    }
}
```

## ASM创建class

```java
public class MyClassLoader extends ClassLoader{
    public Class defineClass(String name, byte[] b){
        return defineClass(name,b,0,b.length);
    }
}
```

```java
import org.objectweb.asm.ClassWriter;

import static org.objectweb.asm.Opcodes.*;

public class ClassCreator {
    public static void main(String[] args) {
        ClassWriter cw = new ClassWriter(0);
        cw.visit(V1_5, ACC_PUBLIC + ACC_ABSTRACT + ACC_INTERFACE,
                "pkg/Comparable", null, "java/lang/Object",
                null);
        cw.visitField(ACC_PUBLIC + ACC_FINAL + ACC_STATIC, "LESS", "I",
                null, -1).visitEnd();
        cw.visitField(ACC_PUBLIC + ACC_FINAL + ACC_STATIC, "EQUAL", "I",
                null, 0).visitEnd();
        cw.visitField(ACC_PUBLIC + ACC_FINAL + ACC_STATIC, "GREATER", "I",
                null, 1).visitEnd();
        cw.visitMethod(ACC_PUBLIC + ACC_ABSTRACT, "compareTo",
                "(Ljava/lang/Object;)I", null, null).visitEnd();
        cw.visitEnd();
        byte[] b = cw.toByteArray();
        MyClassLoader myClassLoader = new MyClassLoader();
        Class clazz = myClassLoader.defineClass("pkg.Comparable", b);
        System.out.println(clazz.getMethods()[0]);
    }
}
```

## ASM动态更改class结构

> 模拟动态代理, 运行时生成class对象

```java
public class TimeProxy {
    public static void before(){
        System.out.println("before...");
    }
}
```

```java
public class Tank {
    public void move(){
        System.out.println("Tank move...");
    }
}
```

```java
import org.objectweb.asm.*;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.reflect.InvocationTargetException;

import static org.objectweb.asm.Opcodes.*;

public class ClassTransformerTest {
    public static void main(String[] args) throws IOException, NoSuchMethodException, IllegalAccessException, InvocationTargetException, InstantiationException {
        //读取Tank.classw文件
        ClassReader cr =
            				//加载Tank.class类的InputStream
            new ClassReader(ClassPrinter.class.getClassLoader().getResourceAsStream("com\\lcw\\ASM\\Tank.class"));
        //创建默认的ClassWriter
        ClassWriter cw = new ClassWriter(0);
        //创建自己的ClassVisitor, 在ClassVisitor中实现更改Tank.class源码, 生成新的class
        //visit后的结果传入cw
        ClassVisitor cv = new ClassVisitor(ASM4, cw){
	            @Override
                public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
                //创建访问方法的MethodVisitor对象访问当前方法
                MethodVisitor mv = super.visitMethod(access, name, descriptor, signature, exceptions);        
                //传入mv访问这个方法
                return new MethodVisitor(ASM4, mv) {
                    //访问方法中的代码, 在这里面更改代码
                    @Override
                    public void visitCode() {
                        //匹配move方法
                        if ("move".equals(name)) {
                            //新增一个静态调用的汇编
                            //visitMethodInsn(汇编指令, 类名, 方法, 参数以及返回值, 是否是接口)
                            visitMethodInsn(INVOKESTATIC, "TimeProxy", "before", "()V", false);
                        }
                        super.visitCode();
                    }
                };
            }
        };
        cr.accept(cv, 0);
        byte[] b = cw.toByteArray();
        //获取项目路径
        String path = (String) System.getProperties().get("user.dir");
        File file = new File(path+"\\com\\lcw\\ASM");
        file.mkdirs();

        //将生成的class写入到本地
        FileOutputStream fos = new FileOutputStream(new File(path + "\\com\\lcw\\ASM\\Tank_0.class"));
        fos.write(b);
        fos.flush();
        fos.close();

    }
}
```

### 生成的class

```java
package com.lcw.ASM;

public class Tank {
    public Tank() {
    }

    public void move() {
        TimeProxy.before();
        System.out.println("Tank move...");
    }
}
```