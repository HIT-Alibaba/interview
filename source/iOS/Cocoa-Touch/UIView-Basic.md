UIView 表示屏幕上的一块矩形区域，负责渲染区域的内容，并且响应该区域内发生的触摸事件。它在 iOS App 中占有绝对重要的地位，因为 iOS 中几乎所有可视化控件都是 UIView 的子类。

UIView 可以负责以下几种任务：

* 绘制和动画
* 布局和子视图管理
* 事件处理

## 绘制和动画

### 视图绘制

UIView 是按需绘制的，当整个视图或者视图的一部分由于布局变化，变成可见的，系统会要求视图进行绘制。对于那些需要使用 UIKit 或者 CoreGraphics 进行自定义绘制的视图，系统会调用 `drawRect:` 方法进行绘制。

当视图内容发生变化时，需要调用 `setNeedsDisplay` 或者 `setNeedsDisplayInRect:` 方法，告诉系统该重新绘制这个视图了。调用这个方法之后，系统会在下一个绘制周期更新这个视图的内容。由于系统要等到下一个绘制周期才真正进行绘制，可以一次性对多个视图调用 `setNeedsDisplay`，它们会同时被更新。


### 视图的几何属性

视图有 frame，center，bounds 等几个基本几何属性，其中:

* frame 使用的最多，其坐标位置都是相对于父视图的，可以用于确定本视图在父视图中的位置和其自身的大小
* center 的坐标位置也是相对于父视图的，通常用于移动，旋转等动画操作
* bounds 是相对于自身的，通常情况下就是（0,0,width,height)， bounds 的含义可以认为是当前 view 被允许绘制的范围

### 视图的 ContentMode

视图在初次绘制完成后，系统会对绘制结果进行快照，之后尽可能地使用快照，避免重新绘制。如果视图的几何属性发生改变，系统会根据视图的 contentMode 来决定如何改变显示效果。

默认的 contentMode 是 `UIViewContentModeScaleToFill` ，系统会拉伸当前的快照，使其符合新的 frame 尺寸。大部分 contentMode 都会对当前的快照进行拉伸或者移动等操作。如果需要重新绘制，可以把 contentMode 设置为 `UIViewContentModeRedraw`，强制视图在改变大小之类的操作时调用`drawRect:`重绘。


### 动画

可以以动画的形式改变视图的下面这些属性，只需要告诉系统动画开始和结束时的数值，系统会自动处理中间的过渡过程。

* frame
* bounds
* center
* transform
* alpha
* backgroundColor
* contentStretch

## 布局和子视图管理

除了提供视图本身的内容之外，一个视图也可以表现得像一个容器。当一个视图包含其他视图时，两个视图之间就创建了一个父子关系。在这个关系中子视图被称为 subView ，父视图被称为 superView 。一个视图可以包含多个子视图，它们被存放在这个视图的 `subviews` 数组里。添加，删除，以及操作这些子视图的相对位置的函数如下：

* `addSubview:`
* `insertSubview:...`
* `bringSubviewToFront:`
* `sendSubviewToBack:`
* `exchangeSubviewAtIndex:withSubviewAtIndex:`
* `removeFromSuperview`（子视图调用）

### AutoResizing 和 Constraint

当一个视图的大小改变时，它的子视图的位置和大小也需要相应地改变。UIView 支持自动布局，也可以手动对子视图进行布局。

当下列这些事件发生时，需要进行布局操作：

* 视图的 bounds 大小改变#
* 用户界面旋转，通常会导致根视图控制器的大小改变
* 视图的 layer 层的 Core Animation sublayers 发生改变
* 程序调用视图的`setNeedsLayout`或`layoutIfNeeded`方法
* 程序调用视图 layer 的`setNeedsLayout`方法

#### Auto Resizing

视图的`autoresizesSubviews`属性决定了在视图大小发生变化时，如何自动调节子视图。

可以使用的掩码如下：

* UIViewAutoresizingNone
* UIViewAutoresizingFlexibleHeight
* UIViewAutoresizingFlexibleWidth
* UIViewAutoresizingFlexibleLeftMargin
* UIViewAutoresizingFlexibleRightMargin
* UIViewAutoresizingFlexibleBottomMargin
* UIViewAutoresizingFlexibleTopMargin

可以通过位运算符将它们组合起来，例如 `UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth`。

#### Constraint

Constraint 是另一种用于自动布局的方法。本质上，Constraint 就是对 UIView 之间两个属性的一个约束：

    attribute1 == multiplier × attribute2 + constant

其中方程两边不一定是等于关系，也可以是大于等于之类的关系。

Constraint 比 AutoResizing 更加灵活和强大，可以实现复杂的子视图布局。

#### 自定义 layout

UIView 当中提供了一个 `layoutSubviews` 函数，UIView 的子类可以重载这个函数，以实现更加复杂和精细的子 View 布局。

苹果文档专门强调了，应该只在上面提到的 Autoresizing 和 Constraint 机制不能实现所需要的效果时，才使用 `layoutSubviews`。而且，layoutSubviews 方法只能被系统触发调用，程序员不能手动直接调用该方法。

那么 layoutSubviews 方法具体调用的时机有哪些呢？在 stackoverflow 的[这个答案](http://stackoverflow.com/questions/728372/when-is-layoutsubviews-called)里有所讨论，具体有下面几种情况：

1. 在父 view 的 autoresize mask 为 ON 的情况下，addSubview 会导致被 add 的 view 调用 layoutSubviews, 同时 add 的 target view 以及它所有的子 view 都会被调用。
2. setFrame 当新的 frame 和 旧的不同时（即 view 的大小改变时）会调用 layoutSubviews
3. 滚动一个 UIScollView 会导致这个 scrollView 以及它的父 View 调用 layoutSubviews
4. 旋转设备会导致当前所响应的 ViewController 的主 View 调用 layoutSubviews
5. 改变 View 的 size 会导致父 View 调用 layoutSubviews
6. removeFromSuperview 也会导致父 View 调用 layoutSubviews

重载 layoutSubviews 可以让我们实现更复杂的布局效果，[这篇博客](http://bachiscoding.com/2014/12/15/when-will-layoutsubviews-be-invoked/)里以[RDVTabBarController](https://github.com/robbdimitrov/RDVTabBarController)为例进行了简单介绍。

## 事件处理

UIView 是 UIResponder 的子类，可以响应触控事件。

通常可以使用 `addGestureRecognizer:` 添加手势识别器来响应触控事件，如果需要手动处理，则按需要重载 UIView 中的下面四个函数：

* `touchesBegan:withEvent:`
* `touchesMoved:withEvent:`
* `touchesEnded:withEvent:`
* `touchesCancelled:withEvent:`


### 参考资料

* [UIView详解](http://blog.csdn.net/chengyingzhilian/article/details/7894276)
* [UIView你知道多少](http://www.cnblogs.com/likwo/archive/2011/06/18/2084192.html)
* http://stackoverflow.com/questions/728372/when-is-layoutsubviews-called
