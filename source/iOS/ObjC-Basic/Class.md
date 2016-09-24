## 类方法

OC中类的方法只有实例方法和静态方法两种：

```objectivec
@interface Controller : NSObject

+ (void)thisIsAStaticMethod; // 静态方法

– (void)thisIsAnInstanceMethod; // 实例方法

@end
```

OC 中的方法只要声明在 @interface里，就可以认为都是公有的。实际上，OC 没有像 Java，C++ 中的那种绝对的私有及保护成员方法，仅仅可以对调用者隐藏某些方法。

声明和实现都写在 @implementation 里的方法，类的外部是看不到的。

可以使用 Category 来实现私有方法：

```objectivec
// AClass.h
@interface AClass : NSObject

-(void)sayHello;

@end

// AClass.m
@interface AClass (private)

-(void)privateSayHello;

@end

@implementation AClass

-(void)sayHello {
    [self privateSayHello];
}

-(void)privateSayHello {
    NSLog(@"Private Hello");
}
```

使用这种方法时，外部就不能直接调用到 `privateSayHello` 方法。

注意在上面的代码里面，当我们想通过 Category 来进行方法隐藏的时候，我们可以把实现放在主 implementation 里。当我们想扩展别的不能获取到源代码的类，或者想把不同 Category 的实现分开，可以新建 `<ClassName>+CategoryName.m` 文件，在里面进行实现：

```objectivec
#import "SystemClass+CategoryName.h"
 
@implementation SystemClass ( CategoryName )
// method definitions
@end
```

也可以使用 Extension 来实现私有方法：

```objectivec
// AClass.h 与上面相同

// AClass.m 
@interface AClass()

-(void)privateSayHello;

@end

@implementation AClass

-(void)sayHello {
    [self privateSayHello];
}

-(void)privateSayHello {
    NSLog(@"Private Hello");
}

@end
```

与使用 Category 类似，由于声明隐藏在 .m 中，调用者无法看到其声明，也就无法调用 `privateSayHello` 这个方法，会引发编译错误。

