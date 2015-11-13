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
    
    