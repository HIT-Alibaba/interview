## Cocoa 并发编程

iOS 中的多线程，是 Cocoa 框架下的多线程，通过 Cocoa 的封装，可以让我们更为方便的进行多线程编程。

在介绍 Cocoa 并发编程之前，我们先理清会提到的几个术语：

* 线程：就是我们通常提到的线程，在进程中可以用线程去执行一些主进程之外的代码。OS X 中线程的实现基于 POSIX 的 pthread API。
* 进程：也是我们通常意义上提到的进程，一个正在执行中的程序实体，可以产生多个线程
* 任务：一个抽象的概念，用于表示一系列需要完成的工作

Cocoa 中封装了 NSThread, NSOperation, GCD 三种多线程编程方式，他们各有所长。

* NSThread

    NSThread 是一个控制线程执行的对象，通过它我们可以方便的得到一个线程并控制它。NSThread 的线程之间的并发控制，是需要我们自己来控制的，可以通过 NSCondition 实现。它的缺点是需要自己维护线程的生命周期和线程的同步和互斥等，优点是轻量，灵活。

* NSOperation

    NSOperation 是一个抽象类，它封装了线程的细节实现，不需要自己管理线程的生命周期和线程的同步和互斥等。只是需要关注自己的业务逻辑处理，需要和 NSOperationQueue 一起使用。使用 NSOperation 时，你可以很方便的设置线程之间的依赖关系。这在略微复杂的业务需求中尤为重要。

* GCD

    GCD(Grand Central Dispatch) 是 Apple 开发的一个多核编程的解决方法。在 iOS4.0 开始之后才能使用。GCD 是一个可以替代 NSThread 的很高效和强大的技术。当实现简单的需求时，GCD 是一个不错的选择。


