

# Cocoa 网络编程

Cocoa 中网络编程层次结构分为三层，自上而下分别是：

* Cocoa 层：NSURL，Bonjour，Game Kit，WebKit
* Core Foundation 层：基于 C 的 CFNetwork 和 CFNetServices
* OS 层:基于 C 的 BSD socket

这里主要介绍处于 Cocoa 层的基于 NSURL 的一系列方法。在 iOS7 之前，主要使用的网络编程 API 是 NSURLConnection 一族的类，在 iOS7 之后苹果引入了 NSURLSession 类族，用于替代 NSURLConnection。

**注意：在 Xcode 7 / iOS 9.0 中苹果正式废弃了 NSURLConnection 系列 API，并建议开发者尽快迁移到 NSURLSession。因此下面有关 NSURLConnection 的内容仅作为参考使用。**

## NSURLConnection

CoreFoundation 中提供了一个类 NSURLConnection ，用于处理用户的网络请求，NSURLConnection 基本可以满足我们大多数的网络请求操作。NSURLConnection 本身并不能单独使用，需要与一族网络通信有关的类进行协同工作，包括 NSURLRequest, NSURLResponse，NSURLCache 等等。

### 基本的请求操作

#### 同步请求，使用 sendAsynchronousRequest 方法

```objectivec
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(NSURLResponse **)response
                             error:(NSError **)error;

```

这个同步请求是阻塞的，并且不可以中途 cancel 掉。我们可以将同步请求放到主线程之外的线程中，执行效果也会类似于异步，比如放到 GCD 的 dispatch_async 里面执行。

#### 异步请求，使用 sendAsynchronousRequest

```objectivec
+ (void)sendAsynchronousRequest:(NSURLRequest*) request
                          queue:(NSOperationQueue*) queue
              completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;
```
这个异步请求是非阻塞的，异步执行后把结果通过 block 回调回来，不能中途 cancel 掉

#### 异步请求，使用委托

首先初始化请求：

```objectivec
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;
```

然后根据需要在 delegate 类(NSURLConnectionDataDelegate协议)里面实现下列代理函数，获取异步请求的返回的数据与结果

```objectivec
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
```

这个异步请求是非阻塞的，异步执行后把返回的数据与结果通过 delegate 函数回调回来，可以使用 cancel 中途取消。

### 将请求放到后台线程

上面提到的 NSURLConnection 的异步方法实际上还是跑在主线程当中，在主线程中执行网络操作会带来两个问题：

1. 尽管在网络连接过程中不会对主线程造成阻塞，但是 delegate 的回调方法还是在主线程中执行的。如果我们在回调方法中（特别是 completion 回调）中进行了大量的耗时操作，仍然会造成主线程的阻塞。
2. NSURLConnection 默认会跑在当前的 runloop 中，并且跑在 Default Mode，当用户执行滚动的 UI 操作时会发生 runloop mode 的切换，也就导致了 NSURLConnection 不能及时执行和完成回调。

为了解决这些问题，我们可以让整个 NSURLConnection 都在后台线程中执行。

#### 怎么做？

简单地把`start`函数放到后台的 queue 中是不行的，像下面这样：


```objectivec
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; // 没有设置 startImmediately 为 NO，会立即开始
        //[connection start]; 这一句没有必要写，写了也一样不能 work。
});
```

因为 dispatch_async 开出的线程中，默认 runloop 没有执行，因此线程会立即结束，来不及调用回调方法。我们可以添加代码让 runloop 跑起来：

```objectivec
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [[NSRunLoop currentRunLoop] run];
});
```

这样回调函数才能够被调用，但是这样又带来一个问题，这个线程中 runloop 会一直跑着，导致这个线程也一直不结束，为了让所在线程在完成任务时正确释放掉，我们可以这样做：

```objectivec
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        while(!self.finished) {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        }
    }); 
```

然后在 finish 回调中执行： 


```objectivec
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.finish = YES;
}
```

这样的实现实际上是有些 dirty 的，引入了一个死循环来判断是否应该终止 loop。看起来 GCD 并不适合和 NSURLConnection 一起工作。

除了 GCD 之外就没有别的办法了吗？幸好，苹果还提供了下面两种方法：

##### scheduleInRunLoop:forMode:

这个函数可以让我们指定 NSURLConnection 跑在某个 runloop：

```objectivec
NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode]; // 添加 inputSource，让 runloop 保持 alive
[self.connection scheduleInRunLoop:runLoop
                           forMode:NSDefaultRunLoopMode];   
[self.connection start];
[runLoop run];
```

这样，我们把它加到任意的有 Runloop 的线程中（其实 Cocoa 的线程都是自带 runloop 的，不过没有打开）都可以正常工作了，加到 NSOperationQueue 中也是可以的。

知名的开源网络库 AFNetworking 就是这么做的，代码参考[这里](https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLConnectionOperation.m#L157)。

注意一点，这样做的话， NSURLConnection 任务所在的线程是永远不会退出的，为了让它正确退出，可以在请求完成时结束掉 runloop：

```objectivec
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}
```

AFNetworking 中负责响应回调的线程，就是通过 Runloop 来保持永不退出的，一直在后台负责响应回调。

##### setDelegateQueue:

更简单的方法是直接使用这个函数，直接使用 NSOperationQueue 来管理我们的 Connection：

```objectivec
NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:aURLRequest
                                                              delegate:self
                                                      startImmediately:NO];
[connection setDelegateQueue:[[NSOperationQueue alloc] init]];
[connection start];
```

如果我们不需要太多自定义功能，这个函数也完全够用了，不需要配置 runloop，不需要担心线程不会正常退出的问题，可以让我们专注于业务代码的编写。

注意上面提到的这两个函数只能取其中一个，如果同时用了两个会报错。


## NSURLSession

 http://objccn.io/issue-5-4/
 
### 参考资料

* [[深入浅出Cocoa]iOS网络编程系列](http://blog.csdn.net/kesalin/article/details/8798039)
* [Cocoa网络编程总结之NSURLConnection](http://helloitworks.com/771.html)
* http://iosdevelopmentjournal.com/blog/2013/01/27/running-network-requests-in-the-background/
* https://stackoverflow.com/questions/8941353/ios-dispatch-async-and-nsurlconnection-delegate-functions-not-being-called/13733626#13733626
* https://satanwoo.github.io/2015/09/11/A-New-Start/
* https://stackoverflow.com/questions/1728631/asynchronous-request-to-the-server-from-background-thread
* https://stackoverflow.com/questions/1363787/is-it-safe-to-call-cfrunloopstop-from-another-thread
* http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
* http://nshipster.com/nsoperation/```objectivec