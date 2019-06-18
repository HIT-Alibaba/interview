# 设计模式
## 简介

在 1994 年，由 Erich Gamma、Richard Helm、Ralph Johnson 和 John Vlissides 四人合著出版了一本名为 Design Patterns - Elements of Reusable Object-Oriented Software（中文译名：设计模式 - 可复用的面向对象软件元素） 的书，该书首次提到了软件开发中设计模式的概念。
四位作者合称 GOF（四人帮，全拼 Gang of Four）。他们所提出的设计模式主要是基于以下的面向对象设计原则。 
- 对接口编程而不是对实现编程。 
- 优先使用对象组合而不是继承。 

## 设计模式六大原则

- 单一职责原则：即一个类应该只负责一项职责
- 里氏替换原则：所有引用基类的地方必须能透明地使用其子类的对象
- 依赖倒转原则：高层模块不应该依赖低层模块，二者都应该依赖其抽象；抽象不应该依赖细节，细节应该依赖抽象
- 接口隔离原则：客户端不应该依赖它不需要的接口；一个类对另一个类的依赖应该建立在最小的接口上
- 迪米特法则：一个对象应该对其他对象保持最少的了解
- 开闭原则：对扩展开放，对修改关闭

## 设计模式归纳

![1](/img/basic-design-gop.png)

## 参考：

- [设计模式六大原则](https://www.cnblogs.com/shijingjing07/p/6227728.html)
- [23中设计模式](https://www.cnblogs.com/pony1223/p/7608955.html)
