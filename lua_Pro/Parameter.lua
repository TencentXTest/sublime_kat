PackageName = '' --(your package name)
PackageType = 'base' --("base","cocos2dx")
-------------Customize your own Parameter ...------------------------------
Performance = true	--性能开关是否开启
isClearAppData = true	--测试开始是否清除被测App数据
testEndIsCleanPic = false  --由于monkey测试有可能产生巨量图片，所以需要将monkey类的测试分成多段执行，若case1测试没有crash，则可以删除case1文件夹，开关在Parameter中设置
isPlayToast = false --回放时是否显示点击步骤toast，默认为显示，实验室为了提高回放效率，可以去掉，可以在parameter中重写
isAutoCheckPoint = false --是否自动截取check_point_pic