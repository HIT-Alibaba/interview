UIViewController（视图控制器），顾名思义，是 MVC 设计模式中的控制器部分。UIViewController 在 UIKit 中主要功能是用于控制画面的切换，其中的 `view` 属性（UIView 类型）管理整个画面的外观。

## UIViewController 生命周期

ViewController 生命周期的第一步是初始化。不过具体调用的方法还有所不同。如果使用 StoryBoard 来创建 ViewController，我们不需要显式地去初始化，Storyboard 会自动使用 `initWithCoder:` 进行初始化。如果不使用 StoryBoard，我们可以使用 `init:` 函数进行初始化，`init:` 函数在实现过程中还会调用 `initWithNibName:bundle:`。 我们应该尽量避免在 VC 外部调用 `initWithNibName:bundle:`，而是把它放在 VC 的内部（参考[这里](https://stackoverflow.com/questions/2224077/when-should-i-initialize-a-view-controller-using-initwithnibname)）。

初始化完成后，VC 的生命周期会经过下面几个函数：

- (void)loadView
- (void)viewDidLoad
- (void)viewWillAppear
- (void)viewWillLayoutSubviews
- (void)viewDidLayoutSubviews
- (void)viewDidAppear
- (void)viewWillDisappear
- (void)viewDidDisappear

假设现在有一个 AViewController(简称 Avc) 和 BViewController (简称 Bvc)，通过 navigationController 的 push 实现 Avc 到 Bvc 的跳转，下面是各个方法的执行执行顺序：

    1. A viewDidLoad  
    2. A viewWillAppear  
    3. A viewDidAppear  
    4. B viewDidLoad  
    5. A viewWillDisappear  
    6. B viewWillAppear  
    7. A viewDidDisappear  
    8. B viewDidAppear  

如果再从 Bvc 跳回 Avc，会产生下面的执行顺序：

    1. B viewWillDisappear  
    2. A viewWillAppear  
    3. B viewDidDisappear  
    4. A viewDidAppear  
    
可见 viewDidLoad 只会调用一次，再第二次跳回 Avc 的时候，AViewController 仍然存在于内存中，也就不需要 load 了。

注意上面的生命周期中都没有提到有关 ViewController 销毁的内容，在 iOS 4 & 5 中 ViewController 中有一个 `viewDidUnload` 方法。当内存不足，应用收到 Memory warning 时，系统会自动调用当前没在界面上的 ViewController 的 viewDidUnload 方法。 通常情况下，这些未显示在界面上的 ViewController 是 UINavigationController Push 栈中未在栈顶的 ViewController，以及 UITabBarViewController 中未显示的子 ViewController。这些 View Controller 都会在 Memory Warning 事件发生时，被系统自动调用 viewDidUnload 方法。

从 iOS 6 开始，viewDidUnload 方法被废弃掉了，应用受到 memory warning 时也不会再调用 viewDidUnload 方法。我们可以通过重载 `- (void)didReceiveMemoryWarning` 和 `-(void)dealloc` 来进行清理工作。
 

### 参考资料

1. [UIViewController生命周期方法执行顺序](http://blog.csdn.net/fanjunxi1990/article/details/16940271)
2. http://blog.devtang.com/blog/2013/05/18/goodbye-viewdidunload/
