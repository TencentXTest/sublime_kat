
Xtest 介绍
--------------------
这是一款xtest自动化脚本编辑工具，利用该插件可以快速编辑xtest 自动化测试脚本，支持运行、拉取测试结果等功能。
目前只能运行在sublime text 2环境下。

使用条件
------------------
您的机器必须配置了ANDROID环境，如果没有配置，xtestserver里也自带了一套adb环境，请在系统path环境变量里加入xtestserver的platform-tools路径（比如：D:\xserverpublic\sdk\platform-tools）
安装
------------------
1.先下载安装sublime text 2 [https://www.sublimetext.com/2/](https://www.sublimetext.com/2/)
2.点击 "peferences" >"browser packages",进入到安装package的目录下，将本插件的kat文件夹copy到该目录
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/1.png)
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/2.png)
3.重启sublime，右键如果出现如下菜单,说明安装成功。
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/3.png)


插入录制的脚本
------------------------------
### 1.导入demo工程，xtestserver2.2版本增加了lua文件夹，选择demo工程
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/4.png)
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/5.png)
### 2.插入手机端录制的脚本:手机连接pc,用xtest录制case后，双击工程中的"1.lua"，点击导出脚本，然后在sublime里右键选择"插入录制代码",
手机端录制的脚本会自动插入到编辑器里
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/6.png)



编辑和运行脚本
------------------------------
### 1.编辑脚本：kat编辑器提供代码提示功能，只需要输入方法首字母就可以弹出提示（api方法请参考xtestserver下面的lua/doc文件夹）
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/7.png)

### 2.运行脚本：请先将parameter.lua里packageName的值修改为被测应用的包名，操作方法:右击直接插入包名。然后右击运行Xtest，即可启动xtest测试。
![image](https://github.com/TencentXtest/sublime_kat/raw/master/images/8.png)



其他
-----------------
如果您还有其他问题，请加入联系我们的qq，技术问题也可以直接在github上建立issues
https://github.com/TencentXtest/Xtest/issues













