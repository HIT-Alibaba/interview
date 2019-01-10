##Activity生命周期
###总论
了解Activity的生命周期，需要了解：

1. 四种状态
2. 七个重要方法
3. 三个嵌套循环
4. 其他

首先在开头放出生命周期的一张总图：<br />
![安卓Activity生命周期](https://github.com/HIT-Alibaba/interview/blob/master/img/android-activity-lifecircle.jpg?raw=true)

###四种状态
四种状态包括

+ 活动（Active/Running）状态
+ 暂停(Paused)状态
+ 停止(Stopped)状态
+ 非活动（Dead）状态

####1. 活动（Active/Running）状态
当Activity运行在屏幕前台(处于当前任务活动栈的最上面),此时它获取了焦点能响应用户的操作,属于运行状态，同一个时刻只会有一个Activity 处于活动(Active)或运行(Running)状态。

此状态由onResume()进入，由onPause()退出

####2. 暂停(Paused)状态
当Activity失去焦点(如在它之上有另一个透明的Activity或返回桌面)它将处于暂停, 再进而进入其他状态。暂停的Activity仍然是存活状态(它保留着所有的状态和成员信息并保持和窗口管理器的连接),但是当系统内存极小时可以被系统杀掉。Android7.0后, 多窗口模式下失去焦点的Activity也将进入onPause，但这不意味着Activity中的活动(动画、视频)等会暂停。虽然官方文档使用的是"an activity is going into the background" 来描述，但这不意味着一个Toast或者由本Activity创建的Dialog会调用onPause。结合[这里](https://hit-alibaba.github.io/interview/Android/basic/Android-LaunchMode.html)对Activity的栈机制不难理解，只要当前Activity仍处于栈顶，系统就默认其仍处于活跃状态。

此状态由onPause()进入，可能下一步进入onResume()或者onCreate()重新唤醒软件，或者被onStop()杀掉

####3. 停止(Stopped)状态
完全被另一个Activity遮挡时处于停止状态,它仍然保留着所有的状态和成员信息。只是对用户不可见,当其他地方需要内存时它往往被系统杀掉。

该状态由onStop()进入，如果被杀掉，可能进入onCreate()或onRestart()，如果彻底死亡，进入onDestroy()

###Service生命周期
Service有两种启动方式:

+ `startService()` 启动本地服务`Local Service`
+ `bindService()` 启动远程服务`Remote Service`

远程服务允许暴露接口并让系统内不同程序相互注册调用。Local Service无法抵抗一些系统清理程序如MIUI自带的内存清除。

具体如何防止自己的Service被杀死可以看这个博客[Android开发之如何保证Service不被杀掉（broadcast+system/app）](http://blog.csdn.net/mad1989/article/details/22492519)，已经做到很变态的程度了。此外今天看到[如何看待 MIUI 工程师袁军对 QQ 后台机制的评论？](http://www.zhihu.com/question/28876912#answer-12365467)，QQ的开启一个像素在前台的做法真的是…呵呵

两种不同的启动方式决定了`Service`具有两种生命周期的可能（并非互斥的两种）。概括来说，`Service`在被创建之后都会进入回调`onCreate()`方法，随后根据启动方式分别回调`onStartCommand()`方法和`onBind()`方法。如果`Service`是经由`bindService()`启动，则需要所有client全部调用`unbindService()`才能将`Service`释放等待系统回收。

一张图解释：

![Service生命周期](https://github.com/HIT-Alibaba/interview/blob/master/img/android-service-lifecircle.png?raw=true)

回调方法的结构下图解释的很明白：

![Service回调方法](https://github.com/HIT-Alibaba/interview/blob/master/img/android-service-callback.png?raw=true)

参考博客：[圣骑士Wind的博客：Android Service的生命周期](http://www.cnblogs.com/mengdd/archive/2013/03/24/2979944.html)