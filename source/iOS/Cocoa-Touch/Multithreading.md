iOS 中的多线程，是 Cocoa 框架下的多线程，通过 Cocoa 的封装，可以让我们更为方便的进行多线程编程。

在介绍 Cocoa 并发编程之前，我们先理清会提到的几个术语：

* 线程：就是我们通常提到的线程，在进程中可以用线程去执行一些主进程之外的代码。OS X 中线程的实现基于 POSIX 的 pthread API。
* 进程：也是我们通常意义上提到的进程，一个正在执行中的程序实体，可以产生多个线程
* 任务：一个抽象的概念，用于表示一系列需要完成的工作

Cocoa 中封装了 NSThread, NSOperation, GCD 三种多线程编程方式，他们各有优缺点。抽象层次是从低到高的，抽象度越高的使用越简单。

* NSThread

    NSThread 是一个控制线程执行的对象，通过它我们可以方便的得到一个线程并控制它。NSThread 的线程之间的并发控制，是需要我们自己来控制的，可以通过 NSCondition 实现。它的缺点是需要自己维护线程的生命周期和线程的同步和互斥等，优点是轻量，灵活。

* NSOperation

    NSOperation 是一个抽象类，它封装了线程的细节实现，不需要自己管理线程的生命周期和线程的同步和互斥等。只是需要关注自己的业务逻辑处理，需要和 NSOperationQueue 一起使用。

* GCD

    GCD(Grand Central Dispatch) 是 Apple 开发的一个多核编程的解决方法。在 iOS4.0 开始之后才能使用。GCD 是一个替代诸如 NSThread, NSOperationQueue, NSInvocationOperation 等技术的很高效和强大的技术。


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
    
    ```objective-c
    dispatch_queue_t queue;
    queue = dispatch_queue_create("com.example.MyQueue", NULL); // OS X 10.7 和 iOS 4.3 之前
    queue = dispatch_queue_create("com.example.MyQueue",  DISPATCH_QUEUE_SERIAL); // 之后
    ```
    
2. 并行队列
    系统默认提供了四个全局可用的并行队列，其优先级不同，分别为 DISPATCH_QUEUE_PRIORITY_HIGH，DISPATCH_QUEUE_PRIORITY_DEFAULT， DISPATCH_QUEUE_PRIORITY_LOW， DISPATCH_QUEUE_PRIORITY_BACKGROUND ，优先级依次降低。优先级越高的队列中的任务会更早执行：
    
    ```objective-c
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    ```
    
    当然我们也可以创建自己的并行队列：
    
    ```objective-c
    queue = dispatch_queue_create("com.example.MyQueue", DISPATCH_QUEUE_CONCURRENT);
    ```
    
    不过一般情况下我们使用系统提供的 Default 优先级的 queue 就足够了。
     
3. 主队列
    主队列可以通过 `dispatch_get_main_queue()` 获取：

    ```objective-c
     dispatch_async(dispatch_get_main_queue(), ^{
            // Update the UI
            [imageVIew setImage:image];
        });
    ```

 #### 自己创建的队列与系统队列有什么不同？

事实上，我们自己创建的队列，最终会把任务分配到系统提供的主队列和四个全局的串行队列上，这种操作叫做 Target queues。具体来说，我们创建的串行队列的 target queue 就是系统的主队列，我们创建的并行队列的 target queue 默认是系统 default 优先级的全局串行队列。所有放在我们创建的队列中的任务，最终都会到 target queue 中完成真正的执行。

那岂不是自己创建队列就没有什么意义了？其实不是的。通过我们自己创建的队列，以及 dispatch_set_target_queue 和 barrier 等操作，可以实现比较复杂的任务之间的同步，可以参考[这里](http://blog.csdn.net/growinggiant/article/details/41077221) 和 [这里](http://www.humancode.us/2014/08/14/target-queues.html)。

通常情况下，对于串行队列，我们应该自己创建，对于并行队列，就直接使用系统提供的 Default 优先级的 queue。
 
 #### 创建的 Queue 需要释放吗？
 
 在 iOS6 之前，使用 `dispatch_queue_create` 创建的 queue 需要使用 `dispatch_retain` 和 `dispatch_release` 进行管理，在 iOS 6 系统把 dispatch queue 也纳入了 ARC 管理的范围，就不需要我们进行手动管理了。使用这两个函数会导致报错。
 
 iOS6 上这个改变，把 dispatch queue 从原来的非 OC 对象（原生 C 指针），变成了 OC 对象，也带来了代码上的一些兼容性问题。在 iOS5 上需要使用 assign 来修饰 queue 对象：
 
 ```objective-c
 @property (nonatomic, assign) dispatch_queue_t queue;
 ```
 
 到 iOS6 上就需要使用 strong 或者 weak 来修饰：
 
 ```objective-c
 @property (nonatomic, strong) dispatch_queue_t queue;
 ```
 
 当出现兼容性问题的时候，需要根据情况来修改代码或者改变 target 的 iOS 版本。
 
 ### 执行任务
 
 折腾了半天 queue，现在终于到了让 queue 真正去执行任务的阶段了。给 queue 添加任务有两种方式，同步和异步。同步方式会阻塞当前线程的执行，等待添加的任务执行完毕之后，才继续向下执行。异步方式不会阻塞当前线程的执行。
 
 ```objective-c
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
 * 不要使用 dispatch_sync 给当前正在运行的 queue 添加任务！这样会导致死锁，像下面这样：
 
    ```objective-c
    - (void)viewDidLoad
    {
        [super viewDidLoad];
        NSLog(@"1");
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"2");
        });
        NSLog(@"3");
    }
    ```
    
    这样只有 1 会被输出，之后程序就被死锁掉了。
    
    死锁的原因是，dispatch_sync 会做两个工作，一个是阻塞掉当前线程，另一个是把任务添加到 queue 中，等待任务执行完毕。像上面这样，主线程被阻塞掉了，任务不能被执行，然后导致 dispatch_sync 永远不能等待到任务执行完毕，就不能释放主线程的阻塞，于是就产生了死锁。
    
* 如果在任务 block 中创建了大量对象，可以考虑在 block 中添加 autorelease pool。尽管每个 queue 自身都会有 autorelease pool 来管理内存，但是 pool 进行 drain 的具体时间是没办法确定的。如果应用对于内存占用比较敏感，可以自己创建 autorelease pool 来进行内存管理。
    
    
## NSOperation 和 NSOperationQueue

 #### 参考资料
 
 * http://www.raywenderlich.com/19788/how-to-use-nsoperations-and-nsoperationqueues
 * http://www.humancode.us/2014/08/14/target-queues.html