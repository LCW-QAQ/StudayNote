# Master公式

> 用来分析递归函数的时间复杂度

数据量为N, Master公式为:

​		**T(N) = T(N/2) * 2 + O(1)**



只有满足一下条件才能使用Master公式估计时间复杂度

- T(N) = A * T(N/B) + O(N^D)
- A, B, D 为常数
- 如果子问题的规模不一致, 无法使用Master公式来估计时间复杂度



根据公式求出复杂度:

- log(A, B) < D
    - O(N^D)
- log(A, B) > D
    - O(N^log(A, B))
- log(A, B) == D
    - O(N^D * log(N, 2))

