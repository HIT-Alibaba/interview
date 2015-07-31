***这里记录的是另一篇[关于Bitmap加载](http://winlandiano.github.io/%E6%8A%80%E6%9C%AF/2014/10/25/Bitmap-load)的文章，感觉方向类似所以直接迁移过来。如有改进的同学欢迎随时更新***

对于一些大屏高分智能机，加载一个Bitmap总是致命的。这两天恰巧在两个不同的项目中遇到了Bitmap的问题。这两个问题都直接导致App在大屏高分屏中崩溃了。现在这里记录下我分别尝试过的几种方法和用过的感觉。下面的使用方法是按照我感觉到有效性从低到高排序的，当然越是有效地实现起来也越繁琐(虽然最繁琐的也没费多大劲)。随时更新:

写在前面：Android使用Bitmap是将图片解压缩为原始格式,所以大小的计算方式大致可以描述如下:

>图片会被解压缩为矩阵(分辨率），假设图片的分辨率是3776 * 2520，每一点又是由ARGB色组成，每个色素占4个Byte，所以加载这张图片要消耗的内存为： 3776 * 2520 * 4byte = 38062080byte
大约要38MB的内存，大小略有出入，因为图片还有一些Exif信息需要存储，会比仅靠分辨率计算要大一些。（卧槽这段的样式真的是逆天了Medium真的是不考虑天朝人的感受）

1.在加载大Bitmap的时候，一些手机会使用硬件加速。这个硬件加载的内存上线有的是24MB，我们可以手动关闭这个限制。当然这需要面临很大的风险，那就是不可控的崩溃。方法是在AndroidMainifest.xml里加入突出显示语句：

{% highlight xml %}
<application
android:hardwareAccelerated=”false”
{% endhighlight %}

***

2.尽一切可能调用`Bitmap.recycle()`，为gc提供一个参考，优先释放掉。但这样确实不是很保险。有时候gc抽风你的App就崩了……没办法……而且我之前做的一个模块需要反复频繁调用较多的Bitmap，这个方法确实降低了memory，但直接让我的应用变成了逐帧动画。建议在`onDestroy`里用`onStop`、`onResume`慎用。

3.使用Scale配合inJustDecodeBounds来降低Bitmap的DPI，根据屏幕的样式来降低Bitmap的所占内存。例如下面示例代码:


{% highlight java %}
BitmapFactory.Options opts = new Options();// 仅读取图片的信息,并不加载图片到内存
opts.inJustDecodeBounds = true;
BitmapFactory.decodeFile(“/sdcard/sample.jpg”, opts);
// 从Options中获取图片的分辨率
int imageHeight = opts.outHeight;
int imageWidth = opts.outWidth;
int picHeight = this.picHeight;
int picWidth = this.picWidth;

// 计算采样率
int scaleX = imageWidth / picWidth;
int scaleY = imageHeight / picHeight;
int scale = 1;
// 采样率依照最大的方向为准
if (scaleX > scaleY && scaleY >= 1) {
	scale = scaleX;
}
if (scaleX < scaleY && scaleX >= 1) {
	scale = scaleY;
}

// false表示读取图片像素数组到内存中，opts参数控制依照设定的采样率
opts.inJustDecodeBounds = false;
// 采样率
opts.inSampleSize = scale;
Bitmap bitmap = BitmapFactory.decodeFile(“/sdcard/a.jpg”, opts);
iv_bigimage.setImageBitmap(bitmap);
{% endhighlight %}

这里我们可以类似的看一下Bitmap的另一个方法[`public static BitmapcreateScaledBitmap (Bitmap src, int dstWidth, int dstHeight, boolean filter)`](http://developer.android.com/reference/android/graphics/Bitmap.html#createScaledBitmap%28android.graphics.Bitmap,%20int,%20int,%20boolean%29)

文档如下

>Creates a new bitmap, scaled from an existing bitmap, when possible. If the specified width and height are the same as the current width and height of the source bitmap, the source bitmap is returned and no new bitmap is created.

可以看出，最坏情况下也是`return the source bitmap`。对于过与变态的屏幕(如pad)只能另辟蹊径。但是对一般的智能机，这一招就足够用了。例如我最近写的一个模块memory直接降至25%。

另外用这个方法也不用再几个drawable中分别放资源文件了。参照[Android加载大分辨率图片到手机内存中的实例方法](http://www.jb51.net/article/43462.htm)