关于 Category 和 Extension 的一些区别，在[这里](#extension)。

## 类变量

苹果推荐在现代 Objective-C 中使用 `@property` 来实现成员变量：

```objectivec
@interface AClass : NSObject

@property (nonatomic, copy) NSString *name;

@end
```

使用 `@property` 声明的变量可以使用`实例名.变量名`来获取和修改。

`@property` 可以看做是一种语法糖，在 MRC 下，使用 `@property` 可以看成实现了下面的代码：

```objectivec
// AClass.h
@interface AClass : NSObject{
@public
    NSString *_name;
}

-(NSString*)name;
-(void)setName:(NSString*)newName;
@end

// AClass.m
@implementation AClass

-(NSString*)name{
    return _name;
}

-(void)setName:(NSString *)name{
    if (_name != name) {
        [_name release];
        _name = [name copy];
    }
}
@end
```

也就是说，`@property` 会自动生成 getter 和 setter， 同时进行自动内存管理。

`@property` 的属性可以有以下几种：

* readwrite 是可读可写特性；需要生成 getter 方法和 setter 方法
* readonly 是只读特性，只会生成 getter 方法 不会生成 setter 方法，不希望属性在类外改变时使用
* assign 是赋值特性，setter 方法将传入参数赋值给实例变量；仅设置变量时；
* retain 表示持有特性，setter 方法将传入参数先保留，再赋值，传入参数的 retain count 会+1;
* copy 表示拷贝特性，setter 方法将传入对象复制一份；需要完全一份新的变量时。
* nonatomic 和 atomic ，决定编译器生成的 setter getter是否是原子操作。 atomic 表示使用原子操作，可以在一定程度上保证线程安全。一般推荐使用 nonatomic ，因为 nonatomic 编译出的代码更快

默认的 `@property` 是 readwrite，assign，atomic。

 同时，我们还可以使用自己定义 accessor 的名字：

```objectivec
@property (getter=isFinished) BOOL finished;
```

这种情况下，编译器生成的 getter 方法名为 `isFinished`，而不是 `finished`。

### @synthesize 和 @dynamic

对于现代 OC 来说，在使用 `@property` 时， 编译器默认会进行自动 synthesize，生成 getter 和 setter，同时把 ivar 和属性绑定起来：

```objectivec
/// 现代 OC 不再需要手动进行下面的声明，编译器会自动处理
@synthesize propertyName = _propertyName
```

不需要我们写任何代码，就可以直接使用 getter 和 setter 了。

然而并不是所有情况下编译器都会进行自动 synthesize，具体由下面几种：

* 可读写(readwrite)属性实现了自己的 getter 和 setter
* 只读(readonly)属性实现了自己的 getter
* 使用 `@dynamic`，显式表示不希望编译器生成 getter 和 setter
* protocol 中定义的属性，编译器不会自动 synthesize，需要手动写
* 当重载父类中的属性时，也必须手动写 synthesize

## 类的扩展——Protocol, Category 和 Extension

### Protocol 

OC是单继承的，OC中的类可以实现多个 protocol 来实现类似 C++ 中多重继承的效果。

Protocol 类似 Java 中的 interface，定义了一个方法列表，这个方法列表中的方法可以使用 `@required`， `@optional` 标注，以表示该方法是否是客户类必须要实现的方法。 一个 protocol 可以继承其他的 protocol 。

```objectivec
@protocol TestProtocol<NSObject> // NSObject也是一个 Protocol，这里即继承 NSObject 里的方法
-(void)print;
@end

@interface B : NSObject<TestProtocol>
-(void)print; // 默认方法是 @required 的，即必须实现
@end

```

Delegate（委托）是 Cocoa 中常见的一种设计模式，其实现依赖于 protocol 这个语言特性。

#### 含有 property 的 Protocol

上面提到过，当 Protocol 中含有 property 时，编译器是不会进行自动 synthesize 的，需要手动处理：

```objectivec
@class ExampleClass;

@protocol ExampleProtocol

@required

@property (nonatomic, retain) ExampleClass *item;

@end
```

在实现这个 Protocol 的时候，要么再次声明 property：

```objectivec
@interface MyObject : NSObject <ExampleProtocol>

@property (nonatomic, retain) ExampleClass *item;

@end
```

要么进行手动 synthesize：

```objectivec
@interface MyObject : NSObject <ExampleProtocol>
@end

@implementation MyObject
@synthesize item;

@end
```

工程自带的 `AppDelegate` 使用了前一种方法，`UIApplicationDelegate` protocol 当中定义了 `window` 属性：

```objectivec
@property (nonatomic, retain) UIWindow *window NS_AVAILABLE_IOS(5_0);
```

在 `AppDelegate.h` 中我们可以看到再次对 `windows` 进行了声明：

```objectivec
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@end
```

### Category

Category 是一种很灵活的扩展原有类的机制，使用 Category 不需要访问原有类的代码，也无需继承。Category提供了一种简单的方式，来实现类的相关方法的模块化，把不同的类方法分配到不同的类文件中。

Category 常见的使用方法如下：

```objectivec
// SomeClass.h
@interface SomeClass : NSObject{
}
-(void)print;
@end 

// SomeClass+Hello.h
#import "SomeClass.h"
 
@interface SomeClass (Hello)
-(void)hello;
@end

// 实现
#import "SomeClass+Hello.h"
@implementationSomeClass (Hello)
-(void)hello{
    NSLog(@"name：%@ ", @"Jacky");
}
@end 
```

在使用 Category 时需要注意的一点是，如果有多个命名 Category 均实现了同一个方法（即出现了命名冲突），那么这些方法在运行时只有一个会被调用，具体哪个会被调用是不确定的。因此在给已有的类（特别是 Cocoa 类）添加 Category 时，推荐的函数命名方法是加上前缀：

```objectivec
@interface NSSortDescriptor (XYZAdditions)
+ (id)xyz_sortDescriptorWithKey:(NSString *)key ascending:(BOOL)ascending;
@end
```


### Extension

Extension 可以认为是一种匿名的 Category， Extension 与 Category 有如下几点显著的区别：

1. 使用 Extension 必须有原有类的源码
2. Extension 声明的方法必须在类的主 @implementation 区间内实现，可以避免使用有名 Category 带来的多个不必要的 implementation 段。
3. Extension 可以在类中添加新的属性和实例变量，Category 不可以（注：在 Category 中实际上可以通过运行时添加新的属性，下面会讲到）
4. <del>Extension 里添加的方法必须要有实现（没有实现编译器会给出警告）</del> 

>**注**：现代 ObjC 中 Extension 和 Category 中声明的方法如果没有实现编译器都会给出警告。

下面是一个 Extension 的例子：

```objectivec
@interface MyClass : NSObject  
- (float)value;  
@end  
              
@interface MyClass () { // 注意此处扩展的写法  
    float value;  
}  
- (void)setValue:(float)newValue;  
@end  
       
@implementation MyClass  
       
- (float)value {  
    return value;  
}  
       
- (void)setValue:(float)newValue {  
    value = newValue;  
}  
@end 
``` 

Extension 很常见的用法，是用来给类添加**私有**的变量和方法，用于在类的内部使用。例如在 interface 中定义为 `readonly` 类型的属性，在实现中添加 extension，将其重新定义为 `readwrite`，这样我们在类的内部就可以直接修改它的值，然而外部依然不能调用 `setter` 方法来修改。示例代码如下（来自苹果官方[文档](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/CustomizingExistingClasses/CustomizingExistingClasses.html#//apple_ref/doc/uid/TP40011210-CH6-SW3)）:

`XYZPerson.h`

```objectivec
@interface XYZPerson : NSObject
...
@property (readonly) NSString *uniqueIdentifier;

@end
```

`XYZPerson.m`

```objectivec
@interface XYZPerson ()
@property (readwrite) NSString *uniqueIdentifier;
@end

@implementation XYZPerson
...
@end
```

#### 如何给已有的类添加属性

首先强调一下上面例子中所展示的，Extension 可以给类添加属性，编译器会自动生成 getter，setter 和 ivar。 Category 并不支持这些。如果使用 Category 的话，类似下面这样：

```objectivec
@interface XYZPerson (UDID)
@property (readwrite) NSString *uniqueIdentifier;
@end

@implementation XYZPerson (UDID)
...
@end
```

尽管编译可以通过，但是当真正使用 `uniqueIdentifier` 时直接会导致程序崩溃。

如果我们手动去 synthesize 呢？像下面这样：

```objectivec
@implementation XYZPerson (UDID)
@synthesize uniqueIdentifier;
...
@end
```

然而这样做的话，代码直接报编译错误了：

`@synthesize not allowed in a category's implementation`

看来这条路是彻底走不通了。

不过我们还有别的方法，想通过 Category 添加属性的话，可以通过 Runtime 当中提供的 associated object 特性。NSHipster 的 [这篇文章](http://nshipster.cn/associated-objects/) 展示了具体的做法。

#### 如何在类中添加全局变量

有些时候我们需要在类中添加某个在类中全局可用的变量，为了避免污染作用域，一个比较好的做法是在 .m 文件中使用 static 变量：


```objectivec
static NSOperationQueue * _personOperationQueue = nil;

@implementation XYZPerson
...
@end
```

由于 static 变量在编译期就是确定的，因此对于 NSObject 对象来说，初始化的值只能是 nil。如何进行类似 init 的初始化呢？可以通过重载 initialize 方法来做：

```objectivec
@implementation XYZPerson
- (void)initialize {
    if (!_personOperationQueue) {
        _personOperationQueue = [[NSOperationQueue alloc] init];
    }
}
@end
```

为什么这里要判断是否为 nil 呢？因为 `initialize` 方法可能会调用多次，后面会提到。

如果是在 Category 中想声明全局变量呢？当然也可以通过 initialize，不过除非必须的情况下，并不推荐在 Category 当中进行方法重载。

有一种方法是声明 static 函数，下面的代码来自 [AFNetworking](https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLSessionManager.m)，声明了一个当前文件范围可用的队列：

```objectivec
static dispatch_queue_t url_session_manager_creation_queue() {
    static dispatch_queue_t af_url_session_manager_creation_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        af_url_session_manager_creation_queue = dispatch_queue_create("com.alamofire.networking.session.manager.creation", DISPATCH_QUEUE_SERIAL);
    });

    return af_url_session_manager_creation_queue;
}
```

下面介绍一个有点黑魔法的方法，除了上面两种方法之外，我们还可以通过编译器的 `__attribute__` 特性来实现初始化：

```objectivec
__attribute__((constructor))
static void initialize_Queue() {
    _personOperationQueue = [[NSOperationQueue alloc] init];
}

@implementation XYZPerson (Operation)

@end
```

## 类的导入

导入类可以使用 `#include` , `#import` 和 `@class` 三种方法，其区别如下：

* `#import`是Objective-C导入头文件的关键字，`#include`是C/C++导入头文件的关键字
* 使用`#import`头文件会自动只导入一次，不会重复导入，相当于`#include`和`#pragma once`；
* `@class`告诉编译器需要知道某个类的声明，可以解决头文件的相互包含问题；

`@class`是放在interface中的，只是在引用一个类，将这个被引用类作为一个类型使用。在实现文件中，如果需要引用到被引用类的实体变量或者方法时，还需要使用`#import`方式引入被引用类。

## 类的初始化

Objective-C 是建立在 Runtime 基础上的语言，类也不例外。OC 中类是初始化也是动态的。在 OC 中绝大部分类都继承自 `NSObject`，它有两个非常特殊的类方法 `load` 和 `initilize`，用于类的初始化

#### +load

+load 方法是当类或分类被添加到 Objective-C runtime 时被调用的，实现这个方法可以让我们在类加载的时候执行一些类相关的行为。子类的 +load 方法会在它的所有父类的 +load 方法之后执行，而分类的 +load 方法会在它的主类的 +load 方法之后执行。但是不同的类之间的 +load 方法的调用顺序是不确定的。

load 方法不会被类自动继承, 每一个类中的 load 方法都不需要像 viewDidLoad 方法一样调用父类的方法。子类、父类和分类中的 +load 方法的实现是被区别对待的。也就是说如果子类没有实现 +load 方法，那么当它被加载时 runtime 是不会去调用父类的 +load 方法的<sup id="fnref:ref"><a href="#fn:ref" class="footnote">1</a></sup>。同理，当一个类和它的分类都实现了 +load 方法时，两个方法都会被调用。因此，我们常常可以利用这个特性做一些“邪恶”的事情，比如说方法混淆（Method Swizzling）。FDTemplateLayoutCell 中就使用了这个方法，见[这里](https://github.com/forkingdog/UITableView-FDTemplateLayoutCell/blob/2bead7b80e40e8689201e7c1d6f034e952c9a155/Classes/UITableView%2BFDIndexPathHeightCache.m#L147)。

#### +initialize

+initialize 方法是在类或它的子类收到第一条消息之前被调用的，这里所指的消息包括实例方法和类方法的调用。也就是说 +initialize 方法是以懒加载的方式被调用的，如果程序一直没有给某个类或它的子类发送消息，那么这个类的 +initialize 方法是永远不会被调用的。

+initialize 方法的调用与普通方法的调用是一样的，走的都是发送消息的流程。换言之，如果子类没有实现 +initialize 方法，那么继承自父类的实现会被调用；如果一个类的分类实现了 +initialize 方法，那么就会对这个类中的实现造成覆盖。

### 注解

<li id="fn:ref">
<p> 1.举一个例子：有一个 Father 类，实现了 load 方法，打印类名，一个 Son 类继承自前者，没有实现 load 方法。实例出一个 Son 的对象时，结果是会输出父类的名字。但这个例子与之前的结论并不矛盾，这里说的是父类先被加载了，所以调用了父类的 load 方法，而子类被加载时没有调用父类的 load 方法。 暂时没找到例子可以严格的证明此前的结论，所以还是去看源码吧。<a href="#fnref:ref" class="reversefootnote">&#8617;</a></p>

### 参考资料

* [iOS开发基础面试题系列](http://blog.csdn.net/xunyn/article/details/8302787)
* [10个Objective-C基础面试题，iOS面试必备](http://www.oschina.net/news/42288/10-objective-c-interview)
* [Objective-C中“私有方法”的实现"](http://blog.sina.com.cn/s/blog_74e9d98d01013au8.html)
* [Objective-C中@property详解](http://www.cnblogs.com/andyque/archive/2011/08/03/2125728.html)
* [Objective-C中的protocol和delegate](http://www.cnblogs.com/whyandinside/archive/2013/02/28/2937217.html)
* [Objective-C——消息，Category 与 Protocol](http://www.cnblogs.com/chijianqiang/archive/2012/06/22/objc-category-protocol.html)
* [深入理解Objective-C中的@class](http://www.cnblogs.com/martin1009/archive/2012/06/24/2560218.html)
* [Objective-C +load vs +initialize](http://blog.leichunfeng.com/blog/2015/05/02/objective-c-plus-load-vs-plus-initialize/)
* [深入理解Objective-C：Category](http://tech.meituan.com/DiveIntoCategory.html)
* https://stackoverflow.com/questions/19784454/when-should-i-use-synthesize-explicitly
* http://www.fantageek.com/blog/2014/07/13/property-in-protocol/
* http://www.friday.com/bbum/2009/09/06/iniailize-can-be-executed-multiple-times-load-not-so-much/
