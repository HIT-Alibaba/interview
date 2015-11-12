
## iOS 网络编程

### Cocoa 网络编程

Cocoa 中网络编程层次结构分为三层，自上而下分别是：

* Cocoa 层：NSURL，Bonjour，Game Kit，WebKit
* Core Foundation 层：基于 C 的 CFNetwork 和 CFNetServices
* OS 层:基于 C 的 BSD socket

这里主要介绍处于 Cocoa 层的基于 NSURL 的一系列方法。

CoreFoundation 中提供了一个类 NSURLConnection ，用于处理用户的网络请求，NSURLConnection 基本可以满足我们大多数的网络请求操作。

#### 同步请求，使用 sendAsynchronousRequest 方法

```objective-c
+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(NSURLResponse **)response
                             error:(NSError **)error;

```

这个同步请求是阻塞的，并且不可以中途 cancel 掉。我们可以将同步请求放到主线程之外的线程中，执行效果也会类似于异步，比如放到 GCD 的 dispatch_async 里面执行。

#### 异步请求，使用 sendAsynchronousRequest

```objective-c
+ (void)sendAsynchronousRequest:(NSURLRequest*) request
                          queue:(NSOperationQueue*) queue
              completionHandler:(void (^)(NSURLResponse* response, NSData* data, NSError* connectionError)) handler;
```
这个异步请求是非阻塞的，异步执行后把结果通过 block 回调回来，不能中途 cancel 掉

#### 异步请求，使用委托

首先初始化请求：

```objective-c
- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;
```

然后根据需要在delegate类里面实现下列代理函数，获取异步请求的返回的数据与结果

```objective-c
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
```

这个异步请求是非阻塞的，异步执行后把返回的数据与结果通过 delegate 函数回调回来，可以使用 cancel 中途取消。

### 将请求放到后台线程

上面提到的 NSURLConnection 的异步方法实际上还是跑在主线程当中，尽管在网络连接过程中不会对主线程造成阻塞，但是 delegate 的回调方法还是在主线程中执行的。如果我们在回调方法中（特别是 completion 回调）中进行了大量的耗时操作，仍然会造成主线程的阻塞。我们可以让整个 NSURLConnection 都在后台线程中执行，这样就可以避免造成主线程的阻塞。

#### 怎么做？

简单地把`start`函数放到后台是不行的。像下面这样：


```objective-c
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self]; // 没有设置 startImmediately 为 NO，会立即开始
        //[connection start]; 这一句没有必要写，写了也一样不能 work。
    }); 
```

因为 dispatch_async 开出的线程中，默认 runloop 没有执行，因此线程会立即结束，来不及调用回调方法。我们可以添加代码让 runloop 跑起来：

```objective-c
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [[NSRunLoop currentRunLoop] run];
    }); 
```

这样回调函数才能够被调用，但是这样又带来一个问题，这个线程中 runloop 会一直跑着，导致这个线程也一直不结束，为了让线程在完成任务时正确结束掉，我们可以这样做：

```objective-c
dispatch_async(connectionQueue, ^{
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:[NSString stringWithFormat:someURL]]];

        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }); 
```

然后在 finish 回调中执行： 


```objective-c
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.finish = YES;
}
```

这样的实现实际上是有些 dirty 的，因为 开出的线程不受我们的控制，因此我们没办法实现任务的暂停，终止等操作。综合上面的讨论，看起来 GCD 并不适合和 NSURLConnection 一起工作。

除了 GCD 之外就没有别的办法了吗？幸好，苹果还提供了下面两种方法：

##### scheduleInRunLoop:forMode:

这个函数可以让我们指定 NSURLConnection 跑在某个 runloop：

``objective-c
NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
[runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode]; // 添加 inputSource，让 runloop 保持 alive
[self.connection scheduleInRunLoop:runLoop
                           forMode:NSDefaultRunLoopMode];   
[self.connection start];
[runLoop run];
```

这样，我们把它加到任意的有 Runloop 的线程中（其实 Cocoa 的线程都是自带 runloop 的，不过没有打开）都可以正常工作了，加到 NSOperationQueue 中也是可以的。

知名的开源网络库 AFNetworking 就是这么做的，代码参考[这里](https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLConnectionOperation.m#L157)。

注意一点，这样做的话， NSURLConnection 任务所在的线程是永远不会退出的，为了让它正确退出，后面会提到具体的做法。

##### setDelegateQueue:

更简单的方法是直接使用这个函数，直接使用 NSOperationQueue 来管理我们的 Connection：

```objective-c
NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:aURLRequest
                                                              delegate:self
                                                      startImmediately:NO];
[connection setDelegateQueue:[[NSOperationQueue alloc] init]];
[connection start];
```

如果我们不需要太多自定义功能，这个函数也完全够用了，不需要配置 runloop，不需要担心线程不会正常退出的问题，可以让我们专注于业务代码的编写。


注意上面提到的这两个函数只能取其中一个，如果同时用了两个会报错。

#### 优雅地退出

在上面的内容中我们探讨了如何让 NSURLConnection 保持运行而不提前退出，现在我们解决一下如何让 NSURLConnection 所在的线程正确的退出。

当我们使用 `scheduleInRunLoop:forMode:` 时，所在的线程会一直执行，想让它退出的话，最简单的方法是在回调中把 Runloop 取消掉：

```objective-c
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    CFRunLoopStop(CFRunLoopGetCurrent());
}
```

不过这样使用 CF 系函数的代码多少显得有些黑科技。使用 NSOperationQueue 我们可以有更加漂亮的做法。

NSOperationQueue 通过监测 `isExecuting`, `isCancelled` 和 `isFinished` 来控制下载任务的执行，具体的监测行为是通过 KVO 来实现的，因此我们可以手动调用 KVO 来通知 NSOperationQueue，告诉它“我们的任务执行完毕了，可以把线程关掉了”：

```objective-c
- (void)finish
{
    NSLog(@"operation for <%@> finished. "
          @"status code: %d, error: %@, data size: %u",
          _url, _statusCode, _error, [_data length]);

    [_connection release];
    _connection = nil;

    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];

    _isExecuting = NO;
    _isFinished = YES;

    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [self finish];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
    _error = [error copy];
    [self finish];
}

### 参考资料

* [[深入浅出Cocoa]iOS网络编程系列](http://blog.csdn.net/kesalin/article/details/8798039)
* [Cocoa网络编程总结之NSURLConnection](http://helloitworks.com/771.html)
* http://iosdevelopmentjournal.com/blog/2013/01/27/running-network-requests-in-the-background/
* https://stackoverflow.com/questions/8941353/ios-dispatch-async-and-nsurlconnection-delegate-functions-not-being-called/13733626#13733626
* https://satanwoo.github.io/2015/09/11/A-New-Start/
* https://stackoverflow.com/questions/1728631/asynchronous-request-to-the-server-from-background-thread
* https://stackoverflow.com/questions/1363787/is-it-safe-to-call-cfrunloopstop-from-another-thread
* http://www.dribin.org/dave/blog/archives/2009/05/05/concurrent_operations/
* http://nshipster.com/nsoperation/