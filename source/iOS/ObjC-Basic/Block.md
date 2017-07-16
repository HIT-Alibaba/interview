## Block 基础

### Block 语法

Block 可以认为是一种匿名函数，使用如下语法声明一个 Block 类型：

```objectivec
return_type (^block_name)(parameters)
```

例如：

```objectivec
double (^multiplyTwoValues)(double, double);
```

Block 字面值的写法如下：

```objectivec
^ (double firstValue, double secondValue) {
    return firstValue * secondValue;
}
```

上面的写法省略了返回值的类型，也可以显式地指出返回值类型。

声明并且定义完一个Block之后，便可以像使用函数一样使用它：

```objectivec
double (^multiplyTwoValues)(double, double) =
                          ^(double firstValue, double secondValue) {
                              return firstValue * secondValue;
                          };
double result = multiplyTwoValues(2,4);

NSLog(@"The result is %f", result);
```

同时，Block 也是一种 Objective-C 对象，可以用于赋值，当做参数传递，也可以放入 NSArray 和 NSDictionary 中。

**注意**：当用于函数参数时，Block 应该放在参数列表的最后一个。

---


**Bonus：** 由于 Block 的语法是如此的晦涩难记，以至于出现了 [fuckingblocksyntax](http://fuckingblocksyntax.com/) 这样的网站专门用于记录 block 的语法，翻译并摘录如下：

作为变量:

```objectivec
returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...};
```

作为属性:

```objectivec
@property (nonatomic, copy) returnType (^blockName)(parameterTypes);
```

作为函数声明中的参数:

```objective-c
- (void)someMethodThatTakesABlock:(returnType (^)(parameterTypes))blockName;
```

作为函数调用中的参数:

```objectivec
[someObject someMethodThatTakesABlock:^returnType (parameters) {...}];
```

作为 typedef:

```objectivec
typedef returnType (^TypeName)(parameterTypes);
TypeName blockName = ^returnType(parameters) {...};
```

### Block 可以捕获外部变量

Block 可以捕获来自外部作用域的变量，这是Block一个很强大的特性。

```objectivec
- (void)testMethod {
    int anInteger = 42;
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
    };
    testBlock();
}
```


默认情况下，Block 中捕获的到变量是不能修改的，如果想修改，需要使用`__block`来声明：

```objectivec
__block int anInteger = 42;
```

对于 id 类型的变量，在 MRC 情况下，使用 `__block id x` 不会 retain 变量，而在 ARC 情况下则会对变量进行 retain（即和其他捕获的变量相同）。如果不想在 block 中进行 retain 可以使用
`__unsafe_unretained __block id x`，不过这样可能会导致野指针出现。更好的办法是使用 `__weak` 的临时变量：

```objectivec
MyViewController *myController = [[MyViewController alloc] init…];
// ...
MyViewController * __weak weakMyViewController = myController;
myController.completionHandler =  ^(NSInteger result) {
    [weakMyViewController dismissViewControllerAnimated:YES completion:nil];
};
```

或者把使用 `__block` 修饰的变量设为 nil，以打破引用循环：

```objectivec
MyViewController * __block myController = [[MyViewController alloc] init…];
// ...
myController.completionHandler =  ^(NSInteger result) {
    [myController dismissViewControllerAnimated:YES completion:nil];
    myController = nil;
};
```

## Block 进阶

### 使用 Block 时的注意事项

在非 ARC 的情况下，对于 block 类型的属性应该使用 `copy` ，因为 block 需要维持其作用域中捕获的变量。在 ARC 中编译器会自动对 block 进行 copy 操作，因此使用 `strong` 或者 `copy` 都可以，没有什么区别，但是苹果仍然建议使用 `copy` 来指明编译器的行为。

block 在捕获外部变量的时候，会保持一个强引用，当在 block 中捕获 `self` 时，由于对象会对 block 进行 `copy`，于是便形成了强引用循环：

```objectivec
@interface XYZBlockKeeper : NSObject
@property (copy) void (^block)(void);
@end
```

```objectivec
@implementation XYZBlockKeeper
- (void)configureBlock {
    self.block = ^{
        [self doSomething];    // capturing a strong reference to self
                               // creates a strong reference cycle
    };
}
...
@end
```

为了避免强引用循环，最好捕获一个 `self` 的弱引用：

```objectivec
- (void)configureBlock {
    XYZBlockKeeper * __weak weakSelf = self;
    self.block = ^{
        [weakSelf doSomething];   // capture the weak reference
                                  // to avoid the reference cycle
    }
}
```

使用弱引用会带来另一个问题，`weakSelf` 有可能会为 nil，如果多次调用 `weakSelf` 的方法，有可能在 block 执行过程中 `weakSelf` 变为 nil。因此需要在 block 中将 `weakSelf` “强化“

```objectivec
__weak __typeof__(self) weakSelf = self;
NSBlockOperation *op = [[[NSBlockOperation alloc] init] autorelease];
[ op addExecutionBlock:^ {
    __strong __typeof__(self) strongSelf = weakSelf;
    [strongSelf doSomething];
    [strongSelf doMoreThing];
} ];
[someOperationQueue addOperation:op];
```

`__strong` 这一句在执行的时候，如果 WeakSelf 还没有变成 nil，那么就会 retain self，让 self 在 block 执行期间不会变为 nil。这样上面的 `doSomething` 和 `doMoreThing` 要么全执行成功，要么全失败，不会出现一个成功一个失败，即执行到中间 `self` 变成 nil 的情况。

#### Bonus

很多文章对于 weakSelf 的解释中并没有详细说，为什么有可能 block 执行的过程当中 weakSelf 变为 nil，这就涉及到 weak 本身的机制了。weak 置 nil 的操作发生在 dealloc 中，苹果在 [TN2109 - The Deallocation Problem](https://developer.apple.com/library/content/technotes/tn2109/_index.html#//apple_ref/doc/uid/DTS40010274-CH1-SUBSECTION11) 中指出，最后一个持有 object 的对象被释放的时候，会触发对象的 dealloc，而这个持有者的释放操作就不一定保证发生在哪个线程了。因此 block 执行的过程中 weakSelf 有可能在另外的线程中被置为 nil。

### Block 在堆上还是在栈上？

首先要指出，Block 在非 ARC 和 ARC 两种环境下的内存机制差别很大。

在 MRC 下，Block 默认是分配在栈上的，除非进行显式的 copy：

```objectivec
__block int val = 10;
blk stackBlock = ^{NSLog(@"val = %d", ++val);};
NSLog(@"stackBlock: %@", stackBlock); // stackBlock: <__NSStackBlock__: 0xbfffdb28>

tempBlock = [stackBlock copy];
NSLog(@"tempBlock: %@", tempBlock);  // tempBlock: <__NSMallocBlock__: 0x756bf20>
```

想把 Block 用作返回值的时候，也要加入 `copy` 和 `autorelease`：

```objectivec
- (blk)myTestBlock {
    __block int val = 10;
    blk stackBlock = ^{NSLog(@"val = %d", ++val);};
    return [[stackBlock copy] autorelease];
}
```

在 ARC 环境下，Block 使用简化了很多，同时 ARC 也更加倾向于把 Block 放到堆上：

```objectivec
__block int val = 10;
__strong blk strongPointerBlock = ^{NSLog(@"val = %d", ++val);};
NSLog(@"strongPointerBlock: %@", strongPointerBlock); // strongPointerBlock: <__NSMallocBlock__: 0x7625120>

__weak blk weakPointerBlock = ^{NSLog(@"val = %d", ++val);};
NSLog(@"weakPointerBlock: %@", weakPointerBlock); // weakPointerBlock: <__NSStackBlock__: 0xbfffdb30>

NSLog(@"mallocBlock: %@", [weakPointerBlock copy]); // mallocBlock: <__NSMallocBlock__: 0x714ce60>

NSLog(@"test %@", ^{NSLog(@"val = %d", ++val);}); // test <__NSStackBlock__: 0xbfffdb18>
```

可以看到只有显式的 `__weak` 以及纯匿名 Block 是放到栈上的，赋值给 `__strong` 指针（也就是默认赋值）都会导致在堆上创建 Block。

对于把 Block 作为函数返回值的情况，ARC 也能自动处理：

```objectivec
- (__unsafe_unretained blk) blockTest {
    int val = 11;
    return ^{NSLog(@"val = %d", val);};
}

NSLog(@"block return from function: %@", [self blockTest]); // block return from function: <__NSMallocBlock__: 0x7685640>
```

PS：经过上面的讨论，可以发现巧神的[这篇博客](http://blog.devtang.com/2013/07/28/a-look-inside-blocks/) 中认为在 ARC 情况下不再有 `NSConcreteStackBlock`，其实是不完全准确的。

#### 参考资料

* https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html#//apple_ref/doc/uid/TP40011210-CH8-SW16
* http://blog.waterworld.com.hk/post/block-weakself-strongself
* https://stackoverflow.com/questions/17384599/why-are-block-variables-not-retained-in-non-arc-environments
* https://stackoverflow.com/questions/2746197/dealloc-on-background-thread/24410372#24410372
* http://www.cnblogs.com/biosli/archive/2013/05/29/iOS_Objective-C_Block.html


