# MybatisPlusFieldAutoFilled

```java
@Component
public class MybatisPlusMetaObjectHandler implements MetaObjectHandler {

    private static final String CREATE_DATE_FILED_NAME = "createDate";

    private static final String UPDATE_DATE_FILED_NAME = "modifyDate";

    @Override
    public void insertFill(MetaObject metaObject) {
        if (metaObject.hasGetter(CREATE_DATE_FILED_NAME)) {
            setFieldValByName(CREATE_DATE_FILED_NAME, new Date(), metaObject);
        }
        if (metaObject.hasGetter(UPDATE_DATE_FILED_NAME)) {
            setFieldValByName(UPDATE_DATE_FILED_NAME, new Date(), metaObject);
        }
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        if (metaObject.hasGetter(UPDATE_DATE_FILED_NAME)) {
            setFieldValByName(UPDATE_DATE_FILED_NAME, new Date(), metaObject);
        }
    }
}
```

```java
// 使用样例
public class Person {
    @TableField(fill = FieldFill.INSERT)
    private Date createDate;
}
```

