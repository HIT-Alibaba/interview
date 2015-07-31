## Block 基础

### Block 语法

Block 可以认为是一种匿名函数，使用如下语法声明一个 Block 类型：

    return_type (^block_name)(parameters)


例如：

    double (^multiplyTwoValues)(double, double);

Block 字面值的写法如下：

    ^ (double firstValue, double secondValue) {
        return firstValue * secondValue;
    }

上面的写法省略了返回值的类型，也可以显式地指出返回值类型。

声明并且定义完一个Block之后，便可以像使用函数一样使用它：

```objective-c
double (^multiplyTwoValues)(double, double) =
                          ^(double firstValue, double secondValue) {
                              return firstValue * secondValue;
                          };
double result = multiplyTwoValues(2,4);

NSLog(@"The result is %f", result);
```

同时，Block 也是一种 Objective-C 对象，可以用于赋值，当做参数传递，也可以放入 NSArray 和 NSDictionary 中。

**注意**：当用于函数参数时，Block 应该放在参数列表的最后一个。

### Block 可以捕获外部变量

Block 可以来自外部作用域的变量，这是Block一个很强大的特性。

```objective-c
- (void)testMethod {
    int anInteger = 42;
    void (^testBlock)(void) = ^{
        NSLog(@"Integer is: %i", anInteger);
    };
    testBlock();
}
```


默认情况下，Block 中捕获的到变量是不能修改的，如果想修改，需要使用`__block`来声明：

```objective-c
__block int anInteger = 42;
```

**注意**： 使用 Block 在类中捕获`self`，以及类似的操作很容易造成强引用循环，因此使用 Block 时要格外注意。