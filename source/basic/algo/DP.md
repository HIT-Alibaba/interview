## 动态规划

建议观看 MIT [算法导论-动态规划](http://open.163.com/movie/2010/12/L/4/M6UTT5U0I_M6V2U1HL4.html)中的课程。

适用于动态规划的问题，需要满足**最优子结构**和**无后效性**，动态规划的求解过程，在于找到**状态转移方程**，进行**自底向上**的求解。

## 例题

#### 爬楼梯问题 [LeetCode 70](https://leetcode.com/problems/climbing-stairs/)

经典的动态规划问题之一，容易找到其状态转移方程为 `dp[i] = dp[i-1] + dp[i-2]`，从基础的 1 和 2 个台阶两个状态开始，自底向上求解：

```cpp
int climbStairs(int n) {
    if (n == 1) {
        return 1;
    }

    int* dp = new int[n+1]();
    dp[1] = 1;
    dp[2] = 2;

    for (int i = 3; i <= n; i++) {
        dp[i] = dp[i-1] + dp[i-2];
    }

    return dp[n];
}
```

从上面的代码中看到，`dp[i]` 只依赖 `dp[i-1]` 和 `dp[i-2]`，因此可以将代码简化：

```cpp
int climbStairs(int n) {
    int f0 = 1, f1 = 1, i, f2;
    for (i=2; i<=n; i++) {
        f2 = f0 + f1;
        f0 = f1;
        f1 = f2;
    }
    return f1;
}
```

容易看出其实结果就是 fibonacci 数列的第 n 项。

#### 连续子数组的最大和 [LeetCode 53](https://leetcode.com/problems/maximum-subarray/)

用 `dp[n`] 表示元素 n 作为末尾的连续序列的最大和，容易想到状态转移方程为`dp[n] = max(dp[n-1] + num[n], num[n])`，从第 1 个元素开始，自顶向上求解：

```cpp
int maxSubArray(vector<int>& nums) {
    int* dp = new int[nums.size()]();

    dp[0] = nums[0];
    int result = dp[0];

    for (int i = 1; i < nums.size(); i++) {
        dp[i] = max(dp[i-1] + nums[i], nums[i]);
        result = max(result, dp[i]);
    }

    return result;
}
```

类似前一个问题，这个问题当中，求解 `dp[i]` 只依赖 `dp[i-1]`，因此可以使用变量来存储，简化代码：

```cpp
int maxSubArray(int A[], int n) {
    int result = INT_MIN;
    int f = 0;
    for (int i=0; i < n; i++) {
        f = max(f + A[i], A[i]);
        result = max(result, f);
    }
    return result;
}
```

#### House Robber [LeetCode 198](https://leetcode.com/problems/house-robber/)

对于一个房子，有抢和不抢两种选择，容易得到状态转移方程 `dp[i+1] = max(dp[i-1] + nums[i], dp[i])`，示例代码如下：

```cpp
int rob(vector<int>& nums) {
    int n = nums.size();
    if (n == 0) {
        return 0;
    }

    vector<int> dp = vector<int>(n + 1);

    dp[0] = 0;
    dp[1] = nums[0];

    for (int i = 1; i < nums.size(); i++) {
        int v = nums[i];
        dp[i+1] = max(dp[i-1] + v, dp[i]);
    }

    return dp[n];
}
```

同样的，可以使用两个变量简化代码：

```cpp
int rob(vector<int>& nums) {
    int n = nums.size();
    if (n == 0) {
        return 0;
    }

    int prev1 = 0;
    int prev2 = 0;

    for (int i = 0; i < nums.size(); i++) {
        int v = nums[i];
        int temp = prev1;
        prev1 = max(prev2 + v, prev1);
        prev2 = temp;
    }

    return prev1;
}
```

#### 最长回文子串 [LeetCode 5](https://leetcode.com/problems/longest-palindromic-substring/)

用 `dp[i][j]` 表示子串 i 到 j 是否是回文，使用动态规划求解：

```cpp
string longestPalindrome(string s) {
	int m = s.size();
	if (m == 0) {
		return "";
	}
	vector<vector<int>> dp(m, vector<int>(m, 0));
	int start = 0;
	int length = 1;

	for (int i = 0; i < m; i++) {
        // 单个字符属于回文，例如 abcd
		dp[i][i] = 1;

        // 连续两个字符相同属于回文，例如 abb
		if (i < m - 1) {
			if (s[i] == s[i + 1]) {
				dp[i][i + 1] = 1;
                start = i;
				length = 2;
			}
		}
	}

	for (int len = 2; len <= m; len++) {
		for (int i = 0; i < m - len; i++) {
			int j = i + len;
            // 扩展长度
			if (dp[i + 1][j - 1] == 1 && s[i] == s[j]) {
				dp[i][j] = 1;

				if (j - i + 1 > length) {
                    start = i;
					length = j - i + 1;
				}
			}
		}
	}

	return s.substr(start, length);
}
```

#### 最小编辑距离 [LeetCode 72](https://leetcode.com/problems/edit-distance/)

用 `dp[i][j]` 表示从 `word[0..i)` 转换到 `word[0..j)` 的最小操作，使用动态规划求解：

```cpp
int minDistance(string word1, string word2) {
    int m = word1.size();
    int n = word2.size();
    vector<vector<int>> dp(m + 1, vector<int>(n + 1, 0));

    // 全部删除，操作数量为 i
    for (int i = 0; i <= m; i++) {
        dp[i][0] = i;
    }

    for (int j = 0; j <= n; j++) {
        dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
        for (int j = 1; j <= n; j++) {
            // 末尾字符相同，不需要编辑
            if (word1[i - 1] == word2[j - 1]) {
                dp[i][j] = dp[i - 1][j - 1];
            } else {
                // 末尾字符不同，三种编辑情况，取最小值
                dp[i][j] = min(dp[i - 1][j - 1], min(dp[i][j - 1], dp[i - 1][j])) + 1;
            }
        }
    }

    return dp[m][n];
}
```
