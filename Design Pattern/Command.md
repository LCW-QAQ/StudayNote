# Command

> 命令模式用来做undo, 事务, 宏命令, Command就是定义一个Action
>
> 现在模拟一个编辑器的插入, 删除操作

## 定义Command及其子类

```java
public abstract class Command {
    abstract void doit();
    abstract void undo();
}
```

```java
public abstract class TextCommand extends Command{
    protected Content content;

    protected String str;
}
```

```java
public class InsertCommand extends TextCommand{

    public InsertCommand(Content content) {
        this.content = content;
    }

    public InsertCommand(Content content, String str) {
        this(content);
        this.str = str;
    }

    @Override
    void doit() {
        content.text = content.text.concat(str);
    }

    @Override
    void undo() {
        content.text = content.text.substring(0, content.text.length()-str.length());
    }
}
```

```java
public class BackspaceTextCommand extends TextCommand{
    protected Character backChar;

    public BackspaceTextCommand(Content content, String str) {
        this(content);
        this.str = str;
    }

    public BackspaceTextCommand(Content content) {
        this.content = content;
    }

    @Override
    void doit() {
        backChar = content.text.charAt(content.text.length()-1);
        content.text = content.text.substring(0, content.text.length()-1);
    }

    @Override
    void undo() {
        content.text = content.text.concat(String.valueOf(backChar));
    }
}
```

## 定义Content

```java
public class Content {
    protected String text;

    public Content() {
    }

    public Content(String text) {
        this.text = text;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    @Override
    public String toString() {
        return text;
    }
}
```

## 定义命令责任链

```java
public class CommandChain extends Command {

    private List<Command> list = new ArrayList<>();
    private int index;
    private Content content;

    public CommandChain() {
    }

    public CommandChain add(Command command){
        list.add(command);
        return this;
    }

    public void doCommand() {
        for (Command command : list) {
            command.doit();
            index++;
        }
    }

    public void undoCommand(){
        list.stream().collect(ArrayList::new,
                (listOne, e) -> listOne.add(0, e),
                (listOne, listTwo) -> listOne.add(0, listTwo)).forEach(c -> ((Command)c).undo());
    }

    @Override
    void doit() {
        doCommand();
    }

    @Override
    void undo() {
        undoCommand();
    }
}
```

## 测试

```java
public class TestChain {
    public static void main(String[] args) {
        Content content = new Content("1,2,3,4");
        CommandChain chainOne = new CommandChain().add(new InsertCommand(content, "Insert Content One"))
                .add(new BackspaceTextCommand(content))
                .add(new InsertCommand(content, "Insert Content Two"));
//
//        chainOne.doCommand();
//        System.out.println(content);

        CommandChain chainTwo = new CommandChain().add(new InsertCommand(content, "????"))
                .add(new BackspaceTextCommand(content));

        chainTwo.doCommand();
        System.out.println(content);
        chainTwo.undo();
        System.out.println(content);

    }
}
```

