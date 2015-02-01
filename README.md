笔试面试知识整理
=============

### 目录

* [网络](#网络)
    * [HTTP](#HTTP)
        * [HTTP的特性](#http的特性)
        * [HTTP报文](#http报文)
        * [持久连接](#持久连接)
        * [会话跟踪](#会话跟踪)
        * [跨站攻击](#跨站攻击)
    * [TCP](#tcp) 
        * [TCP的特性](#tcp的特性)
        * [三次握手与四次挥手](#三次握手与四次挥手)
        * [SYN攻击](#syn攻击)
    * [IP](#ip)
        * [广播与多播](#广播与多播)
* [数据结构和算法](#数据结构和算法)
* [体系结构和操作系统](#体系结构和操作系统)
* [编译原理](#编译原理)
* [数据库](#数据库)


网络
----

### HTTP

#### HTTP的特性

* HTTP构建于TCP/IP协议之上，默认端口号是80
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

#### 持久连接

我们知道 HTTP 协议采用“请求-应答”模式，当使用普通模式，即非 KeepAlive 模式时，每个请求/应答客户和服务器都要新建一个连接，完成之后立即断开连接（HTTP协议为无连接的协议）；当使用 Keep-Alive 模式（又称持久连接、连接重用）时，Keep-Alive 功能使客户端到服务器端的连接持续有效，当出现对服务器的后继请求时，Keep-Alive 功能避免了建立或者重新建立连接。

在 HTTP1.0 和 HTTP1.1 协议中都有对 Keep-Alive 的支持。其中 HTTP1.0 需要在 request 中增加 “Connection: keep-alive” header 才能够支持，而 HTTP1.1 默认开启，如果加入 "Connection: close" 才关闭。目前大部分浏览器都是用 HTTP1.1 协议，也就是说默认都会发起 Keep-Alive 的连接请求了，所以是否能完成一个完整的 Keep-Alive 连接就看服务器设置情况。

注意：

* HTTP Keep-Alive 简单说就是保持当前的TCP连接，避免了重新建立连接

* HTTP 长连接不可能一直保持，例如 `Keep-Alive: timeout=5, max=100`，表示这个TCP通道可以保持20秒，max=XXX，表示这个长连接最多接收XXX次请求就断开。

* HTTP是一个无状态协议，这意味着每个请求都是独立的，Keep-Alive没能改变这个结果。另外，Keep-Alive也不能保证客户端和服务器之间的连接一定是活跃的，在HTTP1.1版本中也如此。唯一能保证的就是当连接被关闭时你能得到一个通知，所以不应该让程序依赖于Keep-Alive的保持连接特性，否则会有意想不到的后果

* 使用长连接之后，客户端、服务端怎么知道本次传输结束呢？两部分：1是判断传输数据是否达到了Content-Length 指示的大小；2动态生成的文件没有 Content-Length ，它是分块传输（chunked），这时候就要根据 chunked 编码来判断，chunked 编码的数据在最后有一个空 chunked块，表明本次传输数据结束，详见[这里](http://www.cnblogs.com/skynet/archive/2010/12/11/1903347.html)。


#### 会话跟踪

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

    4. Session:

        每一个用户都有一个不同的session，各个用户之间是不能共享的，是每个用户所独享的，在session中可以存放信息。
        
        在服务器端会创建一个session对象，产生一个sessionID来标识这个session对象，然后将这个sessionID放入到Cookie中发送到客户端，下一次访问时，sessionID会发送到服务器，在服务器端进行识别不同的用户。
        
        Session的实现依赖于Cookie，如果Cookie被禁用，那么session也将失效。

#### 跨站攻击

* CSRF（Cross-site request forgery，跨站请求伪造）

    CSRF 顾名思义，是伪造请求，冒充用户在站内的正常操作。
    
    例如，一论坛网站的发贴是通过 GET 请求访问，点击发贴之后 JS 把发贴内容拼接成目标 URL 并访问：
    
        http://example.com/bbs/create_post.php?title=标题&content=内容

    那么，我们只需要在论坛中发一帖，包含一链接：

        http://example.com/bbs/create_post.php?title=我是脑残&content=哈哈
        
    只要有用户点击了这个链接，那么他们的帐户就会在不知情的情况下发布了这一帖子。可能这只是个恶作剧，但是既然发贴的请求可以伪造，那么删帖、转帐、改密码、发邮件全都可以伪造。
    
    **如何防范 CSRF 攻击**？可以注意以下几点：
    
    * 关键操作只接受POST请求

    * 验证码
        
      CSRF攻击的过程，往往是在用户不知情的情况下构造网络请求。所以如果使用验证码，那么每次操作都需要用户进行互动，从而简单有效的防御了CSRF攻击。

      但是如果你在一个网站作出任何举动都要输入验证码会严重影响用户体验，所以验证码一般只出现在特殊操作里面，或者在注册时候使用。

    * 检测refer

      常见的互联网页面与页面之间是存在联系的，比如你在www.baidu.com应该是找不到通往www.google.com的链接的，再比如你在论坛留言，那么不管你留言后重定向到哪里去了，之前的那个网址一定会包含留言的输入框，这个之前的网址就会保留在新页面头文件的Referer中

    通过检查Referer的值，我们就可以判断这个请求是合法的还是非法的，但是问题出在服务器不是任何时候都能接受到Referer的值，所以Refere Check 一般用于监控CSRF攻击的发生，而不用来抵御攻击。

    * Token

      目前主流的做法是使用Token抵御CSRF攻击。下面通过分析CSRF 攻击来理解为什么Token能够有效

      CSRF攻击要成功的条件在于攻击者能够预测所有的参数从而构造出合法的请求。所以根据不可预测性原则，我们可以对参数进行加密从而防止CSRF攻击。

      另一个更通用的做法是保持原有参数不变，另外添加一个参数Token，其值是随机的。这样攻击者因为不知道Token而无法构造出合法的请求进行攻击。

    Token 使用原则

    * Token要足够随机————只有这样才算不可预测
    * Token是一次性的，即每次请求成功后要更新Token————这样可以增加攻击难度，增加预测难度
    * Token要注意保密性————敏感操作使用post，防止Token出现在URL中

    **注意**：过滤用户输入的内容**不能**阻挡 csrf，我们需要做的是过滤请求的**来源**。

* XSS（Cross Site Scripting，跨站脚本攻击）

    XSS 全称“跨站脚本”，是注入攻击的一种。其特点是不对服务器端造成任何伤害，而是通过一些正常的站内交互途径，例如发布评论，提交含有 JavaScript 的内容文本。这时服务器端如果没有过滤或转义掉这些脚本，作为内容发布到了页面上，其他用户访问这个页面的时候就会运行这些脚本。
    
    运行预期之外的脚本带来的后果有很多中，可能只是简单的恶作剧——一个关不掉的窗口：

        while (true) {
            alert("你关不掉我~");
        }

    也可以是盗号或者其他未授权的操作。
    
    XSS 是实现 CSRF 的诸多途径中的一条，但绝对不是唯一的一条。一般习惯上把通过 XSS 来实现的 CSRF 称为 XSRF。
    
    **如何防御 XSS 攻击？**
    
    理论上，所有可输入的地方没有对输入数据进行处理的话，都会存在XSS漏洞，漏洞的危害取决于攻击代码的威力，攻击代码也不局限于script。防御 XSS 攻击最简单直接的方法，就是过滤用户的输入。
    
    如果不需要用户输入 HTML，可以直接对用户的输入进行 HTML escape 。下面一小段脚本：
    
        <script>window.location.href=”http://www.baidu.com”;</script>
        
    经过 escape 之后就成了：
    
        &lt;script&gt;window.location.href=&quot;http://www.baidu.com&quot;&lt;/script&gt;
       
    它现在会像普通文本一样显示出来，变得无毒无害，不能执行了。
    
    当我们需要用户输入 HTML 的时候，需要对用户输入的内容做更加小心细致的处理。仅仅粗暴地去掉 script 标签是没有用的，任何一个合法 HTML 标签都可以添加 onclick 一类的事件属性来执行 JavaScript。更好的方法可能是，将用户的输入使用 HTML 解析库进行解析，获取其中的数据。然后根据用户原有的标签属性，重新构建 HTML 元素树。构建的过程中，所有的标签、属性都只从**白名单**中拿取。

参考资料：

* http://www.cnblogs.com/hyddd/archive/2009/03/31/1426026.html
* http://www.cnblogs.com/cswuyg/p/3653263.html
* http://www.w3school.com.cn/tags/html_ref_httpmethods.asp
* http://www.cnblogs.com/skynet/archive/2010/12/11/1903347.html
* http://www.cnblogs.com/skynet/archive/2010/05/18/1738301.html
* http://blog.163.com/chfyljt@126/blog/static/11758032520127302714624/
* https://blog.tonyseek.com/post/introduce-to-xss-and-csrf/
* http://drops.wooyun.org/papers/155
* http://blog.csdn.net/ghsau/article/details/17027893
* [百度百科：HTTP](http://baike.baidu.com/view/9472.htm)

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
* [百度百科：SYN攻击](http://baike.baidu.com/subview/32754/8048820.htm)

### IP

#### 广播与多播

广播和多播仅用于UDP（TCP是面向连接的）。

* 广播

    一共有四种广播地址：
  
    1. 受限的广播
   
     受限的广播地址为255.255.255.255。该地址用于主机配置过程中IP数据报的目的地址，在任何情况下，router不转发目的地址为255.255.255.255的数据报，这样的数据报仅出现在本地网络中。
     
    2. 指向网络的广播
   
     指向网络的广播地址是主机号为全1的地址。A类网络广播地址为netid.255.255.255，其中netid为A类网络的网络号。
    
     一个router必须转发指向网络的广播，但它也必须有一个不进行转发的选择。
    
    3. 指向子网的广播
  
     指向子网的广播地址为主机号为全1且有特定子网号的地址。作为子网直接广播地址的IP地址需要了解子网的掩码。例如，router收到128.1.2.255的数据报，当B类网路128.1的子网掩码为255.255.255.0时，该地址就是指向子网的广播地址；但是如果子网掩码为255.255.254.0，该地址就不是指向子网的广播地址。
    
    4. 指向所有子网的广播
    
     指向所有子网的广播也需要了解目的网络的子网掩码，以便与指向网络的广播地址区分开来。指向所有子网的广播地址的子网号和主机号为全1.例如，如果子网掩码为255.255.255.0，那么128.1.255.255就是一个指向所有子网的广播地址。
    
     当前的看法是这种广播是陈旧过时的，更好的方式是使用多播而不是对所有子网的广播。
  
  广播示例:
  
        PING 192.168.0.255 (192.168.0.255): 56 data bytes
        64 bytes from 192.168.0.107: icmp_seq=0 ttl=64 time=0.199 ms
        64 bytes from 192.168.0.106: icmp_seq=0 ttl=64 time=45.357 ms
        
        64 bytes from 192.168.0.107: icmp_seq=1 ttl=64 time=0.203 ms
        64 bytes from 192.168.0.106: icmp_seq=1 ttl=64 time=269.475 ms
        
        64 bytes from 192.168.0.107: icmp_seq=2 ttl=64 time=0.102 ms
        64 bytes from 192.168.0.106: icmp_seq=2 ttl=64 time=189.881 ms
       
  可以看到的确收到了来自两个主机的答复，其中 192.168.0.107 是本机地址。

* 多播

    多播又叫组播，使用D类地址，D类地址分配的28bit均用作多播组号而不再表示其他。
    
    多播组地址包括1110的最高4bit和多播组号。它们通常可以表示为点分十进制数，范围从224.0.0.0到239.255.255.255。
    
    多播的出现减少了对应用不感兴趣主机的处理负荷。
    
    多播的特点：
    
    * 允许一个或多个发送者（组播源）发送单一的数据包到多个接收者（一次的，同时的）的网络技术
    * 可以大大的节省网络带宽，因为无论有多少个目标地址，在整个网络的任何一条链路上只传送单一的数据包 
    * 多播技术的核心就是针对如何节约网络资源的前提下保证服务质量。 
    
    
    多播示例：
    
        PING 224.0.0.1 (224.0.0.1): 56 data bytes
        64 bytes from 192.168.0.107: icmp_seq=0 ttl=64 time=0.081 ms
        64 bytes from 192.168.0.106: icmp_seq=0 ttl=64 time=123.081 ms
        64 bytes from 192.168.0.107: icmp_seq=1 ttl=64 time=0.122 ms
        64 bytes from 192.168.0.106: icmp_seq=1 ttl=64 time=67.312 ms
        64 bytes from 192.168.0.107: icmp_seq=2 ttl=64 time=0.132 ms
        64 bytes from 192.168.0.106: icmp_seq=2 ttl=64 time=447.073 ms
        64 bytes from 192.168.0.107: icmp_seq=3 ttl=64 time=0.132 ms
        64 bytes from 192.168.0.106: icmp_seq=3 ttl=64 time=188.800 ms
        
        
参考资料:

* http://www.cnblogs.com/Torres_fans/archive/2011/03/21/1990377.html
* http://www.cnblogs.com/happyhotty/articles/1874720.html
* http://blog.sina.com.cn/s/blog_ac9fdc0b0101pw7w.html

数据结构和算法
------------

体系结构和操作系统
---------------

编译原理
-------

数据库
-----


