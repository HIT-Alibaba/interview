## Core Animation

**注**：示例中部分代码的完整版可以在[这里](https://github.com/yixiangboy/IOSAnimationDemo)找到。

### UIView Animation

#### 简单动画

对于 UIView 上简单的动画，iOS 提供了很方便的函数：

    + animateWithDuration:animations:
 
第一个参数是动画的持续时间，第二个参数是一个 block，在 `animations` block 中对 UIView 的属性进行调整，设置 UIView 动画结束后最终的效果，iOS 就会自动补充中间帧，形成动画。

可以更改的属性有:

* frame
* bounds
* center
* transform
* alpha
* backgroundColor
* contentStretch

这些属性大都是 View 的基本属性，下面是一个例子，这个例子中的动画会同时改变 View 的 `frame`，`backgroundColor` 和 `alpha` ：

```objectivec
[UIView animateWithDuration:2.0 animations:^{
    myView.frame = CGRectMake(50, 200, 200, 200);
    myView.backgroundColor = [UIColor blueColor];
    myView.alpha = 0.7;
}];
```

其中有一个比较特殊的 `transform` 属性，它的类型是 `CGAffineTransform`，即 2D 仿射变换，这是个数学中的概念，用一个三维矩阵来表述 2D 图形的矢量变换。用 `transform` 属性对 View 进行：

* 旋转
* 缩放
* 其他自定义 2D 变换

iOS 提供了下面的函数可以创建简单的 2D 变换：

* `CGAffineTransformMakeScale`
* `CGAffineTransformMakeRotation`
* `CGAffineTransformMakeTranslation`

例如下面的代码会将 View 缩小至原来的 1/4 大小：

```objectivec
[UIView animateWithDuration:2.0 animations:^{
    myView.transform = CGAffineTransformMakeScale(0.5, 0.5);
}];
```

#### 调节参数

完整版的 animate 函数其实是这样的：

    + animateWithDuration:delay:options:animations:completion:

可以通过 `delay` 参数调节让动画延迟产生，同时还一个 `options` 选项可以调节动画进行的方式。可用的 `options` 可分为两类：

**控制过程**

例如 `UIViewAnimationOptionRepeat` 可以让动画反复进行， `UIViewAnimationOptionAllowUserInteraction` 可以让允许用户对动画进行过程中同 View 进行交互（默认是不允许的）

**控制速度**

动画的进行速度可以用速度曲线来表示（参考[这里](http://zhuanlan.zhihu.com/cheerfox/20031427#!)），提供的选项例如 `UIViewAnimationOptionCurveEaseIn` 是先慢后快，`UIViewAnimationOptionCurveEaseOut` 是先快后慢。

不同的选项直接可以通过“与”操作进行合并，同时使用，例如:

    UIViewAnimationOptionRepeat | UIViewAnimationOptionAllowUserInteraction
    
#### 关键帧动画

上面介绍的动画中，我们只能控制开始和结束时的效果，然后由系统补全中间的过程，有些时候我们需要自己设定若干关键帧，实现更复杂的动画效果，这时候就需要关键帧动画的支持了。下面是一个示例：


```objectivec
[UIView animateKeyframesWithDuration:2.0 delay:0.0 options:UIViewKeyframeAnimationOptionRepeat | UIViewKeyframeAnimationOptionAutoreverse animations:^{
    [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
        self.myView.frame = CGRectMake(10, 50, 100, 100);
    }];
    [UIView addKeyframeWithRelativeStartTime: 0.5 relativeDuration:0.3 animations:^{
        self.myView.frame = CGRectMake(20, 100, 100, 100);
    }];
    [UIView addKeyframeWithRelativeStartTime:0.8 relativeDuration:0.2 animations:^{
        self.myView.transform = CGAffineTransformMakeScale(0.5, 0.5);
    }];
} completion:nil];
```

这个例子添加了三个关键帧，在外面的 `animateKeyframesWithDuration` 中我们设置了持续时间为 2.0 秒，这是真实意义上的时间，里面的 `startTime` 和 `relativeDuration` 都是相对时间。以第一个为例，`startTime` 为 0.0，`relativeTime` 为 0.5，这个动画会直接开始，持续时间为 2.0 X 0.5 = 1.0 秒，下面第二个的开始时间是 0.5，正好承接上一个结束，第三个同理，这样三个动画就变成连续的动画了。

#### View 的转换

iOS 还提供了两个函数，用于进行两个 View 之间通过动画换场：

    + transitionWithView:duration:options:animations:completion:
    + transitionFromView:toView:duration:options:completion:

需要注意的是，换场动画会在这两个 View 共同的父 View 上进行，在写动画之前，先要设计好 View 的继承结构。

同样，View 之间的转换也有很多选项可选，例如 `UIViewAnimationOptionTransitionFlipFromLeft` 从左边翻转，`UIViewAnimationOptionTransitionCrossDissolve` 渐变等等。

### CALayer Animation 

UIView 的动画简单易用，但是能实现的效果相对有限，上面介绍的 UIView 的几种动画方式，实际上是对底层 CALayer 动画的一种封装。直接使用 CALayer 层的动画方法可以实现更多高级的动画效果。

**注意**：使用 CALayer 动画之前，首先需要引入 QuartzCore.framework。

#### 基本动画（CABasicAnimation）

CABasicAnimation 用于创建一个 CALayer 上的基本动画效果，下面是一个例子：

```objectivec
CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
animation.toValue = @200;
animation.duration = 0.8;
animation.repeatCount = 5;
animation.beginTime = CACurrentMediaTime() + 0.5;
animation.fillMode = kCAFillModeRemoved;
[self.myView.layer addAnimation:animation forKey:nil];
```

##### KeyPath

这里我们使用了 `animationWithKeyPath` 这个方法来改变 layer 的属性，可以使用的属性有很多，具体可以参考[这里](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/AnimatableProperties/AnimatableProperties.html)和[这里](http://www.cnblogs.com/pengyingh/articles/2379631.html)。其中很多属性在前面介绍的 UIView 动画部分我们也看到过，进一步验证了 UIView 的动画方法是对底层 CALayer 的一种封装。

需要注意的一点是，上面我们使用了 `position` 属性， layer 的这个 `position` 属性和 View 的 `frame` 以及 `bounds` 属性都不相同，而是和 Layer 的 `anchorPoint` 有关，可以由下面的公式计算得到：

```objectivec
position.x = frame.origin.x + 0.5 * bounds.size.width；  
position.y = frame.origin.y + 0.5 * bounds.size.height； 
```

关于 `anchorPoint` 和 `position` 属性的以及具体计算的原理可以参考[这篇文章](http://wonderffee.github.io/blog/2013/10/13/understand-anchorpoint-and-position/)。


##### 属性

CABasicAnimation 的属性有下面几个：

* beginTime
* duration
* fromValue
* toValue
* byValue
* repeatCount
* autoreverses
* timingFunction

可以看到，其中 beginTime，duration，repeatCount 等属性和上面在 UIView 中使用到的 duration，UIViewAnimationOptionRepeat 等选项是相对应的，不过这里的选项能够提供更多的扩展性。

需要注意的是 `fromValue`，`toValue`，`byValue` 这几个选项，支持的设置模式有下面几种：

* 设置 fromValue 和 toValue：从 fromValue 变化到 toValue
* 设置 fromValue 和 byValue：从 fromValue 变化到 fromValue + byValue
* 设置 byValue 和 toValue：从 toValue - byValue 变化到 toValue
* 设置 fromValue： 从 fromValue 变化到属性当前值
* 设置 toValue：从属性当前值变化到 toValue
* 设置 byValue：从属性当前值变化到属性当前值 + toValue

看起来挺复杂，其实概括起来基本就是，如果某个值不设置，就是用这个属性当前的值。

另外，可以看到上面我们使用的:

```objecitive-c
animation.toValue = @200;
```

而不是直接使用 200，因为 `toValue` 之类的属性为 `id` 类型，或者像这样使用 @ 符号，或者使用：

```objecitive-c
animation.toValue = [NSNumber numberWithInt:200];
```

最后一个比较有意思的是 `timingFunction` 属性，使用这个属性可以自定义动画的运动曲线（节奏，pacing），系统提供了五种值可以选择：

* kCAMediaTimingFunctionLinear 线性动画
* kCAMediaTimingFunctionEaseIn 先快后慢
* kCAMediaTimingFunctionEaseOut 先慢后快
* kCAMediaTimingFunctionEaseInEaseOut 先慢后快再慢
* kCAMediaTimingFunctionDefault 默认，也属于中间比较快

此外，我们还可以使用 [CAMediaTimingFunction functionWithControlPoints] 方法来自定义运动曲线，[这个网站](http://netcetera.org/camtf-playground.html)提供了一个将参数调节可视化的效果，关于动画时间系统的具体介绍可以参考[这篇文章](http://geeklu.com/2012/09/animation-in-ios/)。

#### 关键帧动画（CAKeyframeAnimation）

同 UIView 中的类似，CALayer 层也提供了关键帧动画的支持，CAKeyFrameAnimation 和 CABasicAnimation 都继承自 CAPropertyAnimation，因此它有具有上面提到的那些属性，此外，CAKeyFrameAnimation 还有特有的几个属性。

##### values 和 keyTimes

使用 `values` 和 `keyTimes` 可以共同确定一个动画的若干关键帧，示例代码如下：

```objectivec
CAKeyframeAnimation *anima = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation"];//在这里@"transform.rotation"==@"transform.rotation.z"
NSValue *value1 = [NSNumber numberWithFloat:-M_PI/180*4];
NSValue *value2 = [NSNumber numberWithFloat:M_PI/180*4];
NSValue *value3 = [NSNumber numberWithFloat:-M_PI/180*4];
anima.values = @[value1,value2,value3];
// anima.keyTimes = @[@0.0, @0.5, @1.0];
anima.repeatCount = MAXFLOAT;
    
[_demoView.layer addAnimation:anima forKey:@"shakeAnimation"];
```

可以看到上面这个动画共有三个关键帧，如果没有指定 `keyTimes` 则各个关键帧会平分整个动画的时间(duration)。

##### path 

使用 path 属性可以设置一个动画的运动路径，注意 path 只对 CALayer 的 anchorPoint 和position 属性起作用，另外如果你设置了 path ，那么 values 将被忽略。

```objectivec
CAKeyframeAnimation *anima = [CAKeyframeAnimation animationWithKeyPath:@"position"];
UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(SCREEN_WIDTH/2-100, SCREEN_HEIGHT/2-100, 200, 200)];
anima.path = path.CGPath;
anima.duration = 2.0f;
[_demoView.layer addAnimation:anima forKey:@"pathAnimation"];
```

#### 组动画（CAAnimationGroup)

组动画可以将一组动画组合在一起，所有动画对象可以同时运行，示例代码如下：

```objectivec
CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
CABasicAnimation *animationOne = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
animationOne.toValue = @2.0;
animationOne.duration = 1.0;
    
CABasicAnimation *animationTwo = [CABasicAnimation animationWithKeyPath:@"position.x"];
animationTwo.toValue = @400;
animationTwo.duration = 1.0;

[group setAnimations:@[animationOne, animationTwo]];
[self.myView.layer addAnimation:group forKey:nil];
```

需要注意的是，一个 group 组内的某个动画的持续时间（duration），如果超过了整个组的动画持续时间，那么多出的动画时间将不会被展示。例如一个 group  的持续时间是 5s，而组内一个动画持续时间为 10s ，那么这个 10s 的动画只会展示前 5s 。

#### 切换动画（CATransition）

CATransition 可以用于 View 或 ViewController 直接的换场动画：

```objectivec
self.myView.backgroundColor = [UIColor blueColor];
CATransition *trans = [CATransition animation];
trans.duration = 1.0;
trans.type = @"push";
    
[self.myView.layer addAnimation:trans forKey:nil];

// 这句放在下面也可以
// self.myView.backgroundColor = [UIColor blueColor];
```

为什么改变颜色放在前后都可以呢？具体的解释可以参考 SO 上的[这个回答](http://stackoverflow.com/questions/2233692/how-does-catransition-work)。简单来说就是动画和绘制之间并不冲突。

### 更高级的动画效果

#### CADisplayLink

CADisplayLink 是一个计时器对象，可以周期性的调用某个 selecor 方法。相比 NSTimer ，它可以让我们以和屏幕刷新率同步的频率（每秒60次）来调用绘制函数，实现界面连续的不停重绘，从而实现动画效果。

示例代码（修改自[这里](http://www.cocoachina.com/ios/20150320/11382.html))：

```objectivec
#import "BlockView.h"

@implementation BlockView

- (void)startAnimationFrom:(CGFloat)from To:(CGFloat)to
{
    self.from = from;
    self.to = to;
    if (self.displayLink == nil) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];
    }
}

// 重复调用这个方法以重绘整个 View
- (void)tick:(CADisplayLink *)displayLink
{
    [self setNeedsDisplay];
}

- (void)endAnimation
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)drawRect:(CGRect)rect
{
    CALayer *layer = self.layer.presentationLayer;
    CGFloat progress = 1 - (layer.position.y - self.to) / (self.from - self.to);
    CGFloat height = CGRectGetHeight(rect);
    CGFloat deltaHeight = height / 2 * (0.5 - fabs(progress - 0.5));
    CGPoint topLeft = CGPointMake(0, deltaHeight);
    CGPoint topRight = CGPointMake(CGRectGetWidth(rect), deltaHeight);
    CGPoint bottomLeft = CGPointMake(0, height);
    CGPoint bottomRight = CGPointMake(CGRectGetWidth(rect), height);
    UIBezierPath* path = [UIBezierPath bezierPath];
    [[UIColor blueColor] setFill];
    [path moveToPoint:topLeft];
    [path addQuadCurveToPoint:topRight controlPoint:CGPointMake(CGRectGetMidX(rect), 0)];
    [path addLineToPoint:bottomRight];
    [path addQuadCurveToPoint:bottomLeft controlPoint:CGPointMake(CGRectGetMidX(rect), height - deltaHeight)];
    [path closePath];
    [path fill];
}

@end

```
#### UIDynamicAnimator

UIDynamicAnimator 是 iOS 7 引入的一个新类，可以创建出具有物理仿真效果的动画，具体提供了下面几种物理仿真行为：

* UIGravityBehavior：重力行为
* UICollisionBehavior：碰撞行为
* UISnapBehavior：捕捉行为
* UIPushBehavior：推动行为
* UIAttachmentBehavior：附着行为
* UIDynamicItemBehavior：动力元素行为

示例代码如下（来自[这里](http://www.teehanlax.com/blog/introduction-to-uikit-dynamics/))

```objectivec
self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
UIGravityBehavior* gravityBehavior = [[UIGravityBehavior alloc] initWithItems:@[self.myView]];
[self.animator addBehavior:gravityBehavior];
    
UICollisionBehavior* collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.myView]];
collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
[self.animator addBehavior:collisionBehavior];
```

可以发现这段代码和我们之前写的动画代码有很大不同，在这里 behavior 是用于控制 View 行为的，我们做的操作是把各种不同的 behavior 加到 animator 中。这段代码实现了 View 因为“重力”原因“掉到”地上，落地的同时还有一个碰撞效果。

#### CAEmitterLayer

CAEmitterLayer 是 Core Animation 提供的一个粒子发生器系统，可以用于创建各种粒子动画，例如烟雾，焰火等效果。

CAEmitterLayer 需要调节的参数很多，可以实现的效果也非常炫酷，具体可参考下面几个网址：

* http://enharmonichq.com/tutorial-particle-systems-in-core-animation-with-caemitterlayer/#prettyPhoto/0/
* https://www.invasivecode.com/weblog/caemitterlayer-and-the-ios-particle-system-lets/?doing_wp_cron=1438657800.4759559631347656250000

[LTMorphingLabel](https://github.com/lexrus/LTMorphingLabel) 这个项目使用 CAEmitterLayer 实现了各种高端炫酷掉渣天的效果，大家想学习的话可以去看看它的代码。