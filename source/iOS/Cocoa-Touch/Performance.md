## 离屏渲染

离屏渲染往往会带来界面卡顿的问题，这里将会讨论 当前屏幕渲染、离屏渲染 以及 CPU 渲染

在 OpenGL 中，GPU 屏幕渲染有以下两种方式：

- On-Screen Rendering

即当前屏幕渲染，在用于显示的屏幕缓冲区中进行，不需要额外创建新的缓存，也不需要开启新的上下文，所以性能较好，但是受到缓存大小限制等因素，一些复杂的操作无法完成。

- Off-Screen Rendering

即离屏渲染，指的是在 GPU 的当前屏幕缓冲区外开辟新的缓冲区进行操作。

相比于当前屏幕渲染，离屏渲染的代价是很高的，主要体现在如下两个方面：

- 创建新的缓冲区
- 上下文切换。离屏渲染的整个过程，需要多次切换上下文环境：先从当前屏幕切换到离屏，等待离屏渲染结束后，将离屏缓冲区的渲染结果显示到到屏幕上，这又需要将上下文环境从离屏切换到当前屏幕。

当设置了以下属性时，会触发离屏渲染：

- shouldRasterize（光栅化）
- masks（遮罩）
- shadows（阴影）
- edge antialiasing（抗锯齿）
- group opacity（不透明）

为了避免卡顿问题，应当尽可能使用当前屏幕渲染，可以不使用离屏渲染则尽量不用，应当尽量避免使用 layer 的 border、corner、shadow、mask 等技术。必须离屏渲染时，相对简单的视图应该使用 CPU 渲染，相对复杂的视图则使用一般的离屏渲染。

如下是 CPU 渲染和离屏渲染的区别：

由于GPU的浮点运算能力比CPU强，CPU渲染的效率可能不如离屏渲染。但如果仅仅是实现一个简单的效果，直接使用 CPU 渲染的效率又可能比离屏渲染好，毕竟普通的离屏渲染要涉及到缓冲区创建和上下文切换等耗时操作。对一些简单的绘制过程来说，这个过程有可能用CoreGraphics，全部用CPU来完成反而会比GPU做得更好。一个常见的 CPU 渲染的例子是：重写 `drawRect` 方法，并且使用任何 Core Graphics 的技术进行了绘制操作，就涉及到了 CPU 渲染。整个渲染过程由 CPU 在 App 内同步地完成，渲染得到的`bitmap`最后再交由GPU用于显示。总之，具体使用 CPU 渲染还是使用 GPU 离屏渲染更多的时候需要进行性能上的具体比较才可以。

一个常见的性能优化的例子就是如何给 UIView/UIImageView 加圆角。

如下是三种加圆角的方式：

- 设置 cornerRadius
- UIBezierPath
- Core Graphics(为 UIView 加圆角)与直接截取图片(为 UIImageView 加圆角)

如下是这三种方法的比较：

### cornerRadius

```objectivec
view.layer.cornerRadius = 6.0;
view.layer.masksToBounds = YES;
```
这种方式会触发两次离屏渲染，如果在滚动页面中这么做的话就会遇到性能问题。当然我们可以进行缓存以优化性能，如下：

```objectivec
view.layer.shouldRasterize = YES;
view.layer.rasterizationScale = [UIScreen mainScreen].scale;
```

shouldRasterize = YES 会使视图渲染内容被缓存起来，下次绘制的时候可以直接显示缓存，当然要在视图内容不改变的情况下。

注意：png 图片 在 UIImageView 这样处理圆角是不会产生离屏渲染的。（ios9.0之后不会离屏渲染，ios9.0之前还是会离屏渲染）。

### UIBezierPath

```objectivec
- (void)drawRect:(CGRect)rect {
  CGRect bounds = self.bounds;
  [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.0] addClip];

  [self.image drawInRect:bounds];
}
```

这种方法会触发一次离屏渲染，很多资料推崇这种写法，但是这种方式会导致内存暴增，并且同样会触发离屏渲染。

### Core Graphics(为 UIView 加圆角)与直接截取图片(为 UIImageView 加圆角)

正如你所期待的那样，这种方法应该是极具效率的正确的姿势。这里将为 UIView 添加圆角与为 UIImageView 添加圆角进行区分。

