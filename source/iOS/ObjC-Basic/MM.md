**推荐首先阅读 [内存管理](../../basic/arch/Memory-Management.md) ** 

### Objective-C中的内存分配

在 Objective-C 中，对象通常是使用 `alloc` 方法在堆上创建的。 `[NSObject alloc]` 方法会在对堆上分配一块内存，按照`NSObject`的内部结构填充这块儿内存区域。

一旦对象创建完成，就不可能再移动它了。因为很可能有很多指针都指向这个对象，这些指针并没有被追踪。因此没有办法在移动对象的位置之后更新全部的这些指针。

## MRC 与 ARC

Objective-C中提供了两种内存管理机制：MRC（MannulReference Counting）和ARC(Automatic Reference Counting)，分别提供对内存的手动和自动管理，来满足不同的需求。现在苹果推荐是用 ARC 来进行内存管理。

### MRC 

在MRC的内存管理模式下，与对变量的管理相关的方法有：retain,release和autorelease。retain和release方法操作的是引用记数，当引用记数为零时，便自动释放内存。并且可以用NSAutoreleasePool对象，对加入自动释放池（autorelease调用）的变量进行管理，当drain时回收内存。

1. retain，该方法的作用是将内存数据的所有权附给另一指针变量，引用数加1，即retainCount+= 1;
2. release，该方法是释放指针变量对内存数据的所有权，引用数减1，即retainCount-= 1;
3. autorelease，该方法是将该对象内存的管理放到autoreleasepool中。

示例代码:

```objective-c
//假设Number为预定义的类
Number* num = [[Number alloc] init];
Number* num2 = [num retain];//此时引用记数+1，现为2

[num2 release]; //num2 释放对内存数据的所有权 引用记数-1,现为1;
[num release];//num释放对内存数据的所有权 引用记数-1,现为0;
[num add:1 and 2];//bug，此时内存已释放。

//autoreleasepool 的使用 在MRC管理模式下，我们摒弃以前的用法，NSAutoreleasePool对象的使用，新手段为@autoreleasepool

@autoreleasepool {
    Number* num = [[Number alloc] init];
    [numautorelease];//由autoreleasepool来管理其内存的释放
} 

```

### ARC 

ARC 是苹果引入的一种自动内存管理机制，会自动监视对象的生存周期，并在编译时期自动在已有代码中插入合适的内存管理代码。

#### 变量标识符

在ARC中与内存管理有关的变量标识符，有下面几种：

* `__strong`
* `__weak`
* `__unsafe_unretained`
* `__autoreleasing`

`__strong` 是默认使用的标识符。只有还有一个强指针指向某个对象，这个对象就会一种存活。

`__weak` 声明这个引用不会保持被引用对象的存活，如果对象没有强引用了，弱引用会被置为nil

`__unsafe_unretained` 声明这个引用不会保持被引用对象的存活，如果对象没有强引用了，它不会被置为nil。如果它引用的对象被回收掉了，该指针就变成了野指针。

`__autoreleasing` 用于标示使用引用传值的参数（id *），在函数返回时会被自动释放掉。

变量标识符的用法如下：

```objective-c
__strong Number* num = [[Number alloc] init];
``` 

#### 属性标识符

类中的属性也可以加上标志符：

```objective-c
@property (assign/retain/strong/weak/unsafe_unretained/copy) Number* num
```

`assign`表明 setter 仅仅是一个简单的赋值操作，通常用于基本的数值类型，例如`CGFloat`和`NSInteger`。

`strong`表明属性定义一个拥有者关系。当给属性设定一个新值的时候，首先这个值进行 `retain` ，旧值进行 `release` ，然后进行赋值操作。

`weak`表明属性定义了一个非拥有者关系。当给属性设定一个新值的时候，这个值不会进行 `retain`，旧值也不会进行 `release`， 而是进行类似 `assign` 的操作。不过当属性指向的对象被销毁时，该属性会被置为nil。

`unsafe_unretained`的语义和 `assign` 类似，不过是用于对象类型的，表示一个非拥有(unretained)的，同时也不会在对象被销毁时置为nil的(unsafe)关系。

`copy` 类似于 `strong`，不过在赋值时进行 `copy` 操作而不是 `retain` 操作。通常在需要保留某个不可变对象（NSString最常见），并且防止它被意外改变时使用。


### 引用循环

当两个对象互相持有对方的强引用，并且这两个对象的引用计数都不是0的时候，便造成了引用循环。

要想破除引用循环，可以从以下几点入手：

* 注意变量作用域，使用 `autorelease` 让编译器来处理引用
* 使用弱引用(weak)
* 当实例变量完成工作后，将其置为nil

### Autorelease Pool

Autorelase Pool 提供了一种可以允许你向一个对象延迟发送`release`消息的机制。当你想放弃一个对象的所有权，同时又不希望这个对象立即被释放掉（例如在一个方法中返回一个对象时），Autorelease Pool 的作用就显现出来了。

所谓的延迟发送`release`消息指的是，当我们把一个对象标记为`autorelease`时:

