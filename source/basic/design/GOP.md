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
# 设计模式归纳
<table>
   <tr>
      <td>序号</td>
      <td>模式 & 描述</td>
      <td>包括</td>
   </tr>
   <tr>
      <td rowspan="5">1</td>
      <td rowspan="5">
          创建型模式
          <br/>
          这些设计模式提供了一种在创建对象的同时隐藏创建逻辑的方式，而不是使用 new 运算符直接实例化对象。这使得程序在判断针对某个给定实例需要创建哪些对象时更加灵活。
      </td>
      <td>
      工厂模式（Factory Pattern）
      </td>
   </tr>
   <tr>
      <td>抽象工厂模式（Abstract Factory Pattern）</td>
   </tr>
   <tr>
      <td>单例模式（Singleton Pattern）</td>
   </tr>
   <tr>
      <td>建造者模式（Builder Pattern）</td>
   </tr>
   <tr>
      <td>原型模式（Prototype Pattern）</td>
   </tr>
   <tr>
      <td rowspan="8">2</td>
      <td rowspan="8">结构型模式<br/>这些设计模式关注类和对象的组合。继承的概念被用来组合接口和定义组合对象获得新功能的方式。</td>
      <td>适配器模式（Adapter Pattern）</td>
   </tr>
   <tr>
      <td>桥接模式（Bridge Pattern）</td>
   </tr>
   <tr>
      <td>过滤器模式（Filter、Criteria Pattern）</td>
   </tr>
   <tr>
      <td>组合模式（Composite Pattern）</td>
   </tr>
   <tr>
      <td>装饰器模式（Decorator Pattern）</td>
   </tr>
   <tr>
      <td>外观模式（Facade Pattern）</td>
   </tr>
   <tr>
      <td>享元模式（Flyweight Pattern）</td>
   </tr>
   <tr>
      <td>代理模式（Proxy Pattern）</td>
   </tr>
   <tr>
      <td rowspan="12">3</td>
      <td rowspan="12">行为型模式<br/>这些设计模式特别关注对象之间的通信。</td>
      <td>责任链模式（Chain of Responsibility Pattern）</td>
   </tr>
   <tr>
      <td>命令模式（Command Pattern）</td>
   </tr>
   <tr>
      <td>解释器模式（Interpreter Pattern）</td>
   </tr>
   <tr>
      <td>迭代器模式（Iterator Pattern）</td>
   </tr>
   <tr>
      <td>中介者模式（Mediator Pattern）</td>
   </tr>
   <tr>
      <td>备忘录模式（Memento Pattern）</td>
   </tr>
   <tr>
      <td>观察者模式（Observer Pattern）</td>
   </tr>
   <tr>
      <td>状态模式（State Pattern）</td>
   </tr>
   <tr>
      <td>空对象模式（Null Object Pattern）</td>
   </tr>
   <tr>
      <td>策略模式（Strategy Pattern）</td>
   </tr>
   <tr>
      <td>模板模式（Template Pattern）</td>
   </tr>
   <tr>
      <td>访问者模式（Visitor Pattern）</td>
   </tr>
</table>

## 转载：
- [设计模式六大原则](https://www.cnblogs.com/shijingjing07/p/6227728.html)