#### 使用 Core Graphics 为 UIView 加圆角

这种做法的原理是利用 Core Graphics 自己画出了一个圆角矩形。

```Swift
func kt_drawRectWithRoundedCorner(radius radius: CGFloat,  
                                  borderWidth: CGFloat,
                                  backgroundColor: UIColor,
                                  borderColor: UIColor) -> UIImage {    
    UIGraphicsBeginImageContextWithOptions(sizeToFit, false, UIScreen.mainScreen().scale)
    let context = UIGraphicsGetCurrentContext()

    CGContextMoveToPoint(context, 开始位置);  // 开始坐标右边开始
    CGContextAddArcToPoint(context, x1, y1, x2, y2, radius);  // 这种类型的代码重复四次

    CGContextDrawPath(UIGraphicsGetCurrentContext(), .FillStroke)
    let output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return output
}
```

这个方法返回的是 UIImage，有了这个图片后，就可以创建一个 UIImageView 并插入到视图层级的底部：

```Swift
extension UIView {  
    func kt_addCorner(radius radius: CGFloat,
                      borderWidth: CGFloat,
                      backgroundColor: UIColor,
                      borderColor: UIColor) {
        let imageView = UIImageView(image: kt_drawRectWithRoundedCorner(radius: radius,
                                    borderWidth: borderWidth,
                                    backgroundColor: backgroundColor,
                                    borderColor: borderColor))
        self.insertSubview(imageView, atIndex: 0)
    }
}
```

在调用时 只需要像这样写：

```Swift
let view = UIView(frame: CGRectMake(1,2,3,4))  
view.kt_addCorner(radius: 6) 
```

#### 直接截取图片为 UIImageView 加圆角

这里的实现思路是直接截取图片：

```Swift
extension UIImage {  
    func kt_drawRectWithRoundedCorner(radius radius: CGFloat, _ sizetoFit: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: sizetoFit)

        UIGraphicsBeginImageContextWithOptions(rect.size, false, UIScreen.mainScreen().scale)
        CGContextAddPath(UIGraphicsGetCurrentContext(),
            UIBezierPath(roundedRect: rect, byRoundingCorners: UIRectCorner.AllCorners,
                cornerRadii: CGSize(width: radius, height: radius)).CGPath)
        CGContextClip(UIGraphicsGetCurrentContext())

        self.drawInRect(rect)
        CGContextDrawPath(UIGraphicsGetCurrentContext(), .FillStroke)
        let output = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        return output
    }
}
```

圆角路径直接用贝塞尔曲线绘制。这个函数的效果是将原来的 UIImage 剪裁出圆角。配合着这函数，我们可以为 UIImageView 拓展一个设置圆角的方法：

```Swift
extension UIImageView {  
    /**
     / !!!只有当 imageView 不为nil 时，调用此方法才有效果

     :param: radius 圆角半径
     */
    override func kt_addCorner(radius radius: CGFloat) {
        self.image = self.image?.kt_drawRectWithRoundedCorner(radius: radius, self.bounds.size)
    }
}
```

在调用时只需要像如下这样写：

```Swift
let imageView = let imgView1 = UIImageView(image: UIImage(name: ""))  
imageView.kt_addCorner(radius: 6)  
```

> 注意：需要小心使用背景颜色。因为没有设置 `masksToBounds`，因此超出圆角的部分依然会被显示。因此不应该再使用背景颜色，可以在绘制圆角矩形时设置填充颜色来达到类似效果。

#### 总结

- 如果能够只用 cornerRadius 解决问题，就不用优化。
- 如果必须设置 masksToBounds，可以参考圆角视图的数量，如果数量较少（一页只有几个）也可以考虑不用优化。
- UIImageView 的圆角通过直接截取图片实现，其它视图的圆角可以通过 Core Graphics 画出圆角矩形实现。

## 参考链接
* [小心别让圆角成了你列表的帧数杀手](http://www.cocoachina.com/ios/20150803/12873.html)
* http://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/
* https://medium.com/ios-os-x-development/perfect-smooth-scrolling-in-uitableviews-fd609d5275a5
* [UIKit性能调优](http://www.jianshu.com/p/619cf14640f3)
* http://articles.cocoahope.com/blog/2013/03/06/applying-rounded-corners