```objective-c
NSString* str = [[[NSString alloc] initWithString:@"hello"] autorelease];
```

这个对象的 retainCount 会+1，但是并不会发生 release。当这段语句所处的 autoreleasepool 进行 drain 操作时，所有标记了 `autorelease` 的对象的 retainCount 会被 -1。即 `release` 消息的发送被延迟到 pool 释放的时候了。

在 ARC 环境下，苹果引入了 `@autoreleasepool` 语法，不再需要手动调用 `autorelease` 和 `drain` 等方法。

#### Autorelease Pool 的用处

在 ARC 下，我们并不需要手动调用 autorelease 有关的方法，甚至可以完全不知道 autorelease 的存在，就可以正确管理好内存。因为 Cocoa Touch 的 Runloop 中，每个 runloop circle 中系统都自动加入了 Autorelease Pool 的创建和释放。

当我们需要创建和销毁大量的对象时，使用手动创建的 autoreleasepool 可以有效的避免内存峰值的出现。因为如果不手动创建的话，外层系统创建的 pool 会在整个 runloop circle 结束之后才进行 drain，手动创建的话，会在 block 结束之后就进行 drain 操作。详情请参考[苹果官方文档](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmAutoreleasePools.html#//apple_ref/doc/uid/20000047-CJBFBEDI)。一个普遍被使用的例子如下：

```objective-c
for (int i = 0; i < 100000000; i++)
{
    @autoreleasepool
    {
        NSString* string = @"ab c";
        NSArray* array = [string componentsSeparatedByString:string];
    }
}
```

如果不使用 autoreleasepool ，需要在循环结束之后释放 100000000 个字符串，如果
使用的话，则会在每次循环结束的时候都进行 release 操作。

#### Autorelease Pool 进行 Drain 的时机

如上面所说，系统在 runloop 中创建的 autoreleaspool 会在 runloop 一个 event 结束时进行释放操作。我们手动创建的 autoreleasepool 会在 block 执行完成之后进行 drain 操作。需要注意的是：

* 当 block 以异常（exception）结束时，pool 不会被 drain
* Pool 的 drain 操作会把所有标记为 autorelease 的对象的引用计数减一，但是并不意味着这个对象一定会被释放到，我们可以在 autorelease pool 中手动 retain 对象，以延长它的生命周期。

#### main.m 中 autorelease pool 的解释

大家都知道在 iOS 程序的 main.m 文件中有类似这样的语句：

```objective-c
int main(int argc, char * argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
```

在面试中问到有关 autorelease pool 有关的知识也多半会问一下，这里的 pool 有什么作用，能不能去掉之类。在这里我们分析一下。

根据[苹果官方文档](https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/index.html#//apple_ref/c/func/UIApplicationMain)， UIApplicationMain 函数是整个 app 的入口，用来创建 application 对象（单例）和 application delegate。尽管这个函数有返回值，但是实际上却永远不会返回，当按下 Home 键时，app 只是被切换到了后台状态。

同时参考苹果关于 Lifecycle 的[官方文档](https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/TheAppLifeCycle/TheAppLifeCycle.html)，UIApplication 自己会创建一个 main run loop，我们大致可以得到下面的结论：

1. main.m 中的 UIApplicationMain 永远不会返回，只有在系统 kill 掉整个 app 时，系统会把应用占用的内存全部释放出来。
2. 因为(1)， UIApplicationMain 永远不会返回，这里的 autorelease pool 也就永远不会进入到释放那个阶段
3. 在 (2) 的基础上，假设有些变量真的进入了 main.m 里面这个 pool（没有被更内层的 pool 捕获），那么这些变量实际上就是被泄露的。这个 autorelease pool 等于是把这种泄露情况给隐藏起来了。
4. UIApplication 自己会创建 main run loop，在 Cocoa 的 runloop 中实际上也是自动包含 autorelease pool 的，因此 main.m 当中的 pool 可以认为是**没有**必要的。

在基于 AppKit 框架的 Mac OS 开发中， main.m 当中就是不存在 autorelease pool 的，也进一步验证了我们得到的结论。不过因为我们看不到更底层的代码，加上苹果的文档中不建议修改 main.m ，所以我们也没有理由就直接把它删掉。


### 参考资料

* [Objective-C内存管理MRC与ARC](http://blog.csdn.net/fightingbull/article/details/8098133)
* [10个Objective-C基础面试题，iOS面试必备](http://www.oschina.net/news/42288/10-objective-c-interview)
* [黑幕背后的 Autorelease](http://blog.sunnyxx.com/2014/10/15/behind-autorelease/)
* https://stackoverflow.com/questions/29350634/ios-autoreleasepool-in-main-and-arc-alloc-release
* https://stackoverflow.com/questions/6588211/why-do-the-ios-main-m-templates-include-a-return-statement-and-an-autorelease-po
* https://stackoverflow.com/questions/2702548/if-the-uiapplicationmain-never-returns-then-when-does-the-autorelease-pool-get