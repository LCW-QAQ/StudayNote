# Composite

> 组合模式, 用于处理树形结构的设计模式

```java
abstract class Node {
    abstract void printNode();
}

class LeafNode extends Node{

    private String value;

    public LeafNode(){}

    public LeafNode(String value) {
        this.value = value;
    }

    @Override
    void printNode() {
        System.out.println(value);
    }

    public String getValue() {
        return value;
    }

    public void setValue(String value) {
        this.value = value;
    }
}

class BranchNode extends Node{

    private String dirName;

    private List<Node> list = new ArrayList<>();

    public BranchNode() {
    }

    public BranchNode(String dirName) {
        this.dirName = dirName;
    }

    public String getDirName() {
        return dirName;
    }

    public void setDirName(String dirName) {
        this.dirName = dirName;
    }

    public void add(Node node){
        list.add(node);
    }

    public List<Node> getList() {
        return list;
    }

    public void setList(List<Node> list) {
        this.list = list;
    }

    @Override
    void printNode() {
        System.out.println(dirName);
    }
}
```

```java
public class NodeUtil {
    public static void tree(Node node, int depth){
        for (int i = 0; i < depth; i++) {
            System.out.print("  ");
        }

        node.printNode();

        if(node instanceof BranchNode){
            List<Node> list = ((BranchNode) node).getList();
            for(Node n : list){
                tree(n, depth+1);
            }
        }
    }

    public static void main(String[] args) {
        BranchNode dir = new BranchNode("dir");
        BranchNode dirOne = new BranchNode("dirOne");
        dirOne.add(new LeafNode("dirOneFile"));
        BranchNode dirTwo = new BranchNode("dirTwo");
        dirTwo.add(new LeafNode("dirTwoFile"));
        dirOne.add(dirTwo);
//        dir.add();
        dir.add(new LeafNode("README.md"));
        dir.add(new LeafNode("main.java"));
        dir.add(dirOne);
        tree(dir, 0);
    }
}
```

