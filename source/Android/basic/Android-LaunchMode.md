###Android Activity的Launch Mode
####综述
对安卓而言，Activity有四种启动模式，它们是：

* standard 标准模式，每次都新建一个实例对象
* singleTop 如果在任务栈顶发现了相同的实例则重用，否则新建并压入栈顶
* singleTask 如果在任务栈中发现了相同的实例，将其上面的任务终止并移除，重用该实例。否则新建实例并入栈
* singleInstance 允许不同应用，进程线程等共用一个实例，无论从何应用调用该实例都重用

想要感受一下的话写一个小demo，然后自己启动自己再点返回键就看出来了。下面详细说说每一种启动模式

####standard
一张图就很好理解

![standard启动模式](https://github.com/HIT-Alibaba/interview/blob/master/img/android-lanchmode-standard.gif?raw=true)

什么配置都不写的话就是这种启动模式。但是每次都新建一个实例的话真是过于浪费，为了优化应该尽量考虑余下三种方式。

####singleTop
每次扫描栈顶，如果在任务栈顶发现了相同的实例则重用，否则新建并压入栈顶。

![singleTop](https://github.com/HIT-Alibaba/interview/blob/master/img/android-lanchmode-singletop.gif?raw=true)

配制方法实在Mainifest.xml中进行：

```
<activity
    android:name=".SingleTopActivity"
    android:label="@string/singletop"
    android:launchMode="singleTop" >
</activity>
```

####singleTask
与singleTop的区别是singleTask会扫描整个任务栈并制定策略。上效果图：

![singleTask](https://github.com/HIT-Alibaba/interview/blob/master/img/android-lanchmode-singletask.gif?raw=true)

使用时需要小心因为会将之前入栈的实例之上的实例全部移除，需要格外小心逻辑。

配制方法：
```
<activity
    android:name=".SingleTopActivity"
    android:label="@string/singletop"
    android:launchMode="singleTop" >
</activity>
```

####singleInstance
这个的理解可以这么看：在微信里点击“用浏览器打开”一个朋友圈，然后切到QQ再用浏览器开一个网页，再跑到哪里再开一个页面。每次我们都在Activity中试图启动另一个浏览器Activity，但是在浏览器端看来，都是调用了同一个自己。因为使用了singleInstance模式，不同应用调用的Activity实际上是共享的。

上说明图：

![singleInstance](https://github.com/HIT-Alibaba/interview/blob/master/img/android-lanchmode-singleinstance.gif?raw=true)

配制方法：
```
<activity
    android:name=".SingleTopActivity"
    android:label="@string/singletop"
    android:launchMode="singleTop" >
</activity>
```

####参考博客
传送门：

+ [http://www.cnblogs.com/fanchangfa/archive/2012/08/25/2657012.html](Android中Activity启动模式详解)
+ [Android入门：Activity四种启动模式](http://www.cnblogs.com/meizixiong/archive/2013/07/03/3170591.html)