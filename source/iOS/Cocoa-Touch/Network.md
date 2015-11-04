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

### 参考资料

* [[深入浅出Cocoa]iOS网络编程系列](http://blog.csdn.net/kesalin/article/details/8798039)
* [Cocoa网络编程总结之NSURLConnection](http://helloitworks.com/771.html)