在现代 Objective-C 中，苹果已经不推荐使用 NSThread 来进行并发编程，而是推荐使用 GCD 和 NSOperation，具体的迁移文档参见 [Migrating Away from Threads](https://developer.apple.com/library/ios/documentation/General/Conceptual/ConcurrencyProgrammingGuide/ThreadMigration/ThreadMigration.html)。下面我们对 GCD 和 NSOperation 的用法进行简单介绍。

## Grand Central Dispatch(GCD)

Grand Central Dispatch(GCD) 是苹果在 Mac OS X 10.6 以及 iOS 4.0 开始引入的一个高性能并发编程机制，底层实现的库名叫 libdispatch。由于它确实很好用，libdispatch 已经被移植到了 FreeBSD 上，Linux 上也有 port 过去的 [libdispatch 实现](https://github.com/nickhutchinson/libdispatch)。

GCD 这么受大家欢迎，它具体好用在哪里呢？GCD 主要的功劳在于把底层的实现隐藏起来，提供了很简洁的面向“任务” 的编程接口，让程序员可以专注于代码的编写。GCD 底层实现仍然依赖于线程，但是使用 GCD 时完全不需要考虑下层线程的有关细节（创建任务比创建线程简单得多），GCD 会自动对任务进行调度，以尽可能地利用处理器资源。

想要了解 GCD，首先要了解下面几个概念：

* Dispatch Queue：Dispatch Queue 顾名思义，是一个用于维护任务的队列，它可以接受任务（即可以将一个任务加入某个队列）然后在适当的时候执行队列中的任务。
* Dispatch Sources：Dispatch Source 允许我们把任务注册到系统事件上，例如 socket 和文件描述符，类似于 Linux 中 epoll 的作用
* Dispatch Groups：Dispatch Groups 可以让我们把一系列任务加到一个组里，组中的每一个任务都要等待整个组的所有任务都结束之后才结束，类似 pthread_join 的功能
* Dispatch Semaphores：这个更加顾名思义，就是大家都知道的信号量了，可以让我们实现更加复杂的并发控制，防止资源竞争

这些东西中最经常用到的是 Dispatch Queue。之前提到 Dispatch Queue 就是一个类似队列的数据结构，而且是 FIFO(First In, First Out)队列，因此任务开始执行的顺序，就是你把它们放到 queue 中的顺序。GCD 中的队列有下面三种：

1. Serial （串行队列）
    串行队列中任务会按照添加到 queue 中的顺序一个一个执行。串行队列在前一个任务执行之前，后一个任务是被阻塞的，可以利用这个特性来进行同步操作。
    
    我们可以创建多个串行队列，这些队列中的任务是串行执行的，但是这些队列本身可以并发执行。例如有四个串行队列，有可能同时有四个任务在并行执行，分别来自这四个队列。
    
2. Concurrent（并行队列）
    并行队列，也叫 global dispatch queue，可以并发地执行多个任务，但是任务开始的顺序仍然是按照被添加到队列中的顺序。具体任务执行的线程和任务执行的并发数，都是由 GCD 进行管理的。
    
    在 iOS 5 之后，我们可以创建自己的并发队列。系统已经提供了四个全局可用的并发队列，后面会讲到。
    
3. Main Dispatch Queue（主队列）
    主队列是一个全局可见的**串行**队列，其中的任务会在主线程中执行。主队列通过与应用程序的 runloop 交互，把任务安插到 runloop 当中执行。因为主队列比较特殊，其中的任务确定会在主线程中执行，通常主队列会被用作同步的作用。
    
### 获取队列
    
按照上面提到的三种队列，我们有对应的三种获取队列的方式：

1. 串行队列
    系统默认并不提供串行队列，需要我们手动创建：
    
    ```objectivec
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.example.MyQueue", NULL); // OS X 10.7 和 iOS 4.3 之前
    queue = dispatch_queue_create("com.example.MyQueue",  DISPATCH_QUEUE_SERIAL); // 之后
    ```
    
2. 并行队列
    系统默认提供了四个全局可用的并行队列，其优先级不同，分别为 `DISPATCH_QUEUE_PRIORITY_HIGH`，`DISPATCH_QUEUE_PRIORITY_DEFAULT`， `DISPATCH_QUEUE_PRIORITY_LOW`， `DISPATCH_QUEUE_PRIORITY_BACKGROUND` ，优先级依次降低。优先级越高的队列中的任务会更早执行：
    
    ```objectivec
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    ```
    
    当然我们也可以创建自己的并行队列：
    
    ```objectivec
    queue = dispatch_queue_create("com.example.MyQueue", DISPATCH_QUEUE_CONCURRENT);
    ```
    
    不过一般情况下我们使用系统提供的 Default 优先级的 queue 就足够了。
    
    **更新：**在 iOS8+ 和 OS X 10.10+ 中苹果引入了新的 QOS 类别，具体的几个类别如下：

    * `QOS_CLASS_USER_INTERACTIVE`
    * `QOS_CLASS_USER_INITIATED`
    * `QOS_CLASS_UTILITY`
    * `QOS_CLASS_BACKGROUND`

    在支持的平台上，推荐使用这几个类别对应的 queue，示例代码如下(Swift 2)：

    ```swift
let qualityOfServiceClass = QOS_CLASS_BACKGROUND
let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
dispatch_async(backgroundQueue, {
    print("This is run on the background queue")
       dispatch_async(dispatch_get_main_queue(), { () -> Void in
           print("This is run on the main queue, after the previous code in outer block")
        })
})
    ```
     
3. 主队列
    主队列可以通过 `dispatch_get_main_queue()` 获取：

    ```objectivec
     dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [imageVIew setImage:image];
        });
    ```

#### 自己创建的队列与系统队列有什么不同？

事实上，我们自己创建的队列，最终会把任务分配到系统提供的主队列和四个全局的并行队列上，这种操作叫做 Target queues。具体来说，我们创建的串行队列的 target queue 就是系统的主队列，我们创建的并行队列的 target queue 默认是系统 default 优先级的全局并行队列。所有放在我们创建的队列中的任务，最终都会到 target queue 中完成真正的执行。

那岂不是自己创建队列就没有什么意义了？其实不是的。通过我们自己创建的队列，以及 dispatch_set_target_queue 和 barrier 等操作，可以实现比较复杂的任务之间的同步，可以参考[这里](http://blog.csdn.net/growinggiant/article/details/41077221) 和 [这里](http://www.humancode.us/2014/08/14/target-queues.html)。

通常情况下，对于串行队列，我们应该自己创建，对于并行队列，就直接使用系统提供的 Default 优先级的 queue。

**注意：**对于 `dispatch_barrier` 系列函数来说，传入的函数应当是**自己创建的**并行队列，否则 barrier 将失去作用。详情请参考苹果文档。

#### 创建的 Queue 需要释放吗？
 
 在 iOS6 之前，使用 `dispatch_queue_create` 创建的 queue 需要使用 `dispatch_retain` 和 `dispatch_release` 进行管理，在 iOS 6 系统把 dispatch queue 也纳入了 ARC 管理的范围，就不需要我们进行手动管理了。使用这两个函数会导致报错。
 
 iOS6 上这个改变，把 dispatch queue 从原来的非 OC 对象（原生 C 指针），变成了 OC 对象，也带来了代码上的一些兼容性问题。在 iOS5 上需要使用 assign 来修饰 queue 对象：
 
 ```objectivec
 @property (nonatomic, assign) dispatch_queue_t queue;
 ```
 
 到 iOS6 以上就需要使用 strong 或者 weak 来修饰，不然会报错：
 
 ```objectivec
 @property (nonatomic, strong) dispatch_queue_t queue;
 ```
 
 当出现兼容性问题的时候，需要根据情况来修改代码，或者改变所 target 的 iOS 版本。
 
### 执行任务
 
 折腾了半天 queue，现在终于到了让 queue 真正去执行任务的阶段了。给 queue 添加任务有两种方式，同步和异步。同步方式会阻塞当前线程的执行，等待添加的任务执行完毕之后，才继续向下执行。异步方式不会阻塞当前线程的执行。
 
 ```objectivec
dispatch_queue_t myCustomQueue;
myCustomQueue = dispatch_queue_create("com.example.MyCustomQueue", NULL);

// 异步添加
dispatch_async(myCustomQueue, ^{
    printf("做一些工作\n");
});
 
printf("第一个 block 可能还没有执行\n");

// 同步添加
dispatch_sync(myCustomQueue, ^{
    printf("做另外一些工作\n");
});
printf("两个 block 都已经执行完毕\n");

 ```
 
#### 注意事项
 
 * 同步和异步添加，与队列是串行队列和并行队列没有关系。可以同步地给并行队列添加任务，也可以异步地给串行队列添加任务。同步和异步添加只影响是不是阻塞当前线程，和任务的串行或并行执行没有关系
    
* 如果在任务 block 中创建了大量对象，可以考虑在 block 中添加 autorelease pool。尽管每个 queue 自身都会有 autorelease pool 来管理内存，但是 pool 进行 drain 的具体时间是没办法确定的。如果应用对于内存占用比较敏感，可以自己创建 autorelease pool 来进行内存管理。

#### 关于线程安全

* Dispatch Queue 本身是线程安全的，换句话说，你可以从系统的任何一个线程给 queue 添加任务，不需要考虑加锁和同步问题
* 避免在任务中使用锁，如果使用锁的话可能会阻碍 queue 中其他 task 的运行
* 不建议获取 dispatch_queue 底层所使用的 thread 的有关信息，也不建议在 queue 中再使用 pthread 系函数

#### GCD 案例分析

##### 案例一

这是一个广为流传的例子，代码如下：

```objectivec
NSLog(@"1"); // 任务1
dispatch_sync(dispatch_get_main_queue(), ^{
    NSLog(@"2"); // 任务2
});
NSLog(@"3"); // 任务3
```

控制台输出

```
1
```

分析：

1. dispatch_sync 表示这是一个同步线程
2. dispatch_get_main_queue 表示其运行在主线程中的主队列
3. 任务2是同步线程的任务。

如图所示：

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/gcd-deadlock-1.png)

过程描述：

主线程启动以后的加入顺序是：任务1，同步线程，任务三。执行完任务1，就会启动同步线程，然后将任务2加入队列。所以，任务3在任务2的前面。如图中所示的那样，这种情况下 任务2 与 任务 3都在等待彼此完成之后才能执行，这就造成了死锁。

##### 案例二

这个例子由此前的案例一演化而来，代码如下：

```objectivec
NSLog(@"1"); // 任务1
dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    NSLog(@"2"); // 任务2
});
NSLog(@"3"); // 任务3
```

这并不会造成死锁，控制台输出如下：

```
1
2
3
```

如图所示：

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/gcd-deadlock-2.png)

分析与过程描述：

首先执行任务1，接下来会遇到一个同步线程，程序会进入等待。等待任务2执行完成以后，才能继续执行任务3。从 dispatch_get_global_queue 可以看出，任务2被加入到了全局的并行队列中，当并行队列执行完任务2以后，返回到主队列，继续执行任务3。

##### 案例三

这个例子会比此前的两节复杂一些，代码如下：

```objectivec
dispatch_queue_t queue = dispatch_queue_create("com.demo.serialQueue", DISPATCH_QUEUE_SERIAL);
NSLog(@"1"); // 任务1
dispatch_async(queue, ^{
    NSLog(@"2"); // 任务2
    dispatch_sync(queue, ^{
        NSLog(@"3"); // 任务3
    });
    NSLog(@"4"); // 任务4
});
NSLog(@"5"); // 任务5
```

控制台输出如下：

```
1
5
2
// 5和2的顺序不一定
```

分析：这里没有使用系统提供的串行或并行队列，而是自己通过dispatch_queue_create函数创建了一个`DISPATCH_QUEUE_SERIAL`的串行队列。

如图所示：

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/gcd-deadlock-3.png)

