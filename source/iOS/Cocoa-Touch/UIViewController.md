UIViewController（视图控制器），顾名思义，是 MVC 设计模式中的控制器部分。UIViewController 在 UIKit 中主要功能是用于控制画面的切换，其中的 `view` 属性（UIView 类型）管理整个画面的外观。

## UIViewController 生命周期

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

### 参考资料

1.[UIViewController生命周期方法执行顺序](blog.csdn.net/fanjunxi1990/article/details/16940271)