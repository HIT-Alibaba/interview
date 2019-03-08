## 单链表

#### 单链表翻转 [LeetCode 206](https://leetcode.com/problems/reverse-linked-list/)

这个问题可以使用递归和非递归两种方法解决。

递归算法实现：

```cpp
ListNode* reverseList(ListNode* head)
{
    if(NULL == head || NULL == head->next)
        return head;
    ListNode * p = reverseList(head->next);
    head->next->next = head;
    head->next = NULL;

    return p;
}
```

非递归算法实现：

```cpp
ListNode* reverseList(ListNode* head) {
    ListNode *curr = head;
    if (curr == NULL) {
        return NULL;
    }

    ListNode *prev, *temp = NULL;
    while (curr != NULL) {
        temp = curr->next;
        curr->next = prev;
        prev = curr;
        curr = temp;
    }

    return prev;
}
```

#### 单链表判断是否有环 [LeetCode 141](https://leetcode.com/problems/linked-list-cycle/)

最容易想到的思路是存一个所有 Node 地址的 Hash 表，从头开始遍历，将 Node 存到 Hash 表中，如果出现了重复，则说明链表有环。

一个经典的方法是双指针（也叫快慢指针），使用两个指针遍历链表，一个指针一次走一步，另一个一次走两步，如果链表有环，两个指针必然相遇。

双指针算法实现：

```cpp
bool hasCycle(ListNode *head) {
    if (head == nullptr) {
        return false;
    }
    ListNode *fast,*slow;
    slow = head;
    fast = head->next;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) {
            return true;
        }
    }
    return false;
}
```

#### 单链表找环入口 [LeetCode 141](https://leetcode.com/problems/linked-list-cycle-ii/)

作为上一题的扩展，为了找到环所在的位置，在快慢指针相遇的时候，此时慢指针没有遍历完链表，再设置一个指针从链表头部开始遍历，这两个指针相遇的点，就是链表环的入口。

算法实现：

```cpp
ListNode *detectCycle(ListNode *head) {
    if (head == nullptr) {
        return nullptr;
    }
    ListNode *fast,*slow;
    slow = head;
    fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
        if (slow == fast) {
            ListNode *slow2 = head;
            while (slow2 != slow) {
                slow = slow->next;
                slow2 = slow2->next;
            }
            return slow2;
        }
    }
    return nullptr;
}
```

#### 单链表找交点 [LeetCode 160](https://leetcode.com/problems/intersection-of-two-linked-lists/)
