Runloop
=======

Runloop 是和线程紧密相关的一个基础组件，是很多线程有关功能的幕后功臣。尽管在平常使用中几乎不太会直接用到，理解 Runloop 有利于我们更加深入地理解 iOS 的多线程模型。

## Runloop 基本概念

Runloop 是什么？Runloop 还是比较顾名思义的一个东西，说白了就是一种循环，只不过它这种循环比较高级。一般的 while 循环会导致 CPU 进入忙等待状态，而 Runloop 则是一种“闲”等待，这部分可以类比 Linux 下的 epoll。当没有事件时，Runloop 会进入休眠状态，有事件发生时， Runloop 会去找对应的 Handler 处理事件。Runloop 可以让线程在需要做事的时候忙起来，不需要的话就让线程休眠。


盗一张苹果官方文档的图，也是几乎每个讲 Runloop 的文章都会引用的图，大体说明了 Runloop 的工作模式：

![Runloop](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Multithreading/Art/runloop.jpg)

图中展现了 Runloop 在线程中的作用：从 input source 和 timer source 接受事件，然后在线程中处理事件。

### Runloop 与线程

Runloop 和线程是绑定在一起的。每个线程（包括主线程）都有一个对应的 Runloop 对象。我们并不能自己创建 Runloop 对象，但是可以获取到系统提供的 Runloop 对象。

主线程的 Runloop 会在应用启动的时候完成启动，其他线程的 Runloop 默认并不会启动，需要我们手动启动。

### Input Source 和 Timer Source

这两个都是 Runloop 事件的来源，其中 Input Source 又可以分为三类

* Port-Based Sources，系统底层的 Port 事件，例如  CFSocketRef ，在应用层基本用不到
* Custom Input Sources，用户手动创建的 Source
* Cocoa Perform Selector Sources， Cocoa 提供的 performSelector 系列方法，也是一种事件源

Timer Source 顾名思义就是指定时器事件了。

### Runloop Observer

Runloop 通过监控 Source 来决定有没有任务要做，除此之外，我们还可以用 Runloop Observer 来监控 Runloop 本身的状态。 Runloop Observer 可以监控下面的 runloop 事件：

* The entrance to the run loop.
* When the run loop is about to process a timer.
* When the run loop is about to process an input source.
* When the run loop is about to go to sleep.
* When the run loop has woken up, but before it has processed the event that woke it up.
* The exit from the run loop.

### Runloop Mode

在监视与被监视中，Runloop 要处理的事情还挺复杂的。为了让 Runloop 能专心处理自己关心的那部分事情，引入了 Runloop Mode 概念。

![Runloop Mode](http://cc.cocimg.com/api/uploads/20150528/1432798883604537.png)

如图所示，Runloop Mode 实际上是 Source，Timer 和 Observer 的集合，不同的 Mode 把不同组的 Source，Timer 和 Observer 隔绝开来。Runloop 在某个时刻只能跑在一个 Mode 下，处理这一个 Mode 当中的 Source，Timer 和 Observer。

苹果文档中提到的 Mode 有五个，分别是：

* NSDefaultRunLoopMode
* NSConnectionReplyMode
* NSModalPanelRunLoopMode
* NSEventTrackingRunLoopMode
* NSRunLoopCommonModes

iOS 中公开暴露出来的只有 NSDefaultRunLoopMode 和 NSRunLoopCommonModes。 NSRunLoopCommonModes 实际上是一个 Mode 的集合，默认包括 NSDefaultRunLoopMode 和 NSEventTrackingRunLoopMode。

### 与 Runloop 相关的坑

日常开发中，与 runLoop 接触得最近可能就是通过 NSTimer 了。一个 Timer 一次只能加入到一个 RunLoop 中。我们日常使用的时候，通常就是加入到当前的 runLoop 的 default mode 中，而 ScrollView 在用户滑动时，主线程 RunLoop 会转到 UITrackingRunLoopMode 。而这个时候， Timer 就不会运行。

有如下两种解决方案：

- 第一种: 设置RunLoop Mode，例如NSTimer,我们指定它运行于 NSRunLoopCommonModes ，这是一个Mode的集合。注册到这个 Mode 下后，无论当前 runLoop 运行哪个 mode ，事件都能得到执行。
- 第二种: 另一种解决Timer的方法是，我们在另外一个线程执行和处理 Timer 事件，然后在主线程更新UI。

在 AFNetworking 3.0 中，就有相关的代码，如下：

```objectivec
- (void)startActivationDelayTimer {
    self.activationDelayTimer = [NSTimer
                                 timerWithTimeInterval:self.activationDelay target:self selector:@selector(activationDelayTimerFired) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.activationDelayTimer forMode:NSRunLoopCommonModes];
}
```

这里就是添加了一个计时器，由于指定了 NSRunLoopCommonModes，所以不管 RunLoop 出于什么状态，都执行这个计时器任务。


#### 参考资料

* https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html#//apple_ref/doc/uid/10000057i-CH16-SW1
* http://chun.tips/blog/2014/10/20/zou-jin-run-loopde-shi-jie-%5B%3F%5D-:shi-yao-shi-run-loop%3F/
* http://www.hrchen.com/2013/07/tricky-runloop-on-ios/
* http://www.cocoachina.com/ios/20150601/11970.html
* http://www.cocoachina.com/ios/20111111/3487.html
* http://mobile.51cto.com/iphone-386596.htm
* http://blog.ibireme.com/2015/05/18/runloop/
