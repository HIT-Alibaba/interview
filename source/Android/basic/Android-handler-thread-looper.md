# Android中的Thread, Looper和Handler机制(附带HandlerThread与AsyncTask)

## Thread，Looper和Handler的关系

与Windows系统一样，Android也是消息驱动型的系统。引用一下消息驱动机制的四要素：

 + 接收消息的“消息队列”
 + 阻塞式地从消息队列中接收消息并进行处理的“线程”
 + 可发送的“消息的格式”
 +  “消息发送函数”
 
与之对应，Android中的实现对应了

+ 接收消息的“消息队列” ——【MessageQueue】
+ 阻塞式地从消息队列中接收消息并进行处理的“线程” ——【Thread+Looper】
+ 可发送的“消息的格式” ——【Message<Runnable被封装在Message中>】
+ “消息发送函数”——【Handler的post和sendMessage】

一个`Looper`类似一个消息泵。它本身是一个死循环，不断地从`MessageQueue`中提取`Message`或者Runnable。而`Handler`可以看做是一个`Looper`的暴露接口，向外部暴露一些事件，并暴露`sendMessage()`和`post()`函数。

在安卓中，除了`UI线程`/`主线程`以外，普通的线程(先不提`HandlerThread`)是不自带`Looper`的。想要通过UI线程与子线程通信需要在子线程内自己实现一个`Looper`。开启Looper分***三步走***：

1. 判定是否已有`Looper`并`Looper.prepare()`
2. 做一些准备工作(如暴露handler等)
3. 调用`Looper.loop()`，线程进入阻塞态

由于每一个线程内最多只可以有一个`Looper`，所以一定要在`Looper.prepare()`之前做好判定，否则会抛出`java.lang.RuntimeException: Only one Looper may be created per thread`。为了获取Looper的信息可以使用两个方法：

+ Looper.myLooper() 
+ Looper.getMainLooper()

`Looper.myLooper()`获取当前线程绑定的Looper，如果没有返回`null`。`Looper.getMainLooper()`返回主线程的`Looper`,这样就可以方便的与主线程通信。注意：**在`Thread`的构造函数中调用`Looper.myLooper`只会得到主线程的`Looper`**，因为此时新线程还未构造好

下面给一段代码，通过Thread，Looper和Handler实现线程通信：

### MainActivity.java
```
public class MainActivity extends Activity {
	public static final String TAG = "Main Acticity";
    Button btn = null;
    Button btn2 = null;
    Handler handler = null;
    MyHandlerThread mHandlerThread = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        btn = (Button)findViewById(R.id.button);
        btn2 = (Button)findViewById(R.id.button2);
        Log.d("MainActivity.myLooper()", Looper.myLooper().toString());
        Log.d("MainActivity.MainLooper", Looper.getMainLooper().toString());
        

        btn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                mHandlerThread = new MyHandlerThread("onStartHandlerThread");
                Log.d(TAG, "创建myHandlerThread对象");
                mHandlerThread.start();
                Log.d(TAG, "start一个Thread");
            }
        });

        btn2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(mHandlerThread.mHandler != null){
                    Message msg = new Message();
                    msg.what = 1;
                    mHandlerThread.mHandler.sendMessage(msg);
                }

            }
        });
    }
}
```

### MyHandlerThread.java

```
public class MyHandlerThread extends Thread {
    public static final String TAG = "MyHT";

    public Handler mHandler = null;

    @Override
    public void run() {
        Log.d(TAG, "进入Thread的run");
        Looper.prepare();
        Looper.prepare();
        mHandler = new Handler(Looper.myLooper()){
            @Override
            public void handleMessage(Message msg){
                Log.d(TAG, "获得了message");
                super.handleMessage(msg);
            }
        };
        Looper.loop();
    }
}
```

***

## HandlerThread 和 AsyncTask

### HandlerThread

Android为了方便对`Thread`和`Handler`进行封装，也就是`HandlerThread`。文档中对`HandlerThread`的定义是：

>Handy class for starting a new thread that has a looper. The looper can then be used to create handler classes. Note that start() must still be called.

`HandlerThread`继承自`Thread`，说白了就是`Thread`加上一个一个`Looper`。分析下面的代码:

```
public class MyHandlerThread extends HandlerThread{
	@Override
	public void run(){
		if(Looper.myLooper == null){
			Looper.prepare();
		}
		super.run();
	}
}
```

会抛出`java.lang.RuntimeException: Only one Looper may be created per thread`错误。如果我们把super.run()注释掉就不会有这样的错误。显然在`super.run()`中进行了Looper的绑定。

### AsyncTask

AsyncTask是谷歌对Thread和Handler的进一步封装，完全隐藏起了这两个概念，而用`doInBackground(Params... params)`取而代之。但需要注意的是AsyncTask的效率不是很高而且资源代价也比较重，只有当进行一些小型操作时为了方便起见使用。这一点在官方文档写的很清楚:

>AsyncTask is designed to be a helper class around Thread and Handler and does not constitute a generic threading framework. AsyncTasks should ideally be used for short operations (a few seconds at the most.) If you need to keep threads running for long periods of time, it is highly recommended you use the various APIs provided by the java.util.concurrent package such as Executor, ThreadPoolExecutor and FutureTask.

由于使用比较简单应该不需要细说。如有需要会在未来更新。