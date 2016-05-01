## 洗牌算法

洗牌算法，顾名思义，就是只利用一次循环等概率的取到不同的元素(牌)。

如果元素存在于数组中，即可将每次 random 到的元素 与 最后一个元素进行交换，然后 count--，即可。

这相当于把这个元素删除，代码如下：

```cpp
#include <iostream>
#include <ctime> 
using namespace std;

const int maxn = 10;

int a[maxn];

int randomInt(int a) {
	return rand()%a;
}
void swapTwoElement(int*x,int*y) {
	 int temp;
     temp=*x;
     *x=*y;
     *y=temp;
}

int main(){
	int count = sizeof(a)/sizeof(int);
	int count_b = count;
	srand((unsigned)time(NULL));
	for (int i = 0; i < count; ++i) { a[i] = i; }
	for (int i = 0; i < count_b; ++i) {
		int random = randomInt(count);
		cout<<a[random]<<" ";
		swapTwoElement(&a[random],&a[count-1]);
		count--;
	}
}
```