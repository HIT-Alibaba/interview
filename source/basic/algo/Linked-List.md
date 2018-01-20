## 单链表

### 单链表就地翻转

递归算法：

```c
void reverse(struct list_node *head)
{
    if(NULL == head || NULL == head->next)
        return;
    reverse1(head->next);
    head->next->next = head;
    head->next = NULL;
}
```

非递归算法：

```c
void reverse2(struct list_node *head)
{
    if (NULL == head)
    {
        return;
    }

    list_node *curr = head;
    list_node *next = head->next;
    list_node *prev = NULL;
    while (next != NULL) {
        curr->next = prev;
        prev = curr;
        curr = next;
        next = curr->next;
    }

    curr->next = prev;
}
```