过程描述：

1. 执行任务1
2. 遇到异步线程，将【任务2、同步线程、任务4】加入串行队列。因为是异步线程，所以在主线程中的任务5不必等待异步线程中的所有任务完成
3. 因为任务5不必等待，所以2和5的输出顺序不能确定
4. 任务2执行完以后，遇到同步线程，这时，将任务3加入异步的串行队列
5. 又因为任务4比任务3早加入串行队列，所以，任务3要等待任务4完成以后，才能执行。但是任务3所在的同步线程会阻塞，所以任务4必须等任务3执行完以后再执行。这就又陷入了无限的等待中，造成死锁。

##### 案例四

代码如下：

```objectivec
NSLog(@"1"); // 任务1
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSLog(@"2"); // 任务2
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"3"); // 任务3
    });
    NSLog(@"4"); // 任务4
});
NSLog(@"5"); // 任务5
```

输出结果如下：

```
1
2
5
3
4
// 5和2的顺序不一定
```

如图所示：

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/gcd-deadlock-4.png)

分析与过程描述：

首先，将【任务1、异步线程、任务5】加入Main Queue中，异步线程中的任务是：【任务2、同步线程、任务4】。

所以，先执行任务1，然后将异步线程中的任务加入到Global Queue中，因为异步线程，所以任务5不用等待，结果就是2和5的输出顺序不一定。

