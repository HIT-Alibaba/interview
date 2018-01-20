## 排序算法的评价

### 稳定性

稳定排序算法会依照相等的关键（换言之就是值）维持纪录的相对次序。也就是一个排序算法是稳定的，就是当有两个有相等关键的纪录R和S，且在原本的串行中R出现在S之前，在排序过的串行中R也将会是在S之前。

### 计算复杂度（最差、平均、和最好表现）

依据串行（list）的大小（n），一般而言，好的表现是O(nlogn)，且坏的行为是O(n2)。对于一个排序理想的表现是O(n)。仅使用一个抽象关键比较运算的排序算法总平均上总是至少需要O(nlogn)。

所有基于比较的排序的时间复杂度至少是 O(nlogn)。

## 常见排序算法

常见的稳定排序算法有：

* 冒泡排序（Bubble Sort） — O(n²)
* 插入排序（Insertion Sort）— O(n²)
* 桶排序（Bucket Sort）— O(n); 需要 O(k) 额外空间
* 计数排序 (Counting Sort) — O(n+k); 需要 O(n+k) 额外空间
* 合并排序（Merge Sort）— O(nlogn); 需要 O(n) 额外空间
* 二叉排序树排序 （Binary tree sort） — O(n log n) 期望时间; O(n²)最坏时间; 需要 O(n) 额外空间
* 基数排序（Radix sort）— O(n·k); 需要 O(n) 额外空间

常见的不稳定排序算法有：

* 选择排序（Selection Sort）— O(n²)
* 希尔排序（Shell Sort）— O(nlogn)
* 堆排序（Heapsort）— O(nlogn)
* 快速排序（Quicksort）— O(nlogn) 期望时间, O(n²) 最坏情况; 对于大的、乱数串行一般相信是最快的已知排序

### 冒泡排序

冒泡排序是最简单最容易理解的排序算法之一，其思想是通过无序区中相邻记录关键字间的比较和位置的交换,使关键字最小的记录如气泡一般逐渐往上“漂浮”直至“水面”。 冒泡排序的复杂度，在最好情况下，即正序有序，则只需要比较n次。故，为O(n) ，最坏情况下，即逆序有序，则需要比较(n-1)+(n-2)+……+1，故，为O(n²)。

#### 乌龟和兔子

在冒泡排序中，最大元素的移动速度是最快的，哪怕一开始最大元素处于序列开头，也可以在一轮内层循环之后，移动到序列末尾。而对于最小元素，每一轮内层循环只能向前挪动一位，如果最小元素在序列末尾，就需要 n-1 次交换才能移动到序列开头。这两种类型的元素分别被称为兔子和乌龟。

#### 代码实现：

```csharp
private static void BubbleSort(int[] array)
{
    for (var i = 0; i < array.Length - 1; i++)  // 若最小元素在序列末尾，需要 n-1 次交换，才能交换到序列开头
    {
        for (var j = 0; j < array.Length - 1; j++)
        {
            if (array[j] > array[j + 1])   // 若这里的条件是 >=，则变成不稳定排序
            {
                Swap(array, j, j+1);
            }
        }
    }
}
```

#### 优化

在非最坏的情况下，冒泡排序过程中，可以检测到整个序列是否已经排序完成，进而可以避免掉后续的循环：

```csharp
private static void BubbleSort(int[] array)
{
    for (var i = 0; i < array.Length - 1; i++)
    {
        var swapped = false;
        for (var j = 0; j < array.Length - 1; j++)
        {
            if (array[j] > array[j + 1])
            {
                Swap(array, j, j+1);
                swapped = true;
            }
        }

        if (!swapped)  // 没有发生交互，证明排序已经完成
        {
            break;
        }
    }
}
```

进一步地，在每轮循环之后，可以确认，最后一次发生交换的位置之后的元素，都是已经排好序的，因此可以不再比较那个位置之后的元素，大幅度减少了比较的次数：

```csharp
private static void BubbleSort(int[] array)
{
    var n = array.Length;
    for (var i = 0; i < array.Length - 1; i++)
    {
        var newn = 0;
        for (var j = 0; j < n - 1; j++)
        {
            if (array[j] > array[j + 1])
            {
                Swap(array, j, j+1);
                newn = j + 1;   // newn 以及之后的元素，都是排好序的
            }
        }

        n = newn;

        if (n == 0)
        {
            break;
        }
    }
}
```

更进一步地，为了优化之前提到的乌龟和兔子问题，可以进行双向的循环，正向循环把最大元素移动到末尾，逆向循环把最小元素移动到最前，这种优化过的冒泡排序，被称为鸡尾酒排序：

```csharp
private static void CocktailSort(int[] array)
{
    var begin = 0;
    var end = array.Length - 1;
    while (begin <= end)
    {
	var newBegin = end;
	var newEnd = begin;

	for (var j = begin; j < end; j++)
	{
	    if (array[j] > array[j + 1])
	    {
		Swap(array, j, j + 1);
		newEnd = j + 1;
	    }
	}

	end = newEnd - 1;

	for (var j = end; j > begin - 1; j--)
	{
	    if (array[j] > array[j + 1])
	    {
		Swap(array, j, j + 1);
		newBegin = j;
	    }
	}

	begin = newBegin + 1;
    }
}
```

### 插入排序

插入排序也是一个简单的排序算法，它的思想是，每次只处理一个元素，从后往前查找，找到该元素合适的插入位置，最好的情况下，即正序有序(从小到大)，这样只需要比较n次，不需要移动。因此时间复杂度为O(n) ，最坏的情况下，即逆序有序，这样每一个元素就需要比较n次，共有n个元素，因此实际复杂度为O(n²) 。

#### 算法实现：

```csharp
private static void InsertionSort(int[] array)
{
    int i = 1;
    while (i < array.Length)
    {
	var j = i;
	while (j > 0 && array[j - 1] > array[j])
	{
	    Swap(array, j, j - 1);
	    j--;
	}

	i++;
    }
}
```

### 快排

快排是经典的 divide & conquer 问题，如下用于描述快排的思想、伪代码、代码、复杂度计算以及快排的变形。

#### 快排的思想

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
