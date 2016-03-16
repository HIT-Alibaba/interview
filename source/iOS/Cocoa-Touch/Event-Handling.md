### 事件分类

对于 iOS 设备用户来说，他们操作设备的方式主要有三种：触摸屏幕、晃动设备、通过遥控设施控制设备。对应的事件类型有以下三种：

1. 触屏事件（Touch Event）
2. 运动事件（Motion Event）
3. 远端控制事件（Remote-Control Event）

### 响应者链

当发生事件响应时，必须知道由谁来响应事件。在 iOS 中，由响应者链来对事件进行响应。

所有事件响应的类都是 UIResponder 的子类，响应者链是一个由不同对象组成的层次结构，其中的每个对象将依次获得响应事件消息的机会。当发生事件时，事件首先被发送给第一响应者，第一响应者往往是事件发生的视图，也就是用户触摸屏幕的地方。事件将沿着响应者链一直向下传递，直到被接受并做出处理。一般来说，第一响应者是个视图对象或者其子类对象，当其被触摸后事件被交由它处理，如果它不处理，事件就会被传递给它的视图控制器对象 ViewController（如果存在），然后是它的父视图（superview）对象（如果存在），以此类推，直到顶层视图。接下来会沿着顶层视图（top view）到窗口（UIWindow 对象）再到程序（UIApplication 对象）。如果整个过程都没有响应这个事件，该事件就被丢弃。一般情况下，在响应者链中只要由对象处理事件，事件就停止传递。

一个典型的事件响应路线如下：

    First Responser --> The Window --> The Application --> nil（丢弃）

我们可以通过 `[responder nextResponder]` 找到当前 responder 的下一个 responder，持续这个过程到最后会找到 UIApplication 对象。

通常情况下，我们在 First Responder （一般也就是用户当前触控的 View ）这里就会响应请求，进入下面的事件分发机制。

### 事件分发

第一响应者（First responder）指的是当前接受触摸的响应者对象（通常是一个 UIView 对象），即表示当前该对象正在与用户交互，它是响应者链的开端。响应者链和事件分发的使命都是找出第一响应者。

iOS 系统检测到手指触摸 (Touch) 操作时会将其打包成一个 UIEvent 对象，并放入当前活动 Application 的事件队列，单例的 UIApplication 会从事件队列中取出触摸事件并传递给单例的 UIWindow 来处理，UIWindow 对象首先会使用 `hitTest:withEvent:`方法寻找此次 Touch 操作初始点所在的视图(View)，即需要将触摸事件传递给其处理的视图，这个过程称之为 hit-test view。

`hitTest:withEvent:`方法的处理流程如下:

* 首先调用当前视图的 `pointInside:withEvent:` 方法判断触摸点是否在当前视图内；
* 若返回 NO, 则 `hitTest:withEvent:` 返回 nil，若返回 YES, 则向当前视图的所有子视图 (subviews) 发送 `hitTest:withEvent:` 消息，所有子视图的遍历顺序是从最顶层视图一直到到最底层视图，即从 subviews 数组的末尾向前遍历，直到有子视图返回非空对象或者全部子视图遍历完毕；
* 若第一次有子视图返回非空对象，则 `hitTest:withEvent:` 方法返回此对象，处理结束；
* 如所有子视图都返回空，则 hitTest:withEvent: 方法返回自身 (self)。

一个示例性的代码实现如下：

```objectivec
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *touchView = self;
    if ([self pointInside:point withEvent:event] &&
       (!self.hidden) &&
       self.userInteractionEnabled &&
       (self.alpha >= 0.01f)) {

        for (UIView *subView in self.subviews) {
            [subview convertPoint:point fromView:self];
            UIView *subTouchView = [subView hitTest:subPoint withEvent:event];
            if (subTouchView) {
                touchView = subTouchView;
                break;
            }
        }
    }else{
        touchView = nil;
    }

    return touchView;
}
```

#### 说明

1. 如果最终 hit-test 没有找到第一响应者，或者第一响应者没有处理该事件，则该事件会沿着响应者链向上回溯，如果 UIWindow 实例和 UIApplication 实例都不能处理该事件，则该事件会被丢弃（这个过程即上面提到的响应值链）；
2. `hitTest:withEvent:` 方法将会忽略隐藏 (hidden=YES) 的视图，禁止用户操作 (`userInteractionEnabled=NO`) 的视图，以及 alpha 级别小于 0.01(alpha<0.01)的视图。如果一个子视图的区域超过父视图的 bound 区域(父视图的 clipsToBounds 属性为 NO，这样超过父视图 bound 区域的子视图内容也会显示)，那么正常情况下对子视图在父视图之外区域的触摸操作不会被识别, 因为父视图的 `pointInside:withEvent:` 方法会返回 NO, 这样就不会继续向下遍历子视图了。当然，也可以重写 `pointInside:withEvent:` 方法来处理这种情况。
3. 我们可以重写 `hitTest:withEvent:` 来达到某些特定的目的。

[CYLTabBarController](https://github.com/ChenYilong/CYLTabBarController)是一个支持自定义 Tab 控件的开源项目。在 TabBar 当中，为了支持 TabBar 按钮大小超过 TabBar Frame 范围时也可以响应，它的实现就是重载了 hitTest 方法：

```objectivec
/*
 *
 Capturing touches on a subview outside the frame of its superview
 *
 */
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.clipsToBounds && !self.hidden && self.alpha > 0) {
        for (UIView *subview in self.subviews.reverseObjectEnumerator) {
            CGPoint subPoint = [subview convertPoint:point fromView:self];
            UIView *result = [subview hitTest:subPoint withEvent:event];
            if (result != nil) {
                return result;
            }
        }
    }
    return nil;
}
```

可以看到和上面的示例代码的差距，主要就在于取消了 `pointInside` 函数的检测，让我们可以捕获到当前 Frame 范围以外的子 View 的触控事件。

### 参考资料

1. [CocoaTouch 事件处理流程](http://www.cnblogs.com/snake-hand/p/3178070.html)
2. http://blog.sina.com.cn/s/blog_59fb90df0101ab26.html