然后再看异步线程中的任务执行顺序。任务2执行完以后，遇到同步线程。将同步线程中的任务加入到Main Queue中，这时加入的任务3在任务5的后面。

当任务3执行完以后，没有了阻塞，程序继续执行任务4。

从以上的分析来看，得到的几个结果：1最先执行；2和5顺序不一定；4一定在3后面。

##### 案例五

代码如下：

```objectivec
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    NSLog(@"1"); // 任务1
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSLog(@"2"); // 任务2
    });
    NSLog(@"3"); // 任务3
});
NSLog(@"4"); // 任务4
while (1) {
}
NSLog(@"5"); // 任务5
```

输出如下：

```
1
4
// 1和4的顺序不一定
```

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/gcd-deadlock-5.png)

分析与过程描述：

和上面几个案例的分析类似，先来看看都有哪些任务加入了Main Queue：【异步线程、任务4、死循环、任务5】。

在加入到Global Queue异步线程中的任务有：【任务1、同步线程、任务3】。

第一个就是异步线程，任务4不用等待，所以结果任务1和任务4顺序不一定。

任务4完成后，程序进入死循环，Main Queue阻塞。但是加入到Global Queue的异步线程不受影响，继续执行任务1后面的同步线程。

同步线程中，将任务2加入到了主线程，并且，任务3等待任务2完成以后才能执行。这时的主线程，已经被死循环阻塞了。所以任务2无法执行，当然任务3也无法执行，在死循环后的任务5也不会执行。

最终，只能得到1和4顺序不定的结果。

##### 案例总结

相信对于绝大多数人来说，在案例三开始，是否死锁以及整个的执行流程就变得不是那么显而易见了，这五个案例就意在展示 GCD 的问题：如果想要设置线程间的依赖关系，那就需要嵌套，如果嵌套就会导致一些复杂的事情发生。这应该是 GCD 的一个非常明显的缺陷之一了。

当然，NSOperation 为了我们提供了很方便设置依赖关系的解决方案。

## NSOperation 和 NSOperationQueue

虽然标题这么写，但是实际上 NSOperation 和 NSOperationQueue 并不一定要一起使用。NSOperation 本身是可以单独使用的，不过单独使用的话并不能体现出 NSOperation 的强大之处（从下面的部分你就能看出单独用 NSOperation 真的是做不了什么事情），通常还是使用 NSOperationQueue 来执行 NSOperation。

