## 例题

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

    ListNode *prev = NULL, *temp = NULL;
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

和找环的方法类似，同样可以使用 Hash 表存储所有节点，发现重复的节点即交点。

一个容易想到的方法是，先得到两个链表的长度，然后得到长度的差值 distance，两个指针分别从两个链表头部遍历，其中较长链表指针先走 distance 步，然后同时向后走，当两个指针相遇的时候，即链表的交点：

```cpp
int getListLength(ListNode *head) {
    if (head == nullptr) {
        return 0;
    }
    int length = 0;
    ListNode *p = head;
    while (p!=nullptr) {
        p = p->next;
        length ++;
    }
    return length;
}

ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
    int lengthA = getListLength(headA);
    int lengthB = getListLength(headB);

    if (lengthA > lengthB) {
        std::swap(headA, headB);
    };
    int distance = abs(lengthB - lengthA);
    ListNode *p1 = headA;
    ListNode *p2 = headB;
    while(distance--) {
        p2 = p2->next;
    }
    while (p1 != nullptr && p2 != nullptr) {
        if (p1 == p2)
            return p1;
        p1 = p1->next;
        p2 = p2->next;
    }
    return NULL;
}
```

另一个较快的方法时，两个指针 pa，pb 分别从 headA，headB开始遍历，当 pa 遍历到尾部的时候，指向 headB，当 pb 遍历到尾部的时候，转向 headA。当两个指针再次相遇的时候，如果两个链表有交点，则指向交点，如果没有则指向 NULL：

```cpp
ListNode *getIntersectionNode(ListNode *headA, ListNode *headB) {
    ListNode *pa = headA;
    ListNode *pb = headB;

    while (pa != pb) {
        pa = pa != nullptr ? pa->next : headB;
        pb = pb != nullptr ? pb->next : headA;
    }

    return pa;
}
```


#### 单链表找中间节点 [LeetCode 876](https://leetcode.com/problems/middle-of-the-linked-list/)

用快慢指针法，当快指针走到链表结尾时，慢指针刚好走到链表的中间：

```cpp
ListNode* middleNode(ListNode* head) {
    ListNode *slow = head;
    ListNode *fast = head;
    while (fast && fast->next) {
        slow = slow->next;
        fast = fast->next->next;
    }

    return slow;
}
```

#### 单链表合并 [LeetCode 21](https://leetcode.com/problems/merge-two-sorted-lists/)

两个链表本身都是排序过的，把两个链表从头节点开始，逐个节点开始进行比较，最后剩下的节点接到尾部：

```cpp
ListNode *mergeTwoLists(ListNode *l1, ListNode *l2) {
    if (l1 == nullptr) {
        return l2;
    }
    if (l2 == nullptr) {
        return l1;
    }
    ListNode dummy(-1);
    ListNode *p = &dummy;
    for (; l1 && l2; p = p->next) {
        if (l1->val < l2->val) {
            p->next = l1;
            l1 = l1->next;
        } else {
            p->next = l2;
            l2 = l2->next;
        }
    }
    p->next = l1 != nullptr ? l1 : l2;
    return dummy.next;
}
```