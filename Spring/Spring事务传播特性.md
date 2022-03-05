# Spring事务传播特性

| 传播行为      | 意义                                                         |
| ------------- | ------------------------------------------------------------ |
| MANDATORY     | 表示该方法必须运行在一个事务中。如果当前没有事务正在发生，将抛出一个异常 |
| NESTED        | 表示如果当前正有一个事务在进行中，则该方法应当运行在一个嵌套式事务中。被嵌套的事务可以独立于封装事务进行提交或回滚。如果没有正在运行的事务，行为就像REQUIRES一样。 |
| NEVER         | 表示当前的方法不应该在一个事务中运行。如果一个事务正在进行，则会抛出一个异常。 |
| NOT_SUPPORTED | 表示该方法不应该在一个事务中运行。如果一个现有事务正在进行中，它将在该方法的运行期间被挂起。 |
| SUPPORTS      | 表示当前方法不需要事务性上下文，但是如果有一个事务已经在运行的话，它也可以在这个事务里运行。 |
| REQUIRES_NEW  | 表示当前方法必须在它自己的事务里运行。一个新的事务将被启动，而且如果有一个现有事务在运行的话，则将在这个方法运行期间被挂起。 |
| REQUIRES      | 表示当前方法必须在一个事务中运行。如果一个现有事务正在进行中，该方法将在那个事务中运行，否则就要开始一个新事务。 |

> 注意事务的传播是在多个事务且在不同Service之间的情况, 演示的时候记得使用多个事务且在不同Service中

单独解释一下NESTED, 事务嵌套

```java
@Controller
public class TxService {
    @Autowired
    SimpleDao simpleDao;

    @Autowired
    TxService2 txService2;

    // 这里开启一个事务
    @Transactional(rollbackFor = Exception.class, propagation = Propagation.REQUIRED)
    public void updateUser1() {
        simpleDao.updateUser1();
        System.out.println(TransactionSynchronizationManager.getCurrentTransactionName());
        try {
            // 调用txService2中的updateUser2, updateUser2的传播级别是NESTED
            // NESTED嵌套在当前事务中运行, 如果嵌套事务出错, 不会回滚当前事务, 但是当前出错会回滚嵌套事务
            // 理解为一个父子事务模型即可
            txService2.updateUser2();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

```java
@Service
public class TxService2 {

    @Autowired
    SimpleDao simpleDao;

    // 嵌套事务, 嵌套在当前事务中运行, 若没有事务则创建一个事务行为与REQUIRED相同
    @Transactional(rollbackFor = Exception.class, propagation = Propagation.NESTED)
    public void updateUser2() {
        simpleDao.updateUser2();
        System.out.println(TransactionSynchronizationManager.getCurrentTransactionName());
        int i = 1 / 0;
    }
}
```

