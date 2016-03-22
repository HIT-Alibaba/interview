## 单例模式（Singleton）

单例模式是一种常见的设计模式，在 Cocoa 开发中也经常使用。

一个简单的单例模式示例代码如下：

```objectivec
/* Singleton.h */ 
#import "Foundation/Foundation.h"
@interface Singleton : NSObject 
+ (Singleton *)shardInstance; 
@end 
      
/* Singleton.m */ 
#import "Singleton.h" 
static Singleton *instance = nil; 
      
@implementation Singleton 
+ (Singleton *)sharedInstance { 
    if (!instance) { 
        instance = [[super allocWithZone:NULL] init]; 
    } 
    return instance; 
} 
```

Cocoa 库本身在一些地方也使用了单例模式，例如`[NSNotificationCenter defaultCenter]`，`[UIColor redColor]`等。

这种写法的优点是，可以延迟加载，按需分配内存以节省开销。

但是，这并非一个线程安全的写法，比如两个或多个线程并发的调用 `sharedInstance` 方法，有可能会得到多个实例，这里列出两种方法来创建一个线程安全的单例。

### @synchronized

可以使用@synchronized进行加锁，代码如下：

```objectivec
/* Singleton.h */
#import <Foundation/Foundation.h>
@interface Singleton : NSObject
+ (Singleton *)sharedInstance;
@end
/* Singleton.m */
#import "Singleton.h"
static Singleton *instance = nil;
@implementation Singleton 
+ (Singleton *)sharedInstance { 
    @synchronized (self) {
        if (!instance) { 
            instance = [[super alloc] init];
        } 
    }
    return instance; 
}
```

这种写法也是懒加载，不过虽然保证了线程安全但是由于锁的存在当多线程访问时，性能会降低。

### GCD

这里主要利用GCD中的dispatch_once方法，这是最普遍也是苹果最推荐的方法，函数原型如下：

```objectivec
void dispatch_once(
   dispatch_once_t *predicate,
   dispatch_block_t block);
```

单例实现代码如下：

```objectivec
/* Singleton.h */
#import <Foundation/Foundation.h>
@interface Singleton : NSObject
+ (Singleton *)sharedInstance;
@end
/* Singleton.m */
#import "Singleton.h"
static Singleton *instance = nil;
@implementation Singleton 
+ (Singleton *)sharedInstance { 
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        instance = [[Singleton alloc] init];
    });
    return instance; 
}
```

这样的方法有很多优势，首先满足了线程安全问题，其次很好满足静态分析器要求。

GCD 可以确保以更快的方式完成这些检测，它可以保证 block 中的代码在任何线程通过 dispatch_once 调用之前被执行，但它不会强制每次调用这个函数都让代码进行同步控制。