NSOperation 是一个抽象类，我们需要继承它并且实现我们的子类。

### 并发和非并发

首先看一下不使用 OperationQueue 的情况。

默认情况下 NSOperation 是非并发的，当我们像下面这样定义一个 operation:

```objectivec
@implementation MyOperation

-(void)main {
    NSLog(@"MyOperation Main Function");
}

@end
```

然后启动它： 

```objectivec
#import "MyOperation.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        MyOperation *op = [[MyOperation alloc] init];
        [op start];
        NSLog(@"Main Function");
    }
    return 0;
}
```

可以看到运行结果是：

    MyOperation Main Function
    Main Function
    
即整个 Operation 就是在当前的线程中以阻塞的形式执行的，当 operation 的 main 函数执行完毕之后，程序的控制权返回到主的 main 函数中。这样看来 operation 跟普通的一个函数调用就没有什么区别了。
 
对于并发的 Operation，要实现还是有点麻烦的，我们需要重载 start，isAsynchronous，isExecuting，isFinished 四个函数，同时还最好在 start 和 main 的实现中支持 cancel 操作。为什么要这么麻烦呢？因为对于一个并发的 Operation，调用者知道它什么时候开始，却不能知道它什么时候结束。在 NSOperation 的体系下，是通过 KVO 监测 isExecuting 和 isFinished 这几个变量，来监测 Operation 的完成状态的。出于兼容性的考虑（参考[这里](https://stackoverflow.com/questions/3573236/why-does-nsoperation-disable-automatic-key-value-observing)），我们还必须手动触发 KVO 通知。下面是一个示例：

```objectivec
#import "MyOperation.h"

@interface MyOperation()

@property (atomic, assign) BOOL _executing;
@property (atomic, assign) BOOL _finished;
@end

@implementation MyOperation

- (void)start;
{
    if ([self isCancelled])
    {
        // Move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        self._finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    self._executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
}

- (void)main;
{
    if ([self isCancelled]) {
        return;
    }
    sleep(10);
    NSLog(@"MyOperation Main Function");
    [self completeOperation];
}

- (BOOL)isAsynchronous;
{
    return YES;
}

- (BOOL)isExecuting {
    return self._executing;
}

- (BOOL)isFinished {
    return self._finished;
}

- (void)completeOperation {
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    self._executing = NO;
    self._finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}
@end
```

可以看到所谓的“并发”，跟上面的非并发并没有什么本质的不同，完全取决于我们的 start 函数是如何实现的。这里我们的 start 函数中把任务直接扔给了另外的线程，也就不会阻塞当前线程了。

废了这么大劲，我们如何执行这个 Operation 呢？如果再像上面一样使用 `[op start]` 直接执行的话，你会发现还没等到 Operation 返回我们的整个程序就已经结束掉了。因为我们的主程序并不会等到 operatoin 返回。想要等到 operation 返回，我们还需要手动地去监视 operation 的变量，然后等待它返回。。。

看到这里你就明白为什么单独使用 NSOperation 发挥不了太大的作用了，因为 NSOperation 本身确实是没有做什么工作，大部分东西还是要靠我们自己来控制。

这时候就需要 NSOperationQueue 登场了。

### 在 NSOperationQueue 中运行

NSOperationQueue 是一个专门用于执行 NSOperation 的队列。在 OS X 10.6 之后，把一个 NSOperation 放到 NSOperationQueue 中，queue 会忽略 isAsynchronous 变量，总是会把 operation 放到后台线程中执行。这样不管 operation 是不是异步的，queue 的执行都是不会造成主线程的阻塞的。使用 Queue 可以很方便地进行并发操作，并且帮我们完成大部分的监视 operation 是否完成的操作。接着用上面的 MyOperation 做例子，使用 NSOperationQueue 之后，我们就可以这样写：

```objectivec
MyOperation *op = [[MyOperation alloc] init];
NSOperationQueue *queue = [[NSOperationQueue alloc] init];

[queue addOperation:op];    // add 完 operation 就立即启动了
[queue waitUntilAllOperationsAreFinished]; // 阻塞当前线程，直到所有的 operation 全都完成
NSLog(@"Main Function");
```

像这样，我们可以添加各个各样的 operation 到 queue 中，只要这些 operation 都正确地重载了 isExecuting 和 isFinished，就可以正确地被并发执行。

除此之外，NSOperationQueue 还有几个很强大的特性。

#### Dependency

NSOperation 可以通过 addDependency 来依赖于其他的 operation 完成，如果有很多复杂的 operation，我们可以形成它们之间的依赖关系图，来实现复杂的同步操作：

```objectivec
[updateUIOperation addDependency: workerOperation];
```

#### Cancellation

NSOperation 有如下几种的运行状态：

- Pending
- Ready
- Executing
- Finished
- Canceled

除 Finished 状态外，其他状态均可转换为 Canceled 状态。

![](https://raw.githubusercontent.com/WiInputMethod/interview/master/img/ios-nsoperation-lifecycle.png)

当 NSOperation 支持了 cancel 操作时，NSOperationQueue 可以使用 cancelAllOperatoins 来对所有的 operation 执行 cancel 操作。不过 cancel 的效果还是取决于 NSOperation 中代码是怎么写的。比如 对于数据库的某些操作线程来说，cancel 可能会意味着 你需要把数据恢复到最原始的状态。

#### maxConcurrentOperationCount

默认的最大并发 operation 数量是由系统当前的运行情况决定的([来源](https://stackoverflow.com/questions/14995801/default-value-of-maxconcurrentoperationcount-for-nsoperationqueue))，我们也可以强制指定一个固定的并发数量。

#### Queue 的优先级

NSOperationQueue 可以使用 queuePriority 属性设置优先级，具体的优先级有下面几种：

```objectivec
typedef enum : NSInteger {
   NSOperationQueuePriorityVeryLow = -8,
   NSOperationQueuePriorityLow = -4,
   NSOperationQueuePriorityNormal = 0,
   NSOperationQueuePriorityHigh = 4,
   NSOperationQueuePriorityVeryHigh = 8
} NSOperationQueuePriority;
```

在 Queue 中优先级较高的会先执行。

**注1：**尽管系统会尽量使得优先级高的任务优先执行，不过并不能确保优先级高的任务一定会先于优先级低的任务执行，即优先级并不能保证任务的执行先后顺序。要先让一个任务先于另一个任务执行，需要使用设置dependency 来实现。

**注2：**同 NSOperation 一样，NSOperationQueue 也具有若干 QoS 选项可供选择。有关 QoS 配置的具体细节，例如当 NSOperation 和 NSOperationQueue 具有不同的 QoS 时出现的效果，以及如何改变 QoS 等，可以参考苹果官方文档 [Energy Efficiency Guide for iOS Apps
](https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/PrioritizeWorkWithQoS.html)。

## GCD 与 NSOperation 的对比

这是面试中经常会问到的一点，这两个都很常用，也都很强大。对比它们可以从下面几个角度来说：

* 首先要明确一点，NSOperationQueue 是基于 GCD 的更高层的封装，从 OS X 10.10 开始可以通过设置 `underlyingQueue` 来把 operation 放到已有的 dispatch queue 中。
* 从易用性角度，GCD 由于采用 C 风格的 API，在调用上比使用面向对象风格的 NSOperation 要简单一些。  
* 从对任务的控制性来说，NSOperation 显著得好于 GCD，和 GCD 相比支持了 Cancel 操作（注：在 iOS8 中 GCD 引入了 `dispatch_block_cancel` 和 `dispatch_block_testcancel`，也可以支持 Cancel 操作了），支持任务之间的依赖关系，支持同一个队列中任务的优先级设置，同时还可以通过 KVO 来监控任务的执行情况。这些通过 GCD 也可以实现，不过需要很多代码，使用 NSOperation 显得方便了很多。
* 从第三方库的角度，知名的第三方库如 AFNetworking 和 SDWebImage 背后都是使用 NSOperation，也从另一方面说明对于需要复杂并发控制的需求，NSOperation 是更好的选择（当然也不是绝对的，例如知名的 [Parse SDK](https://github.com/ParsePlatform/Parse-SDK-iOS-OSX) 就完全没有使用 NSOperation，全部使用 GCD，其中涉及到大量的 GCD 高级用法，[这里](https://github.com/ChenYilong/ParseSourceCodeStudy)有相关解析）。

#### 参考资料
 
 * http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues
 * http://www.humancode.us/2014/08/14/target-queues.html
 * http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
 * http://www.jianshu.com/p/0b0d9b1f1f19
 * http://www.cnblogs.com/tangbinblog/p/4133481.html
 * http://www.saitjr.com/ios/ios-gcd-deadlock.html

