
sublime_kat介绍
--------------------
这是一款xtest自动化脚本编辑工具，利用该插件可以快速编辑xtest 自动化测试脚本，支持运行、拉取测试结果等功能。
目前只能运行在sublime text 2环境下。

视频教程
------------------
http://v.qq.com/x/page/l0337y41tvt.html

使用条件
------------------
您需要一台安装xtest并成功授权的手机，并保持与pc的usb的连接

安装
------------------
1.先下载整个sublime_kat工程，保存到本地目录中。
2.再下载安装sublime text 2 [https://www.sublimetext.com/2/](https://www.sublimetext.com/2/)
2.点击 "peferences" >"browser packages",进入到安装package的目录下，将sublime_kat下面的kat文件夹copy到该目录

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/1.png)

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/2.png)

3.重启sublime，右键如果出现如下菜单,说明安装成功。

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/3.png)


插入录制的脚本
------------------------------
### 1.先导入脚本工程:将sublime_kat文件夹下的lua_pro文件夹添加到sublime编辑器中即可

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/4.png)

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/5.png)

### 2.插入手机端录制的脚本:手机连接pc,手机端操作：录制case后，点击导出脚本，sublime端操作：双击工程中的"1.lua"（运行时候会自动运行该脚本），将光标定位在想要插入代码的位置，右键选择"插入录制代码",手机端录制的脚本会自动插入到编辑器的指定位置。

![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/10.png)
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/6.png)



编辑和运行脚本
------------------------------
### 1.编辑脚本：kat编辑器提供代码提示功能，只需要输入方法首字母就可以弹出提示（api方法请参考sublime_kat下的lua_doc文件夹）
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/7.png)

### 2.运行脚本：请先将parameter.lua里packageName的值修改为被测应用的包名，操作方法:右击直接“插入包名”（当然也可以自己手动写入）。然后右击运行Xtest，即可启动xtest测试。注:编辑器运行的脚本只是单机调试用，不会影响手机端y原有的case内容，如需修改，请将case上传，然后在pc端脚本管理里进行修改。
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/8.png)


查看测试结果
------------------------------

测试结束后，右击"拉取测试结果",编辑器就会将本次测试结果拉取回来。
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/9.png)

其他
-----------------
如果您还有其他问题，请加入联系我们的qq，技术问题也可以直接在github上建立issues
https://github.com/TencentXtest/Xtest/issues













