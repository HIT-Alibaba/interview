## 消息

在C++或Java里，类与类的行为方法之间的关系非常紧密，一个方法必定属于一个类，且于编译时就已经绑定在一起，所以你不可能调用一个类里没有的方法。而在Objective-C中就比较简单了，类和消息之间是松耦合的，方法调用只是向某个类发送一个消息，该类可以在运行时再确定怎么处理接受到的消息。也就是说，一个类不保证一定会响应接收到的消息，如果收到了一个无法处理的消息，那么程序就是简单报一个错而已。

Objective-C 是 C 语言的超集，所有的方法在底层都是简单朴素的 C 方法，运行时决定了当传入一个消息时具体哪个方法被调用。

像对象发送一个消息的代码类似于这个：

```objectivec
id returnValue = [someObject messageName:parameter];
```

最终这个代码会变成类似下面这个C方法：

```objectivec
id returnValue = objc_msgSend(someObject, @selector(messageName:), parameter);
```

## 消息传递

当一个对象接受到它不能理解的消息时，消息传递机制会被启用。

在消息真正“不被处理”之前，有三次可以处理它的机会。

**第一次是动态方法解析**

当一个对象接受到它不能理解的消息时，第一个被调用的方法是一个类方法：

```objectivec
+ (BOOL)resolveInstanceMethod:(SEL)selector;
```

这个方法以传入对象的 selector 作为参数，返回一个布尔值，这个值指示了有没有一个实例方法被添加到类中，使得类现在可以处理这个 selector。


**如果失败，使用替代接收者**

第二次尝试是询问接受这个消息的类，有没有一个替代接受者可以处理这个未知消息，对应的函数是：

```objectivec
- (id)forwardingTargetForSelector:(SEL)selector;
```

未知 selector 被传入，如果有替代者，那么替代者对象会被返回，否则返回nil

**最后，使用消息传递机制**

如果上面这些尝试都失败了，只能使用完成的消息传递机制。首先创建一个`NSInvocation`对象来包装好这个没有处理的消息的所有细节。

用于传递消息的方法是：

```objectivec
- (void)forwardInvocation:(NSInvocation *)invocation;
```

这个方法的实现应该总是调用其父类的实现。最终`NSObject`的实现会唤醒`doesNotRecognizeSelector`来触发一个“未处理的 selector” 异常。

## Method Swizzling

当消息传入一个函数时，实际调用的方法是在运行时决定的。这就允许我们改变某个消息传入时实际调用的方法。通常这种办法用于改变那些看不到源码的类的功能。

类的方法列表包含了一系列的 selector 名字和对应的实现之间的映射，用于指导动态消息系统去哪里找某个消息对应的实现。这些对应的实现存储为一种叫做`IMP`的函数指针，其原型如下：

```objectivec
id (*IMP)(id, SEL, ...)
```

要想得到某个 selector 对应的实现，可以使用下面的函数：

```objectivec
Method class_getInstanceMethod(Class aClass, SEL aSelector)
```

想添加一个实现，可以使用下面的函数：

```objectivec
BOOL class_addMethod(Class class, SEL originalSelector, Method m1, const char* encoding)
```

要想交换两个实现，可以使用：

```objectivec
void method_exchangeImplementations(Method m1, Method m2)
```

Swizzling 通常被认为是一种黑科技，它容易导致不可预测的行为和难以预知的结果。尽管它不是十分安全，但是只要能做到下面几点，使用它相对而言还是比较安全的：

* 总是调用方法本来的实现（除非你真的不需要这么做）
* 避免冲突
* 明白你在干什么
* 小心谨慎

### 参考资料

* [Objective-C——消息、Category和Protocol](http://www.cnblogs.com/chijianqiang/archive/2012/06/22/objc-category-protocol.html)