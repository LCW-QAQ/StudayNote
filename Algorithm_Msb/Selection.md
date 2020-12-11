# Selection

> 选择排序平时不怎么使用, 因为时间复杂度太高, 速度太慢
>
> 我们将n个元素从容器中拿出来, 将他与后面的元素比较, 找到最小的元素, 然后和n互换位置

```java
import java.util.Arrays;

/**
 * @author lcw
 * @Create 2020-10-22
 */
public class Selection {
    //时间复杂度为O(n^2)
    public static void selectionSort(Comparable[] arr){
        for (int i = 0; i < arr.length-1; i++) {//n
            int min = i;
            for (int j = i+1; j < arr.length; j++) {//(n-1)+(n-2)+...+1
                if(arr[min] != null && arr[min].compareTo(arr[j]) > 0){
                    min = j;
                }
//                min = arr[min] != null ? arr[min].compareTo(arr[j]) > 0 ? j : min : min;
            }
            SortUtil.swap(arr, min, i);//n
        }
    }
}
```

