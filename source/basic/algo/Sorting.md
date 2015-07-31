## 排序算法的评价

#### 稳定性

稳定排序算法会依照相等的关键（换言之就是值）维持纪录的相对次序。也就是一个排序算法是稳定的，就是当有两个有相等关键的纪录R和S，且在原本的串行中R出现在S之前，在排序过的串行中R也将会是在S之前。

#### 计算复杂度（最差、平均、和最好表现）

依据串行（list）的大小（n），一般而言，好的表现是O(nlogn)，且坏的行为是O(n2)。对于一个排序理想的表现是O(n)。仅使用一个抽象关键比较运算的排序算法总平均上总是至少需要O(nlogn)。

## 常见排序算法

#### 稳定排序：

* 冒泡排序（Bubble Sort） — O(n²)
* 插入排序（Insertion Sort）— O(n²)
* 桶排序（Bucket Sort）— O(n); 需要 O(k) 额外空间
* 计数排序 (Counting Sort) — O(n+k); 需要 O(n+k) 额外空间
* 合并排序（Merge Sort）— O(nlogn); 需要 O(n) 额外空间
* 二叉排序树排序 （Binary tree sort） — O(n log n) 期望时间; O(n²)最坏时间; 需要 O(n) 额外空间
* 基数排序（Radix sort）— O(n·k); 需要 O(n) 额外空间

#### 不稳定排序

* 选择排序（Selection Sort）— O(n²)
* 希尔排序（Shell Sort）— O(nlogn)
* 堆排序（Heapsort）— O(nlogn)
* 快速排序（Quicksort）— O(nlogn) 期望时间, O(n2) 最坏情况; 对于大的、乱数串行一般相信是最快的已知排序

### 参考资料

1. [各种基本排序算法的总结](http://blog.sina.com.cn/s/blog_4080505a0101iewt.html)
2. [常用排序算法小结](http://blog.csdn.net/whuslei/article/details/6442755)
3. [八大排序算法总结](http://blog.csdn.net/yexinghai/article/details/4649923)