苹果的文档 [documentation for dispatch_once](https://developer.apple.com/library/ios/documentation/Performance/Reference/GCD_libdispatch_Ref/index.html#//apple_ref/c/func/dispatch_once) 是这么说的：

> The predicate must point to a variable stored in global or static scope. The result of using a predicate with automatic or dynamic storage (including Objective-C instance variables) is undefined.

所以，如果你的 predicate 不是静态的、不是全局的，还是不能用GCD。其实如果去看这个函数所在的头文件，你会发现目前它的实现其实是一个宏。

## 工厂模式（Factory）

工厂模式是另一种常见的设计模式，本质上是使用方法来简化类的选择和初始化过程。

下面是一个网上到处都是的简单工厂模式的例子：

```objectivec
//
//  OperationFactory.m
//  FactoryPattern

#import "OperationFactory.h"
#import "Operation.h"
#import "OperationAdd.h"
#import "OperationSub.h"
#import "OperationMul.h"
#import "OperationDiv.h"

@implementation OperationFactory

+ (Operation *) createOperat:(char)operate{
    Operation *oper = nil;
    switch (operate) {
        case '+':
        {
            oper = [[OperationAdd alloc] init];
            break;
        }
        case '-':
        {
            oper = [[OperationSub alloc] init];
            break;
        }
        case '*':
        {
            oper = [[OperationMul alloc] init];
            break;
        }
        case '/':
        {
            oper = [[OperationDiv alloc] init];
            break;
        }
        default:
            break;
    }
    return oper;
}
@end
```

由于 Objective-C 本身的动态特性，还可以用反射来改写：

```objectivec
@implementation OperationFactory
+ (Operation *) createOperat:(NSString *)operate{
    Operation *oper = nil;
    Class class = NSClassFromString(operate);
    oper = [(Operation *)[class alloc] init];
    if ([oper respondsToSelector:@selector(getResult)]) {
        [oper getResult];
    }
    return oper;
}
@end
```

使用时，可以传入类名，来获取对应类的对象：

```objectivec
Operation *oper = [OperationFactory createOperat: @"OperationAdd"];
oper.numberA = 10;
oper.numberB = 20;
NSLog(@"%f", oper.getResult);
```

## 委托模式（Delegate）

委托模式是 Cocoa 中十分常见的设计模式，在 Cocoa 库中被大量的使用。在 Objective-C 中，委托模式通常使用协议（protocol）来实现。

委托模式的示例代码：

```objectivec
@protocol PrintDelegate <NSObject>
- (void)print;
@end


@interface AClass : NSObject<PrintDelegate>
@property id<PrintDelegate> delegate;
@end

@implementation AClass

-(void)sayHello {
    [self.delegate print];
}

-(void)print {
    NSLog(@"Do Print");
}
@end

// 使用 AClass
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        AClass * a = [AClass new];
        a.delegate = a;
        [a sayHello];
    }
    return 0;
}
```

这里对象a的 delegate 设置为自己，也可以是任何一个实现了 `PrintDelegate` 协议的对象。

## 观察者模式（Observer）

Cocoa 中提供了两种用于实现观察者模式的办法，一直是使用`NSNotification`，另一种是`KVO(Key Value Observing)`。

### NSNotification

`NSNotification` 基于 Cocoa 自己的消息中心组件 `NSNotificationCenter` 实现。

观察者需要统一在消息中心注册，说明自己要观察哪些值的变化。观察者通过类似下面的函数来进行注册：

```objectivec
[[NSNotificationCenter defaultCenter] addObserver:self
				         selector:@selector(printName:)
				             name: @"messageName"
				           object:nil];
```

上面的函数表明把自身注册成 "messageName" 消息的观察者，当有消息时，会调用自己的 `printName` 方法。

消息发送者使用类似下面的函数发送消息：

```objectivec
[[NSNotificationCenter defaultCenter] postNotificationName:@"messageName"
				                    object:nil
				                  userInfo:nil];
```

### KVO(Key Value Observing)

KVO的实现依赖于 Objective-C 本身强大的 KVC(Key Value Coding) 特性，可以实现对于某个属性变化的动态监测。

示例代码如下：

```objectivec
// Book类
@interface Book : NSObject

@property NSString *name;
@property CGFloat price;

@end
  
// AClass类
@class Book;
@interface AClass : NSObject

@property (strong) Book *book;

@end

@implementation AClass

- (id)init:(Book *)theBook {
    if(self = [super init]){
        self.book = theBook;
        [self.book addObserver:self forKeyPath:@"price" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    if([keyPath isEqual:@"price"]){
        NSLog(@"------price is changed------");
        NSLog(@"old price is %@",[change objectForKey:@"old"]);
        NSLog(@"new price is %@",[change objectForKey:@"new"]);
    }
}

- (void)dealloc{
    [self.book removeObserver:self forKeyPath:@"price"];
}
@end

// 使用 KVO
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Book *aBook = [Book new];
        aBook.price = 10.9;
        AClass * a = [[AClass alloc] init:aBook];
        aBook.price = 11; // 输出 price is changed
    }
    return 0;
}
```


### 参考资料

* [Objective-C中的单例模式](http://arthurchen.blog.51cto.com/2483760/642536/)
* [iPhone开发笔记——简单工厂模式](http://blog.sina.com.cn/s/blog_58af95150101m362.html)
* [详解Objective-C中的委托和协议](http://mobile.51cto.com/iphone-283416.htm)
* [Objective-C中Observer模式的实现](http://blog.csdn.net/zshtiger2414/article/details/6409695)
* [Objective-C KVO编程](http://blog.csdn.net/kindazrael/article/details/7961601)
* [iOS开发系列——Objective-C开发之KVC，KVO](http://www.cnblogs.com/kenshincui/p/3871178.html)