笔试面试知识整理
=============

### 目录

* [网络](#网络)
    * [HTTP](#HTTP)
        * [HTTP的特性](#HTTP的特性)
        * [HTTP报文](#HTTP报文)
        * [HTTP持久连接](#HTTP持久连接)
        * [HTTP会话跟踪](#HTTP会话跟踪)
    * [TCP](#tcp) 
        * [TCP的特性](#TCP的特性)
        * [三次握手与四次挥手](#三次握手与四次挥手)
        * [SYN攻击](#syn攻击)
* [数据结构和算法](#数据结构和算法)
* [体系结构和操作系统](#体系结构和操作系统)
* [编译原理](#编译原理)
* [数据库](#数据库)


网络
----

### HTTP

#### HTTP的特性

* HTTP构建于TCP协议之上，默认端口号是80
* HTTP是**无连接无状态**的

#### HTTP报文

HTTP定义了与服务器交互的不同方法，最基本的方法有4种，分别是`GET`，`POST`，`PUT`，`DELETE`。`URL`全称是资源描述符，我们可以这样认为：一个`URL`地址，它用于描述一个网络上的资源，而 HTTP 中的`GET`，`POST`，`PUT`，`DELETE`就对应着对这个资源的查，改，增，删4个操作。

1. GET用于信息获取，而且应该是安全的和幂等的。

    所谓安全的意味着该操作用于获取信息而非修改信息。换句话说，GET 请求一般不应产生副作用。就是说，它仅仅是获取资源信息，就像数据库查询一样，不会修改，增加数据，不会影响资源的状态。
    
    幂等的意味着对同一URL的多个请求应该返回同样的结果。
    
    GET请求报文示例：
    
        GET /books/?sex=man&name=Professional HTTP/1.1
        Host: www.wrox.com
        User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.6)
        Gecko/20050225 Firefox/1.0.1
        Connection: Keep-Alive
        
2. POST表示可能修改变服务器上的资源的请求。
        
        POST / HTTP/1.1
        Host: www.wrox.com
        User-Agent: Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.6)
        Gecko/20050225 Firefox/1.0.1
        Content-Type: application/x-www-form-urlencoded
        Content-Length: 40
        Connection: Keep-Alive
        
        sex=man&name=Professional  
              
3. 注意:

    * GET可提交的数据量受到URL长度的限制，HTTP协议规范没有对URL长度进行限制。这个限制是特定的浏览器及服务器对它的限制
    * 理论上讲，POST是没有大小限制的，HTTP协议规范也没有进行大小限制，出于安全考虑，服务器软件在实现时会做一定限制
    * 参考上面的报文示例，可以发现GET和POST数据内容是一模一样的，只是位置不同，一个在URL里，一个在HTTP包的包体里

#### HTTP持久连接

我们知道 HTTP 协议采用“请求-应答”模式，当使用普通模式，即非 KeepAlive 模式时，每个请求/应答客户和服务器都要新建一个连接，完成之后立即断开连接（HTTP协议为无连接的协议）；当使用 Keep-Alive 模式（又称持久连接、连接重用）时，Keep-Alive 功能使客户端到服务器端的连接持续有效，当出现对服务器的后继请求时，Keep-Alive 功能避免了建立或者重新建立连接。

在 HTTP1.0 和 HTTP1.1 协议中都有对 Keep-Alive 的支持。其中 HTTP1.0 需要在 request 中增加 “Connection: keep-alive” header 才能够支持，而 HTTP1.1 默认开启，如果加入 "Connection: close" 才关闭。目前大部分浏览器都是用 HTTP1.1 协议，也就是说默认都会发起 Keep-Alive 的连接请求了，所以是否能完成一个完整的 Keep-Alive 连接就看服务器设置情况。

注意：

* HTTP Keep-Alive 简单说就是保持当前的TCP连接，避免了重新建立连接

* HTTP 长连接不可能一直保持，例如 `Keep-Alive: timeout=5, max=100`，表示这个TCP通道可以保持20秒，max=XXX，表示这个长连接最多接收XXX次请求就断开。

* HTTP是一个无状态协议，这意味着每个请求都是独立的，Keep-Alive没能改变这个结果。另外，Keep-Alive也不能保证客户端和服务器之间的连接一定是活跃的，在HTTP1.1版本中也如此。唯一能保证的就是当连接被关闭时你能得到一个通知，所以不应该让程序依赖于Keep-Alive的保持连接特性，否则会有意想不到的后果

* 使用长连接之后，客户端、服务端怎么知道本次传输结束呢？两部分：1是判断传输数据是否达到了Content-Length 指示的大小；2动态生成的文件没有 Content-Length ，它是分块传输（chunked），这时候就要根据 chunked 编码来判断，chunke d编码的数据在最后有一个空 chunked块，表明本次传输数据结束。


#### HTTP会话跟踪

1. 什么是会话？

    客户端打开与服务器的连接发出请求到服务器响应客户端请求的全过程称之为会话。
    
2. 什么是会话跟踪？

    会话跟踪指的是对同一个用户对服务器的连续的请求和接受响应的监视。
    
3. 为什么需要会话跟踪？

    浏览器与服务器之间的通信是通过HTTP协议进行通信的，而HTTP协议是”无状态”的协议，它不能保存客户的信息，即一次响应完成之后连接就断开了，下一次的请求需要重新连接，这样就需要判断是否是同一个用户，所以才有会话跟踪技术来实现这种要求。
    
    
4. 会话跟踪常用的方法:

    1. URL重写
       
       URL(统一资源定位符)是Web上特定页面的地址，URL重写的技术就是在URL结尾添加一个附加数据以标识该会话,把会话ID通过URL的信息传递过去，以便在服务器端进行识别不同的用户。


    2. 隐藏表单域
    
       将会话ID添加到HTML表单元素中提交到服务器，此表单元素并不在客户端显示


    3. Cookie
    
        Cookie是Web服务器发送给客户端的一小段信息，客户端请求时可以读取该信息发送到服务器端，进而进行用户的识别。对于客户端的每次请求，服务器都会将Cookie发送到客户端,在客户端可以进行保存,以便下次使用。
        
        客户端可以采用两种方式来保存这个Cookie对象，一种方式是保存在客户端内存中，称为临时Cookie，浏览器关闭后这个Cookie对象将消失。另外一种方式是保存在客户机的磁盘上，称为永久Cookie。以后客户端只要访问该网站，就会将这个Cookie再次发送到服务器上，前提是这个Cookie在有效期内，这样就实现了对客户的跟踪。
        
        Cookie是可以被禁止的。

    4. session:

        每一个用户都有一个不同的session，各个用户之间是不能共享的，是每个用户所独享的，在session中可以存放信息。
        
        在服务器端会创建一个session对象，产生一个sessionID来标识这个session对象，然后将这个sessionID放入到Cookie中发送到客户端，下一次访问时，sessionID会发送到服务器，在服务器端进行识别不同的用户。
        
        Session的实现依赖于Cookie，如果Cookie被禁用，那么session也将失效。


参考资料：

* http://www.cnblogs.com/hyddd/archive/2009/03/31/1426026.html
* http://www.cnblogs.com/cswuyg/p/3653263.html
* http://www.w3school.com.cn/tags/html_ref_httpmethods.asp
* http://www.cnblogs.com/skynet/archive/2010/12/11/1903347.html
* http://www.cnblogs.com/skynet/archive/2010/05/18/1738301.html
* http://blog.163.com/chfyljt@126/blog/static/11758032520127302714624/
* 百度百科：HTTP

### TCP

#### TCP的特性

* TCP提供一种**面向连接的、可靠的**字节流服务
* 在一个TCP连接中，仅有两方进行彼此通信。广播和多播不能用于TCP
* TCP使用校验和，确认和重传机制来保证可靠传输
* TCP使用累积确认
* TCP使用滑动窗口机制来实现流量控制，通过动态改变窗口的大小进行拥塞控制


#### 三次握手与四次挥手

* 所谓三次握手(Three-way Handshake)，是指建立一个 TCP 连接时，需要客户端和服务器总共发送3个包。

    三次握手的目的是连接服务器指定端口，建立 TCP 连接，并同步连接双方的序列号和确认号，交换 TCP 窗口大小信息。在 socket 编程中，客户端执行 `connect()` 时。将触发三次握手。
    
    
    * 第一次握手(SYN=1, seq=x):
    
        客户端发送一个 TCP 的 SYN 标志位置1的包，指明客户端打算连接的服务器的端口，以及初始序号 X,保存在包头的序列号(Sequence Number)字段里。

        发送完毕后，客户端进入 `SYN_SEND` 状态。
        
    * 第二次握手(SYN=1, ACK=1, seq=y, ACKnum=x+1):
    
        服务器发回确认包(ACK)应答。即 SYN 标志位和 ACK 标志位均为1。服务器端选择自己 ISN 序列号，放到 Seq 域里，同时将确认序号(Acknowledgement Number)设置为客户的 ISN 加1，即X+1。 
        发送完毕后，服务器端进入 `SYN_RCVD` 状态。

    * 第三次握手(ACK=1，ACKnum=y+1)
        
        客户端再次发送确认包(ACK)，SYN 标志位为0，ACK 标志位为1，并且把服务器发来 ACK 的序号字段+1，放在确定字段中发送给对方，并且在数据段放写ISN的+1
        
        发送完毕后，客户端进入 `ESTABLISHED` 状态，当服务器端接收到这个包时，也进入 `ESTABLISHED` 状态，TCP 握手结束。

* TCP的连接的拆除需要发送四个包，因此称为四次挥手(Four-way handshake)，也叫做改进的三次握手。客户端或服务器均可主动发起挥手动作，在 socket 编程中，任何一方执行 `close()` 操作即可产生挥手操作。

    * 第一次挥手(FIN=1，seq=x)
        
        假设客户端想要关闭连接，客户端发送一个 FIN 标志位置为1的包，表示自己已经没有数据可以发送了，但是仍然可以接受数据。
        
        发送完毕后，客户端进入 `FIN_WAIT_1` 状态。
        
    * 第二次挥手(ACK=1，ACKnum=x+1)
    
        服务器端确认客户端的 FIN 包，发送一个确认包，表明自己接受到了客户端关闭连接的请求，但还没有准备好关闭连接。
        
        发送完毕后，服务器端进入 `CLOSE_WAIT` 状态，客户端接收到这个确认包之后，进入 `FIN_WAIT_2` 状态，等待服务器端关闭连接。
        
    * 第三次挥手(FIN=1，seq=y)

        服务器端准备好关闭连接时，向客户端发送结束连接请求，FIN 置为1。
        
        发送完毕后，服务器端进入 `LAST_ACK` 状态，等待来自客户端的最后一个ACK。
        
    * 第四次挥手(ACK=1，ACKnum=y+1)
    
        客户端接收到来自服务器端的关闭请求，发送一个确认包，并进入 `TIME_WAIT `状态，等待可能出现的要求重传的 ACK 包。
        
        服务器端接收到这个确认包之后，关闭连接，进入 `CLOSED` 状态。
        
        客户端等待了某个固定时间（两个最大段生命周期，2MSL，2 Maximum Segment Lifetime）之后，没有收到服务器端的 ACK ，认为服务器端已经正常关闭连接，于是自己也关闭连接，进入 `CLOSED` 状态。
        

#### SYN攻击

* 什么是 SYN 攻击（SYN Flood）？

    在三次握手过程中，服务器发送 SYN-ACK 之后，收到客户端的 ACK 之前的 TCP 连接称为半连接(half-open connect)。此时服务器处于 SYC_RCVD 状态。当收到 ACK 后，服务器才能转入 ESTABLISHED 状态.

    SYN 攻击指的是，攻击客户端在短时间内伪造大量不存在的IP地址，向服务器不断地发送SYN包，服务器回复确认包，并等待客户的确认。由于源地址是不存在的，服务器需要不断的重发直至超时，这些伪造的SYN包将长时间占用未连接队列，正常的SYN请求被丢弃，导致目标系统运行缓慢，严重者会引起网络堵塞甚至系统瘫痪。
    
    SYN 攻击是一种典型的 DoS/DDoS 攻击。
    
* 如何检测 SYN 攻击？

     检测 SYN 攻击非常的方便，当你在服务器上看到大量的半连接状态时，特别是源IP地址是随机的，基本上可以断定这是一次SYN攻击。在 Linux/Unix 上可以使用系统自带的 netstats 攻击来检测 SYN 攻击。
     
* 如何防御 SYN 攻击？

    SYN攻击不能完全被阻止，除非将TCP协议重新设计。我们所做的是尽可能的减轻SYN攻击的危害，常见的防御 SYN 攻击的方法有如下几种：
    
    * 缩短超时（SYN Timeout）时间
    * 增加最大半连接数
    * 过滤网关防护
    * SYN cookies技术
     

参考资料: 

* 计算机网络：自顶向下方法
* http://www.cnblogs.com/hnrainll/archive/2011/10/14/2212415.html
* http://www.cnblogs.com/rootq/articles/1377355.html
* http://blog.csdn.net/whuslei/article/details/6667471
* 百度百科：SYN攻击

数据结构和算法
------------

体系结构和操作系统
---------------

编译原理
-------

数据库
-----


