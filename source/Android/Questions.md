13. 什么是ANR，如何避免
14. [[ListView原理与优化|ListView-Optimize]]
15. ContentProvider实现原理
16. 介绍Binder机制
17. 匿名共享内存，使用场景
18. 如何自定义View，如果要实现一个转盘圆形的View，需要重写View中的哪些方法？(onLayout,onMeasure,onDraw)
19. Android事件分发机制
20. Socket和LocalSocket
21. [[如何加载大图片|Android-Large-Image]] 
22. HttpClient和URLConnection的区别，怎么使用https
23. Parcelable和Serializable区别 
24. Android里跨进程传递数据的几种方案。(Binder,文件[面试官说这个不算],Socket,匿名共享内存（Anonymous Shared Memory))
25. 布局文件中，layout_gravity 和 gravity 以及 weight的作用。
26. ListView里的ViewType机制
27. TextView怎么改变局部颜色(SpannableString或者HTML)
28. Activity A 跳转到 Activity B，生命周期的执行过程是啥？(此处有坑 ActivityA的OnPause和ActivityB的onResume谁先执行)
29. Android中Handler声明非静态对象会发出警告，为什么，非得是静态的？(Memory Leak)
30. ListView使用过程中是否可以调用addView(不能，话说这题考来干啥。。。)
31. [[Android中的Thread, Looper和Handler机制(附带HandlerThread与AsyncTask)|Android-handler-thread-looper]]
32. Application类的作用
33. View的绘制过程
34. 广播注册后不解除注册会有什么问题？(内存泄露)
35. 属性动画(Property Animation)和补间动画(Tween Animation)的区别，为什么在3.0之后引入属性动画([官方解释：调用简单](http://android-developers.blogspot.com/2011/05/introducing-viewpropertyanimator.html))
36. 有没有使用过EventBus或者Otto框架，主要用来解决什么问题，内部原理
37. 设计一个网络请求框架(可以参考Volley框架)
38. 网络图片加载框架(可以参考BitmapFun)
39. Android里的LRU算法原理
40. BrocastReceive里面可不可以执行耗时操作?
41. Service onBindService 和startService 启动的区别