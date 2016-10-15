**推荐首先阅读 [内存管理](../../basic/arch/Memory-Management.md) ** 

## Objective-C 中的内存分配

在 Objective-C 中，对象通常是使用 `alloc` 方法在堆上创建的。 `[NSObject alloc]` 方法会在对堆上分配一块内存，按照`NSObject`的内部结构填充这块儿内存区域。

一旦对象创建完成，就不可能再移动它了。因为很可能有很多指针都指向这个对象，这些指针并没有被追踪。因此没有办法在移动对象的位置之后更新全部的这些指针。



## MRC 与 ARC

Objective-C中提供了两种内存管理机制：MRC（MannulReference Counting）和 ARC(Automatic Reference Counting)，分别提供对内存的手动和自动管理，来满足不同的需求。现在苹果推荐使用 ARC 来进行内存管理。

### MRC 

#### 对象操作的四个类别

| 对象操作 |  OC中对应的方法 | 对应的 retainCount 变化 |
| -------------------- |:---------------:| :---------------:| 
| 生成并持有对象 | alloc/new/copy/mutableCopy等 | +1 |
| 持有对象 | retain | +1 |
| 释放对象 | release | -1 |
| 废弃对象 | dealloc | - |

**注意：**

* ~~这些对象操作的方法其实并不包括在OC中，而是包含在Cocoa框架下的Foundation框架中。~~[从 iOS 7 开始](https://developer.apple.com/library/content/releasenotes/General/iOS70APIDiffs/index.html)，这些方法被移动到了 Runtime 当中，可以在 [objc4-680 NSObject.h](http://opensource.apple.com/source/objc4/objc4-680/runtime/NSObject.h) 找到。
* 对象的 `reatinCount` 属性并没有实际上的参考价值，参考苹果官方文档[《Practical Memory Management》](https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmPractical.html).

#### 四个法则

- 自己生成的对象，自己持有。
- 非自己生成的对象，自己也能持有。
- 不在需要自己持有对象的时候，释放。
- 非自己持有的对象无需释放。

如下是四个黄金法则对应的代码示例：

```objectivec
/*
 * 自己生成并持有该对象
 */
 id obj0 = [[NSObeject alloc] init];
 id obj1 = [NSObeject new];
```

```objectivec
/*
 * 持有非自己生成的对象
 */
id obj = [NSArray array]; // 非自己生成的对象，且该对象存在，但自己不持有
[obj retain]; // 自己持有对象
```

```objectivec
/*
 * 不在需要自己持有的对象的时候，释放
 */
id obj = [[NSObeject alloc] init]; // 此时持有对象
[obj release]; // 释放对象
/*
 * 指向对象的指针仍就被保留在obj这个变量中
 * 但对象已经释放，不可访问
 */
```

```objectivec
/*
 * 非自己持有的对象无法释放
 */
id obj = [NSArray array]; // 非自己生成的对象，且该对象存在，但自己不持有
[obj release]; // ~~~此时将运行时crash 或编译器报error~~~ 非 ARC 下，调用该方法会导致编译器报 issues。此操作的行为是未定义的，可能会导致运行时 crash 或者其它未知行为
```

其中 `非自己生成的对象，且该对象存在，但自己不持有` 这个特性是使用`autorelease`来实现的，示例代码如下：

```objectivec
- (id) getAObjNotRetain {
    id obj = [[NSObject alloc] init]; // 自己持有对象
    [obj autorelease]; // 取得的对象存在，但自己不持有该对象
    return obj;
}
```

`autorelease` 使得对象在超出生命周期后能正确的被释放(通过调用release方法)。在调用 `release` 后，对象会被立即释放，而调用 `autorelease` 后，对象不会被立即释放，而是注册到 `autoreleasepool` 中，经过一段时间后 `pool`结束，此时调用release方法，对象被释放。

在MRC的内存管理模式下，与对变量的管理相关的方法有：retain, release 和 autorelease。retain 和 release 方法操作的是引用记数，当引用记数为零时，便自动释放内存。并且可以用 NSAutoreleasePool 对象，对加入自动释放池（autorelease 调用）的变量进行管理，当 drain 时回收内存。

### ARC 

ARC 是苹果引入的一种自动内存管理机制，会根据引用计数自动监视对象的生存周期，实现方式是在编译时期自动在已有代码中插入合适的内存管理代码以及在 Runtime 做一些优化。

#### 变量标识符

在ARC中与内存管理有关的变量标识符，有下面几种：

* `__strong`
* `__weak`
* `__unsafe_unretained`
* `__autoreleasing`

`__strong` 是默认使用的标识符。只有还有一个强指针指向某个对象，这个对象就会一直存活。

`__weak` 声明这个引用不会保持被引用对象的存活，如果对象没有强引用了，弱引用会被置为 nil

`__unsafe_unretained` 声明这个引用不会保持被引用对象的存活，如果对象没有强引用了，它不会被置为 nil。如果它引用的对象被回收掉了，该指针就变成了野指针。

`__autoreleasing` 用于标示使用引用传值的参数（id *），在函数返回时会被自动释放掉。

变量标识符的用法如下：

```objectivec
Number* __strong num = [[Number alloc] init];
``` 

注意 `__strong` 的位置应该放到 `*` 和变量名中间，放到其他的位置严格意义上说是不正确的，只不过编译器不会报错。

#### 属性标识符

类中的属性也可以加上标志符：

```objectivec
@property (assign/retain/strong/weak/unsafe_unretained/copy) Number* num
```

`assign `表明 setter 仅仅是一个简单的赋值操作，通常用于基本的数值类型，例如`CGFloat`和`NSInteger`。

`strong` 表明属性定义一个拥有者关系。当给属性设定一个新值的时候，首先这个值进行 `retain` ，旧值进行 `release` ，然后进行赋值操作。

`weak` 表明属性定义了一个非拥有者关系。当给属性设定一个新值的时候，这个值不会进行 `retain`，旧值也不会进行 `release`， 而是进行类似 `assign` 的操作。不过当属性指向的对象被销毁时，该属性会被置为nil。

`unsafe_unretained` 的语义和 `assign` 类似，不过是用于对象类型的，表示一个非拥有(unretained)的，同时也不会在对象被销毁时置为nil的(unsafe)关系。

`copy` 类似于 `strong`，不过在赋值时进行 `copy` 操作而不是 `retain` 操作。通常在需要保留某个不可变对象（NSString最常见），并且防止它被意外改变时使用。

##### 错误使用属性标识符的后果

如果我们给一个原始类型设置 `strong\weak\copy` ，编译器会直接报错：

> Property with 'retain (or strong)' attribute must be of object type

设置为 `unsafe_unretained` 倒是可以通过编译，只是用起来跟 `assign` 也没有什么区别。

反过来，我们给一个 NSObject 属性设置为 assign，编译器会报警：

> Assigning retained object to unsafe property; object will be released after assignment

正如警告所说的，对象在赋值之后被立即释放，对应的属性也就成了野指针，运行时跑到属性有关操作会直接崩溃掉。和设置成 `unsafe_unretained` 是一样的效果（设置成 `weak` 不会崩溃）。

##### `unsafe_unretained` 的用处

`unsafe_unretained` 差不多是实际使用最少的一个标识符了，在使用中它的用处主要有下面几点：

1. 兼容性考虑。iOS4 以及之前还没有引入 `weak`，这种情况想表达弱引用的语义只能使用 `unsafe_unretained`。这种情况现在已经很少见了。
2. 性能考虑。使用 `weak` 对性能有一些影响，因此对性能要求高的地方可以考虑使用 `unsafe_unretained` 替换 `weak`。一个例子是 [YYModel 的实现](https://github.com/ibireme/YYModel/blob/master/YYModel/NSObject%2BYYModel.m)，为了追求更高的性能，其中大量使用 `unsafe_unretained` 作为变量标识符。

### 引用循环

当两个对象互相持有对方的强引用，并且这两个对象的引用计数都不是0的时候，便造成了引用循环。

要想破除引用循环，可以从以下几点入手：

* 注意变量作用域，使用 `autorelease` 让编译器来处理引用
* 使用弱引用(weak)
* 当实例变量完成工作后，将其置为nil

### Autorelease Pool

Autorelase Pool 提供了一种可以允许你向一个对象延迟发送`release`消息的机制。当你想放弃一个对象的所有权，同时又不希望这个对象立即被释放掉（例如在一个方法中返回一个对象时），Autorelease Pool 的作用就显现出来了。

所谓的延迟发送`release`消息指的是，当我们把一个对象标记为`autorelease`时:

```objectivec
NSString* str = [[[NSString alloc] initWithString:@"hello"] autorelease];
```

这个对象的 retainCount 会+1，但是并不会发生 release。当这段语句所处的 autoreleasepool 进行 drain 操作时，所有标记了 `autorelease` 的对象的 retainCount 会被 -1。即 `release` 消息的发送被延迟到 pool 释放的时候了。

在 ARC 环境下，苹果引入了 `@autoreleasepool` 语法，不再需要手动调用 `autorelease` 和 `drain` 等方法。

#### Autorelease Pool 的用处

在 ARC 下，我们并不需要手动调用 autorelease 有关的方法，甚至可以完全不知道 autorelease 的存在，就可以正确管理好内存。因为 Cocoa Touch 的 Runloop 中，每个 runloop circle 中系统都自动加入了 Autorelease Pool 的创建和释放。

当我们需要创建和销毁大量的对象时，使用手动创建的 autoreleasepool 可以有效的避免内存峰值的出现。因为如果不手动创建的话，外层系统创建的 pool 会在整个 runloop circle 结束之后才进行 drain，手动创建的话，会在 block 结束之后就进行 drain 操作。详情请参考[苹果官方文档](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/MemoryMgmt/Articles/mmAutoreleasePools.html#//apple_ref/doc/uid/20000047-CJBFBEDI)。一个普遍被使用的例子如下：

```objectivec
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
* Pool 的 drain 操作会把所有标记为 autorelease 的对象的引用计数减一，但是并不意味着这个对象一定会被释放掉，我们可以在 autorelease pool 中手动 retain 对象，以延长它的生命周期（在 MRC 中）。

#### main.m 中 Autorelease Pool 的解释

大家都知道在 iOS 程序的 main.m 文件中有类似这样的语句：

```objectivec
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

在基于 AppKit 框架的 Mac OS 开发中， main.m 当中就是不存在 autorelease pool 的，也进一步验证了我们得到的结论。不过因为我们看不到更底层的代码，加上苹果的文档中不建议修改 main.m ，所以我们也没有理由就直接把它删掉（亲测，删掉之后不影响 App 运行，用 Instruments 也看不到泄露）。

#### Autorelease Pool 与函数返回值

如果一个函数的返回值是指向一个对象的指针，那么这个对象肯定不能在函数返回之前进行 release，这样调用者在调用这个函数时得到的就是野指针了，在函数返回之后也不能立刻就 release，因为我们不知道调用者是不是 retain 了这个对象，如果我们直接 release 了，可能导致后面在使用这个对象时它已经成为 nil 了。

为了解决这个纠结的问题， Objective-C 中对对象指针的返回值进行了区分，一种叫做 *retained return value*，另一种叫做 *unretained return value*。前者表示调用者拥有这个返回值，后者表示调用者不拥有这个返回值，按照“谁拥有谁释放”的原则，对于前者调用者是要负责释放的，对于后者就不需要了。

按照苹果的命名 convention，以 `alloc`, `copy`, `init`, `mutableCopy` 和 `new` 这些方法打头的方法，返回的都是 retained return value，例如 `[[NSString alloc] initWithFormat:]`，而其他的则是 unretained return value，例如 `[NSString stringWithFormat:]`。我们在编写代码时也应该遵守这个 convention。

我们分别在 MRC 和 ARC 情况下，分析一下两种返回值类型的区别。

##### MRC

在 MRC 中我们需要关注这两种函数返回类型的区别，否则可能会导致内存泄露。

*对于 retained return value，需要负责释放*

假设我们有一个 property 定义如下：

```objectivec
@property (nonatomic, retain) NSObject *property;
```

在对其赋值的时候，我们应该使用：

```objectivec
self.property = [[[NSObject alloc] init] autorelease];
```

然后在 dealloc 方法中加入：

```objectivec
[_property release];
_property = nil;
```

这样内存的情况大体是这样的：

1. init 把 retain count 增加到 1
2. 赋值给 self.property ，把 retain count 增加到 2
3. 当 runloop circle 结束时，autorelease pool 执行 drain，把 retain count 减为 1
4. 当整个对象执行 dealloc 时， release 把 retain count 减为 0，对象被释放

可以看到没有内存泄露发生。

如果我们只是使用：

```objectivec
self.property = [[NSObject alloc] init];
```

这一条语句会导致 retain count 增加到 2，而我们少执行了一次 release，就会导致 retain count 不能被减为 0 。

另外，我们也可以使用临时变量：

```objectivec
NSObject * a = [[NSObject alloc] init];
self.property = a;
[a release];
```

这种情况，因为对 a 执行了一次 release，所有不会出现上面那种 retain count 不能减为 0 的情况。

**注意**：现在大家基本都是 ARC 写的比较多，会忽略这一点，但是根据上面的内容，我们看到在 MRC 中直接对 self.proprety 赋值和先赋给临时变量，再赋值给 self.property，确实是有区别的！我在面试中就被问到这一点了。

我们在编写自己的代码时，也应该遵守上面的原则，同样是使用 autorelease：

```objectivec
// 注意函数名的区别
+ (MyCustomClass *) myCustomClass
{
    return [[[MyCustomClass alloc] init] autorelease]; // 需要 autorelease
}
- (MyCustomClass *) initWithName:(NSString *) name
{
	return [[MyCustomClass alloc] init]; // 不需要 autorelease
}
```

*对于 unretained return value，不需要负责释放*

当我们调用非 alloc，init 系的方法来初始化对象时（通常是工厂方法），我们不需要负责变量的释放，可以当成普通的临时变量来使用：

```objectivec
NSString *name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
self.name = name
// 不需要执行 [name release]
```

##### ARC

在 ARC 中我们完全不需要考虑这两种返回值类型的区别，ARC 会自动加入必要的代码，因此我们可以放心大胆地写：

```objectivec
self.property = [[NSObject alloc] init];
self.name = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
```

以及在自己写的函数中：

```objectivec
+ (MyCustomClass *) myCustomClass
{
    return [[MyCustomClass alloc] init]; // 不用 autorelease
}
```

这些写法都是 OK 的，也不会出现内存问题。

为了进一步理解 ARC 是如何做到这一点的，我们可以参考 Clang 的[文档](http://clang.llvm.org/docs/AutomaticReferenceCounting.html#unretained-return-values)。

对于 retained return value， Clang 是这样做的：

>When returning from such a function or method, ARC retains the value at the point of evaluation of the return statement, before leaving all local scopes.

>When receiving a return result from such a function or method, ARC releases the value at the end of the full-expression it is contained within, subject to the usual optimizations for local values.

可以看到基本上 ARC 就是帮我们在代码块结束的时候进行了 release：

```objectivec
NSObject * a = [[NSObject alloc] init];
self.property = a;
//[a release]; 我们不需要写这一句，因为 ARC 会帮我们把这一句加上
```

对于 unretained return value：

>When returning from such a function or method, ARC retains the value at the point of evaluation of the return statement, then leaves all local scopes, and then balances out the retain while ensuring that the value lives across the call boundary. In the worst case, this may involve an autorelease, but callers must not assume that the value is actually in the autorelease pool.

>ARC performs no extra mandatory work on the caller side, although it may elect to do something to shorten the lifetime of the returned value.

这个和我们之前在 MRC 中做的不是完全一样。ARC 会把对象的生命周期延长，确保调用者能拿到并且使用这个返回值，但是并不一定会使用 autorelease，文档写的是在 worst case 的情况下才可能会使用，因此调用者不能假设返回值真的就在 autorelease pool 中。从性能的角度，这种做法也是可以理解的。如果我们能够知道一个对象的生命周期最长应该有多长，也就没有必要使用 autorelease 了，直接使用 release 就可以。如果很多对象都使用 autorelease 的话，也会导致整个 pool 在 drain 的时候性能下降。

##### weak 与 autorelease

众所周知，weak 不会持有对象，当给一个 weak 赋以一个自己生成的对象（即上面提到的 retained return value）后，对象会立马被释放。

一个很常见的 warning 就是 Assigning retained object to weak variable, object will be released after assignment.

但是我们前面也提到了，可以持有非自己生成的对象，这通过 autorelease 实现。

那么如果一个 weak 被赋以一个非自己生成的对象（即上面提到的 unretained return value）呢？代码如下：

```objectivec
NSNumber __weak *number = [NSNumber numberWithInt:100];
NSLog(@"number = %@", number);
```

这种情况下是可以正确打印值的。

[clang的文档](http://clang.llvm.org/docs/AutomaticReferenceCounting.html#arc-runtime-objc-loadweak) 是这么说的：这种情况下，weak 并不会立即释放，而是会通过 `objc_loadWeak` 这个方法注册到 AutoreleasePool 中，以延长生命周期。


##### ARC 下是否还有必要在 dealloc 中把属性置为 nil？

为了解决这个问题，首先让我们理清楚属性是个什么存在。属性(property) 实际上就是一种语法糖，每个属性背后都有实例变量(Ivar)做支持，编译器会帮我们自动生成有关的 setter 和 getter，对于下面的 property：

```objectivec
@interface Counter : NSObject
@property (nonatomic, retain) NSNumber *count;
@end;
```

生成的 getter 和 setter 类似下面这样：

```objectivec
- (NSNumber *)count {
    return _count;
}
- (void)setCount:(NSNumber *)newCount {
    [newCount retain];
    [_count release];
    // Make the new assignment.
    _count = newCount;
}
```

Property 这部分对于 MRC 和 ARC 都是适用的。

有了这部分基础，我们再来理解一下把属性置为 nil 这个步骤。首先要明确一点，在 MRC 下，我们并不是真的把属性置为 nil，而是把 Ivar 置为 nil。

```objectivec
[_property release];
_property = nil;
```

如果用 self.property 的话还会调用 setter，里面可能存在某些不应该在 dealloc 时运行的代码。

对于 ARC 来说，系统会自动在 dealloc 的时候把所有的 Ivar 都执行 release，因此我们也就没有必要在 dealloc 中写有关 release 的代码了。

##### 在 ARC 下把变量置为 nil 有什么效果？什么情况下需要把变量置为 nil？

在上面有关 property 的内容基础上，我们知道用:

```objectivec
self.property = nil
```

实际上就是手动执行了一次 release。而对于临时变量来说：

```objectivec
NSObject *object = [[NSObject alloc] init];
object = nil;
```

置为 nil 这一句其实没什么用（除了让 object 在下面的代码里不能再使用之外），因为上面我们讨论过 ，ARC 下的临时变量是受到 Autorelease Pool 的管理的，会自动释放。

因为 ARC 下我们不能再使用 release 函数，把变量置为 nil 就成为了一种释放变量的方法。真正需要我们把变量置为 nil 的，通常就是在使用 block 时，用于破除循环引用：

```objectivec
MyViewController * __block myController = [[MyViewController alloc] init…];
// ...
myController.completionHandler =  ^(NSInteger result) {
    [myController dismissViewControllerAnimated:YES completion:nil];
    myController = nil;
};
```

在 [YTKNetwork](https://github.com/yuantiku/YTKNetwork) 这个项目中，也可以看到类似的代码：

```objectivec
- (void)clearCompletionBlock {
    // nil out to break the retain cycle.
    self.successCompletionBlock = nil;
    self.failureCompletionBlock = nil;
}
```

##### ARC 在运行时期的优化

上面提到对于 unretained return value， ARC “并不一定会使用 autorelease”，下面具体解释一下。

ARC 所做的事情并不仅仅局限于在编译期找到合适的位置帮你插入合适的 `release` 等等这样的内存管理方法，其在运行时期也做了一些优化，如下是两个优化的例子：

1. 合并对称的引用计数操作。比如将 +1/-1/+1/-1 直接置为 0.

2. 巧妙地跳过某些情况下 `autorelease` 机制的调用。

其中第二个优化，是 ARC 针对 `autorelease` 返回值提供的一套优化策略，大体的流程如下：

当方法全部基于 ARC 实现时，在方法 return 的时候，ARC 会调用 `objc_autoreleaseReturnValue()` 以替代 MRC 下的 `autorelease`。在 MRC 下需要 retain 的位置，ARC 会调用 `objc_retainAutoreleasedReturnValue()`。因此下面的 ARC 代码：

```objectivec
+ (instancetype)createSark {
    return [self new];
}
// caller
Sark *sark = [Sark createSark];
```

实际上会被改写成类似这样：

```objectivec
+ (instancetype)createSark {
    id tmp = [self new];
    return objc_autoreleaseReturnValue(tmp); // 代替我们调用autorelease
}
// caller
id tmp = objc_retainAutoreleasedReturnValue([Sark createSark]) // 代替我们调用retain
Sark *sark = tmp;
objc_storeStrong(&sark, nil); // 相当于代替我们调用了release
```

有了这个基础，ARC 可以使用一些优化技术。在调用 `objc_autoreleaseReturnValue()` 时，会在栈上查询 return address 以确定 return value 是否会被直接传给 `objc_retainAutoreleasedReturnValue()`。 如果没传，说明返回值不能直接从提供方发送给接收方，这时就会调用 `autorelease`。反之，如果返回值能顺利的从提供方传送给接收方，那么就会直接跳过 `autorelease` 过程，并且修改 return address 以跳过 `objc_retainAutoreleasedReturnValue()`过程，这样就跳过了整个 `autorelease` 和 `retain`的过程。

> **核心思想**：当返回值被返回之后，紧接着就需要被 retain 的时候，没有必要进行 autorelease + retain，直接什么都不要做就好了。

另外，当函数的调用方是非 ARC 环境时，ARC 还会进行更多的判断，在这里不再详述，详见 [《黑幕背后的 Autorelease》](http://blog.sunnyxx.com/2014/10/15/behind-autorelease/)。


### 关于如何写一个检测循环引用的工具

Instrument 为我们提供了 Allocations/Leaks 这样好用的工具用来检测 memory leak 的工具。如下是内存泄露的两种类型：

- Leaked memory: Memory unreferenced by your application that cannot be used again or freed (also detectable by using the Leaks instrument).

- Abandoned memory: Memory still referenced by your application that has no useful purpose.

其中 Leaks 工具主要用来检测 Leaked memory，在 MRC 时代 程序员会经常忘记写 release 方法导致内存泄露，在 ARC 时代这种已经不太常见。(ARC时代 主要的Leaked Memory 来自于底层 C 语言以及 一些由 C 写成的底层库，往往会因为忘记手工 free 而导致 leak )。

Allocations 工具主要用来检测 Abandoned memory. 主要思路是在一个时间切片内检测对象的声明周期以观察内存是否会无限增长。通过 hook 掉 alloc，dealloc，retain，release 等方法，来记录对象的生命周期。

### 参考资料

* [Objective-C内存管理MRC与ARC](http://blog.csdn.net/fightingbull/article/details/8098133)
* [10个Objective-C基础面试题，iOS面试必备](http://www.oschina.net/news/42288/10-objective-c-interview)
* [黑幕背后的 Autorelease](http://blog.sunnyxx.com/2014/10/15/behind-autorelease/)
* [Objective-C Autorelease Pool 的实现原理](http://blog.leichunfeng.com/blog/2015/05/31/objective-c-autorelease-pool-implementation-principle/)
* [How does objc_retainAutoreleasedReturnValue work?](http://www.galloway.me.uk/2012/02/how-does-objc_retainautoreleasedreturnvalue-work/)
* https://stackoverflow.com/questions/9784762/strong-weak-retain-unsafe-unretained-assign
* https://stackoverflow.com/questions/29350634/ios-autoreleasepool-in-main-and-arc-alloc-release
* https://stackoverflow.com/questions/6588211/why-do-the-ios-main-m-templates-include-a-return-statement-and-an-autorelease-po
* https://stackoverflow.com/questions/2702548/if-the-uiapplicationmain-never-returns-then-when-does-the-autorelease-pool-get
* https://stackoverflow.com/questions/6055274/use-autorelease-when-setting-a-retain-property-using-dot-syntax
* https://stackoverflow.com/questions/17601274/arc-and-autorelease
* https://stackoverflow.com/questions/8292060/arc-equivalent-of-autorelease
* https://stackoverflow.com/questions/7906804/do-i-set-properties-to-nil-in-dealloc-when-using-arc
* http://wereadteam.github.io/2016/02/22/MLeaksFinder/?from=singlemessage&isappinstalled=0
* http://clang.llvm.org/docs/AutomaticReferenceCounting.html#arc-runtime-objc-loadweak
