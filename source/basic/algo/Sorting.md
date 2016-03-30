## 排序算法的评价

#### 稳定性

稳定排序算法会依照相等的关键（换言之就是值）维持纪录的相对次序。也就是一个排序算法是稳定的，就是当有两个有相等关键的纪录R和S，且在原本的串行中R出现在S之前，在排序过的串行中R也将会是在S之前。

#### 计算复杂度（最差、平均、和最好表现）

依据串行（list）的大小（n），一般而言，好的表现是O(nlogn)，且坏的行为是O(n2)。对于一个排序理想的表现是O(n)。仅使用一个抽象关键比较运算的排序算法总平均上总是至少需要O(nlogn)。

所有基于比较的排序的时间复杂度至少是 O(nlogn)。

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
* 快速排序（Quicksort）— O(nlogn) 期望时间, O(n²) 最坏情况; 对于大的、乱数串行一般相信是最快的已知排序

#### 快排

快排是经典的 divide & conquer 问题，如下用于描述快排的思想、伪代码、代码、复杂度计算以及快排的变形。

##### 快排的思想

如下的三步用于描述快排的流程：

- 在数组中随机取一个值作为标兵
- 对标兵左、右的区间进行划分(将比标兵大的数放在标兵的右面，比标兵小的数放在标兵的左面，如果倒序就反过来)
- 重复如上两个过程，直到选取了所有的标兵并划分(此时每个标兵决定的区间中只有一个值，故有序)

##### 伪代码

如下是快排的主体伪代码

```
QUCIKSORT(A, p, r)
if p < r
    q = PARTITION(A, p, r)
    QUICKSORT(A, p, q-1)
    QUICKSORT(A, q+1, r)
```

如下是用于选取标兵以及划分的伪代码

```
PARTITION(A, p, r)
x = A[r]
i = p - 1
for j = p to r - 1
	if A[j] <= x
		i++
		swap A[i] with A[j]
swap A[i+1] with A[j]
return i+1
```

##### 代码

```Swift
func quickSort(inout targetArray: [Int], begin: Int, end: Int) {
    if begin < end {
        let pivot = partition(&targetArray, begin: begin, end: end)
        quickSort(&targetArray, begin: begin, end: pivot - 1)
        quickSort(&targetArray, begin: pivot + 1, end: end)
    }
}

func partition(inout targetArray: [Int], begin: Int, end: Int) -> Int {
    let value = targetArray[end]
    var i = begin - 1
    for j in begin ..< end {
        if  targetArray[j] <= value {
            i += 1;
            swapTwoValue(&targetArray[i], b: &targetArray[j])
        }
    }
    swapTwoValue(&targetArray[i+1], b: &targetArray[end])
    return i+1
}

func swapTwoValue(inout a: Int, inout b: Int) {
    let c = a
    a = b
    b = c
}

var testArray :[Int] = [123,3333,223,231,3121,245,1123]

quickSort(&testArray, begin: 0, end: testArray.count-1)
```

##### 复杂度分析

在最好的情况下，每次 partition 都会把数组一分为二，所以时间复杂度 T(n) = 2T(n/2) + O(n)

解为 T(n) = O(nlog(n))

在最坏的情况下，数组刚好和想要的结果顺序相同，每次 partition 到的都是当前无序区中最小(或最大)的记录，因此只得到一个比上一次划分少一个记录的子序列。T(n) = O(n) + T(n-1)

解为 T(n) = O(n²)

在平均的情况下，快排的时间复杂度是 O(nlog(n))

##### 变形

可以利用快排的 PARTITION 思想求数组中第K大元素这样的问题，步骤如下：

- 在数组中随机取一个值作为标兵，左右分化后其顺序为X
- 如果 X == Kth 说明这就是第 K 大的数
- 如果 X > Kth 说明第 K 大的数在标兵左边，继续在左边寻找第 Kth 大的数
- 如果 X < Kth 说明第 K 大的数在标兵右边，继续在右边需找第 Kth - X 大的数

这个问题的时间复杂度是 O(n)

T(n) = n + n/2 + n/4 + ... = O(n)

### 参考资料

1. [各种基本排序算法的总结](http://blog.sina.com.cn/s/blog_4080505a0101iewt.html)
2. [常用排序算法小结](http://blog.csdn.net/whuslei/article/details/6442755)
3. [八大排序算法总结](http://blog.csdn.net/yexinghai/article/details/4649923)
4. [QuickSort](https://en.wikipedia.org/wiki/Quicksort)