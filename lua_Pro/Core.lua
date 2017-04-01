 --[[--
 XTest自动化核心类库 
 Core模块中的API与业务无关,只作为核心类库扩展使用 (Version:3.3.9.18)
 @module Core
 @author Lilith
 @license ---
 @copyright ---
]]
Android = luajava.newInstanceEx('com.matt.testtool.LuaAndroidApi')
hashmap = luajava.newInstance('java.util.HashMap')
----------------------------------全局变量------------------------------------------
Device = Android:getDeviceName()
---全局路径---
RootPath = '/sdcard/kat/'
ResultPath = RootPath..'Result/'
TotalResultLogPath = ResultPath..'Result.txt'
LogPath = ResultPath..'Log.txt'
DeviceInfoFilePath = ResultPath..'Info.txt'
InstallFilePath = ResultPath..'Install.txt'
VersionPath = ResultPath..'Version.txt'
CasePath = ResultPath..'case/'
--------------
clicktime = 2000  --点击后等待的时间(毫秒)
Case_Name = nil
t_info = {}
t_result = {}
Debug = true
Performance = false  --是否开启性能监控
TRACEBACK = ''
KAT_LUAEND = false
ISPOINT = 'true'  --回放时是否需要在点击控件的打水印,'true' or 'false'
Needresign = 'true' --是否需要重打包运行浅度monkey测试,'true' or 'false'
isTraversal = false  --当前测试是否为深度遍历测试,默认为false,该开关在startSimpleTest()中及monkey()中被修改
isMonkey = false  --当前测试是否为Monkey测试,默认为false,该开关在startSimpleTest()中及monkey()中被修改
isAccessbility = true  --是否启动一场弹窗清理功能
isClearAppData = false  --回放前是否需要清除被测应用数据
stepId = nil  --全局,回放到第几步,每次调用doRun方法时将被初始化
continuePlaybackFailTimes = nil --回放时连续失败次数,每次调用doRun方法时将被初始化
palybackFailMaxTimes = nil 	--回放时总失败次数,每次调用doRun方法时将被初始化
picCheckPointCounter = nil  --图片checkpoint检查点步骤计数器
actionCounter = nil  --自动checkpoint时的计数器
isLaboratoryMonkey = false  --当前是否在实验室执行monkey测试,默认为false,若在实验室执行monkey需要变为true
testEndIsCleanPic = false  --由于monkey测试有可能产生巨量图片,所以需要将monkey类的测试分成多段执行,若case1测试没有crash,则可以删除case1文件夹,开关在Parameter中设置
isPlayToast = true  --回放时是否显示点击步骤toast,默认为显示,实验室为了提高回放效率,可以去掉,可以在parameter中重写
isStepFail = false  --当前步骤是否失败,默认为false,在具体的录制的每步中进行修改,该步骤执行完毕重新标记为false
isAutoCheckPoint = false  --是否自动截取check_point_pic
isGetStartTime = false  --是否计算启动时间
action = 'nil'
AUTO_CP_FREQUENCY = 3  --自动截取check_point_pic的截图频率
COUNTINUE_FAIL_NUM = 3  --每个Case允许回放连续出错的次数
MAX_FAIL_NUM = 5  --每个Case允许回放出错的最大次数
PLAY_BACK_FAIL_TIP = 'Fail times reach maximum, please check!'
VIDEO_INFO_PATH = '/sdcard/kat/Result/VideoInfo.txt'  --回放过程中标记步骤点的信息内容,视频录制开启后使用,可以在parameter中重写
STEP_ERROR = 'Playback failed: not find control!'
CURRENT_TOOLS = 'kat'
ACTION_INFO_PATH = '/sdcard/kat/Result/Action.txt' 
CHECK_POINT_INFO_PATH = '/sdcard/kat/Result/cp_pic_info.txt'
CRASH_DATA_PATH = '/sdcard/kat/Result/allCrashData.txt'
TEST_RUNNING_RESULT_PATH = '/sdcard/kat/Result/testRunningResult.txt'

CHECK_POINT_SEPARATOR = "|"
CHECK_POINT_SUM = 0
CHECK_POINT_FAIL = 0
CHECK_POINT_PASS = 0

function handler(tag, detail)
	log('┌────────────────────┐'..'\n')
	log('| crash_handler'..'\n')
	log('| is_traversal:'..tostring(isTraversal)..'\n') 
	log('| is_monkey:'..tostring(isMonkey)..'\n')
	log('└────────────────────┘'..'\n')
	local crashTime = os.time()
	if detail == nil then detail = 'nil' end
	local error_type 
	local snap_tag 
	if tag == 1 then
		error_type = 'crash'
		snap_tag = 'fw_crash'
		_notifyMessage('Collect crash info!!', 1)
	elseif tag == 2 then
		error_type = 'anr'
		snap_tag = 'fw_anr'
	end
	_sleep(3000) --有可能crash弹窗还没及时出现,这里休眠几秒,若还没出现就不等了
	--取消checkPoint结果收集，在发生crash时候不记录断言
	-- t_info[#t_info + 1] = 'fw_cp_false: '..snap_tag
	-- t_result[#t_result + 1] = false
	collectResult()
	local PicName = getSystemTime('yyyyMMdd-HHmmss')..'_'..error_type..'.jpg'
	if isLaboratoryMonkey and isMonkey then  --由于实验室把路径修改了,这里还需要做一下处理
		crashsnapshotScreen(ResultPath..Case_Name..'/img/'..PicName, PackageName..'\n'..detail)
	elseif isLaboratoryMonkey then	--实验室monkey但首次就crash的处理
		Android:newFolder(ResultPath..Case_Name..'/img/')
		crashsnapshotScreen(ResultPath..Case_Name..'/img/'..PicName, PackageName..'\n'..detail)
	else	
		crashsnapshotScreen(CasePath..Case_Name..'/'..PicName, PackageName..'\n'..detail)
		Android:delete(CasePath..Case_Name..'/OK.txt')
		if _fileIsExist(ACTION_INFO_PATH) and not isTraversal then
			_check_point_pic()
		end
		os.remove(ACTION_INFO_PATH)
	end
	local file = io.open(CRASH_DATA_PATH,'r')
	local crashData = file:read("*all")
	file:close()
	local info = ''
	for w in string.gmatch(detail, '%w+') do
		info = info..w
	end
	if string.find(crashData, info) then
	else
		_writeFile(CRASH_DATA_PATH, info)
		_writeFileToFolder(ResultPath..'crash/', crashTime..'.txt', detail)
	end
	_sleep(1000)
	if isMonkey or isTraversal then  --monkey或者遍历就要重启一下,否则就停下吧
		restartApp(PackageName)
	else
		if Performance then pausePerformanceTest() end
		restartApp(PackageName)
		luaStop('KAT_LUAEND')
	end
end

require('/sdcard/kat/Parameter')
if PackageName == nil then error('fw_error please update your PackageName in Parameter.lua') end
if PackageType == nil then error('fw_error please update your PackageType in Parameter.lua') end

--- 得到控件的X,Y坐标值
 -- @within 1-General
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string activity 录制现场的activity名
 -- @treturn {boolean,number,number} 如果成功得到坐标则返回true,以及元素的x,y坐标值；否则返回false
 -- @usage local result,x,y = getControl_XY(-1,'name','qqchat','%com.tencent.mobileqq.widget.QQTabHost#0', 'com.tencent.mobileqq.activity.SplashActivity')
function getControl_XY(id, key, ctext, classpath, activity)
	local classpath = pathTranslate(classpath)
	local info = ''
	if activity == nil then activity = '' end
	local result = false
	local status, Temp_x, Temp_y, Temp_dx, Temp_dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
	local X = Temp_x + Temp_dx/2
	local Y = Temp_y + Temp_dy/2
	if status > 0 then result = true end
	info = 'getControl_XY '..tostring(result)..': '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
	return result, X, Y
end
 --- 可选事件类型的点击操作
 -- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @number event 点击类型 0-click 1-down 2-up
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @string activity 录制现场的activity名
 -- @usage clickByEvent(-1, 'id', 'qchat',  '%com.tencent.mobileqq.widget.QQTabHost#0', 0, TimeMarker(CaseN), 'com.tencent.mobileqq.activity.SplashActivity')
function clickByEvent(id, key, ctext, classpath, event, path, activity)
	local classpath = pathTranslate(classpath)
	local info = ''
	local mypath = path
	if path == 0 or path == nil then mypath = '' end
	if activity == nil then activity = '' end
	Android:click(id, key, ctext, classpath, event, mypath, activity)
	info = 'clickByEvent: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
end

 --- 基础性质的点击操作,常用在对性能要求高的场景中
 -- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @string activity 录制现场的activity名
 -- @treturn boolean 点击成功返回true,失败返回false
 -- @usage basic_click(-1,'key','qqchat','%com.tencent.mobileqq.widget.QQTabHost#0',TimeMarker(CaseN), 'com.tencent.mobileqq.activity.SplashActivity')
function basic_click(id, key, ctext, classpath, path, activity)
	local info = ''
	local result = false
	local mypath = path
	if path == 0 or path == nil then mypath = '' end
	if activity == nil then activity = '' end
	local status = Android:click(id, key, ctext, classpath, 0, mypath, activity)
	if status > 0 then result = true end
	info = 'basic_click '..tostring(result)..': '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
	return result
end

--- 等待控件并点击
 -- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @number wPercent 被点击元素的矩形区域横坐标相对百分比
 -- @number hPercent 被点击元素的矩形区域纵坐标相对百分比
 -- @number Timeout 超时时间,单位s
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @string activity 录制现场的activity名
 -- @treturn boolean 点击成功返回true,失败返回false
 -- @usage tap(-1, 'name', '登录', '%com.tencent.mobileqq.widget.QQTabHost#0', 0.5, 0.5, 20, TimeMarker(CaseN), 'com.jm.android.jumei.SpecialTimeSaleActivity')
function tap(id, key, ctext, classpath, wPercent, hPercent, Timeout, path, activity)
	if isAutoTest then
		Android:cacheTap(id, key, ctext, classpath, wPercent, hPercent, 0, '', activity)
	else
		return tap_original(id, key, ctext, classpath, wPercent, hPercent, Timeout, path, activity)
	end
end

function tap_original(id, key, ctext, classpath, wPercent, hPercent, Timeout, path, activity)
	local classpath = pathTranslate(classpath)
	action = 'tap'
	actionInit(ctext)
	if activity == nil then activity = '' end
	local mypath = path
	if path == 0 or path == nil then mypath = '' end
	local info = ''
	local status = ''
	local result = false
	local x, y, dx, dy = 0, 0, 0, 0
	local resolution_x, resolution_y = Android:getScreenResolution()
	local start_time = os.time()
	local end_time = start_time + Timeout
	while os.time() <= end_time do
		status, x, y, dx, dy = decodeResult(Android:tap(id, key, ctext, classpath, wPercent, hPercent, 0, mypath, activity))
		sleep(clicktime)
		-- LIKE_IT = 1         模糊匹配
		-- ALL_RIGHT = 2       完全匹配
		-- ERR_SYSTEM = 0      系统
		-- ERR_ACTIVITY = -1   Activity不匹配
		-- ERR_TIMEOUT = -2    超时
		-- ERR_NOTHING = -3    未找到
		-- ERR_OTHER = -4	   其它
		if status > 0 then
			local Temp_x = math.floor(x + dx*wPercent)
			local Temp_y = math.floor(y + dy*hPercent)
			if 0 <= Temp_x and Temp_x <= resolution_x and 0 <= Temp_y and Temp_y <= resolution_y then
				result = true
				break
			end
		elseif status == 0 then --返回系统错误直接返回失败
			break
		end
	end
	autoCP(ctext, x, y, dx, dy, wPercent, hPercent)
	if not result then
		isStepFail = true
		if isPlayToast then
			_notifyMessage('Step '..stepId..' '..STEP_ERROR)
		end
		_snapshotWholeScreen(TimeMarker(Case_Name), action..'|not find:'..tostring(id)..'+'..key..'+'..ctext..'+'..classpath)
	end
	info = 'step '..stepId..' > '..action..' '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n' 
	write_file_video(VIDEO_INFO_PATH, ' '..tostring(result)..'\n')
	if Debug then log(info) end
	stepId = stepId + 1
	tooManyfail(info)
	getHookVersion()
	return result
end

function tap_fuzzy(id, key, ctext, classpath, wPercent, hPercent, record_resolution_x, record_resolution_y, Timeout, path)
	local classpath = pathTranslate(classpath)
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':点击 false '..getSystemTimemap())
	if isPlayToast then
		if ctext ~= '' then
			_notifyMessage('Step '..stepId..' : 点击 ['..ctext..']')
		else
			_notifyMessage('Step'..stepId..' : 点击操作')
		end
	end
	local info = ''
	local temp_clicked = false
	local start_time = os.time()
	local end_time = start_time + Timeout
	while os.time() <= end_time do
		if path == 0 or path == nil then
			temp_clicked = Android:tap(id, key, ctext, classpath, wPercent, hPercent, 0)
		else 
			temp_clicked = Android:tap(id, key, ctext, classpath, wPercent, hPercent, 0, path)
		end
		_sleep(clicktime) 
		if temp_clicked then
			break
		end
	end
	if not temp_clicked then
		info = 'step '..stepId..' > tap false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
		_notifyMessage('Step '..stepId..' 回放失败 : 没有找到目标控件,尝试模糊匹配!')
		isStepFail = true
		if path == 0 or path == nil then
			temp_clicked = Android:tap(id, key, ctext, classpath, wPercent, hPercent, record_resolution_x, record_resolution_y, 0)
		else 
			temp_clicked = Android:tap(id, key, ctext, classpath, wPercent, hPercent, record_resolution_x, record_resolution_y, 0, path)
		end
		_sleep(clicktime)
	else
		info = 'step '..stepId..' > tap true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'   
	end
	write_file_video(VIDEO_INFO_PATH, ''..tostring(temp_clicked)..'\n')
	if Debug then log(info) end
	tooManyfail(info)
	getHookVersion()
	return temp_clicked
end

--- 长按操作
-- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @number wPercent 被点击元素的矩形区域横坐标相对百分比
 -- @number hPercent 被点击元素的矩形区域纵坐标相对百分比
 -- @number TouchTime 长按时间,单位ms
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @string activity 录制现场的activity名
 -- @treturn boolean 长按成功返回true,失败返回false
 -- @usage longTouch(-1, 'is', 'qqchat', '%com.tencent.mobileqq.widget.QQTabHost#0', 0.5, 0.5, 4000, TimeMarker(CaseN),'com.jm.android.jumei.SpecialTimeSaleActivity')
function longTouch(id, key, ctext, classpath, wPercent, hPercent, TouchTime, path, activity)
	if isAutoTest then
		Android:cacheLongTouch(id, key, ctext, classpath, wPercent, hPercent, TouchTime, '', activity)
	else
		return longTouch_original(id, key, ctext, classpath, wPercent, hPercent, TouchTime, path, activity)
	end
end

function longTouch_original(id, key, ctext, classpath, wPercent, hPercent, TouchTime, path, activity)
	local classpath = pathTranslate(classpath)
	action = 'longTouch'
	actionInit(ctext)
	if activity == nil then activity = '' end
	local mypath = path
	if path == 0 or path == nil then mypath = '' end
	local info = ''
	local status = ''
	local result = false
	local x, y, dx, dy = 0, 0, 0, 0
	local resolution_x, resolution_y = Android:getScreenResolution()
	local start_time = os.time()
	local end_time = start_time + 20
	while os.time() <= end_time do
		status, x, y, dx, dy = decodeResult(Android:longTouch(id, key, ctext, classpath, wPercent, hPercent, TouchTime, mypath, activity))
		sleep(clicktime)
		-- LIKE_IT = 1         模糊匹配
		-- ALL_RIGHT = 2       完全匹配
		-- ERR_SYSTEM = 0      系统
		-- ERR_ACTIVITY = -1   Activity不匹配
		-- ERR_TIMEOUT = -2    超时
		-- ERR_NOTHING = -3    未找到
		-- ERR_OTHER = -4	   其它
		if status > 0 then
			local Temp_x = math.floor(x + dx*wPercent)
			local Temp_y = math.floor(y + dy*hPercent)
			if 0 <= Temp_x and Temp_x <= resolution_x and 0 <= Temp_y and Temp_y <= resolution_y then
				result = true
				break
			end
		elseif status == 0 then --返回系统错误直接返回失败
			break
		end
	end
	autoCP(ctext, x, y, dx, dy, wPercent, hPercent)
	if not result then
		isStepFail = true
		if isPlayToast then
			_notifyMessage('Step '..stepId..' '..STEP_ERROR)
		end
		_snapshotWholeScreen(TimeMarker(Case_Name), action..'|not find:'..tostring(id)..'+'..key..'+'..ctext..'+'..classpath)
	end
	info = 'step '..stepId..' > '..action..' '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n' 
	write_file_video(VIDEO_INFO_PATH, ' '..tostring(result)..'\n')
	if Debug then log(info) end
	stepId = stepId + 1
	tooManyfail(info)
	getHookVersion()
	return result
end
--- 按坐标滑动(有加速度滑动)
 -- @within 2-Gesture
 -- @number x1 滑动开始的横坐标
 -- @number y1 滑动开始的纵坐标
 -- @number x2 滑动结束的横坐标
 -- @number y2 滑动结束的纵坐标
 -- @number record_resolution_x 录制滑动时横坐标录制设备的分辨率信息
 -- @number record_resolution_y 录制滑动时纵坐标录制设备的分辨率信息
 -- @string path  截图路径
 -- @usage fling(100, 200, 150, 300, 1080, 1920, TimeMarker(CaseN))
function fling(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	if isAutoTest then
		local resolution_x, resolution_y = Android:getScreenResolution()
		local X1 = (x1*resolution_x)/record_resolution_x
		local Y1 = (y1*resolution_y)/record_resolution_y
		local X2 = (x2*resolution_x)/record_resolution_x
		local Y2 = (y2*resolution_y)/record_resolution_y
		Android:cacheMove(X1, Y1, X2, Y2, 110)
	else
		fling_original(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	end
end

function fling_original(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	local action = 'fling'
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':'..action..' false '..getSystemTimemap()) 
	local info = ''
	if x1 > x2 and y1 > y2 then
		info = 'fling to the top left'
	elseif x1 > x2 and y1 < y2 then
		info = 'fling to the bottom left'
	elseif x1 > x2 and y1 == y2 then
		info = 'fling to the left'
	elseif x1 == x2 and y1 > y2 then
		info = 'fling to the top'
	elseif x1 == x2 and y1 < y2 then
		info = 'fling to the bottom'
	elseif x1 < x2 and y1 < y2 then
		info = 'fling to the bottom right'
	elseif x1 < x2 and y1 == y2 then
		info = 'fling to the right'
	elseif x1 < x2 and y1 > y2 then
		info = 'fling to the top right'
	end
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : '..info)
	end
	local resolution_x, resolution_y = Android:getScreenResolution()
	local X1 = (x1*resolution_x)/record_resolution_x
	local Y1 = (y1*resolution_y)/record_resolution_y
	local X2 = (x2*resolution_x)/record_resolution_x
	local Y2 = (y2*resolution_y)/record_resolution_y
	if path == nil or path == 0 then
		Android:fling(X1, Y1, X2, Y2)
		sleep(1500)
	else
		Android:fling(X1, Y1, X2, Y2, path)
		sleep(1500)
	end
	autoCP('', 0, 0, 0, 0, 0, 0)
	info = 'step '..stepId..' > fling: '..info..'\n'
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
	getHookVersion()
end

 --- 按坐标滑动(无加速度)
 -- @within 2-Gesture
 -- @number x1 滑动开始的横坐标
 -- @number y1 滑动开始的纵坐标
 -- @number x2 滑动结束的横坐标
 -- @number y2 滑动结束的纵坐标
 -- @number record_resolution_x 录制滑动时横坐标录制设备的分辨率信息
 -- @number record_resolution_y 录制滑动时纵坐标录制设备的分辨率信息
 -- @string path  截图路径
 -- @usage scroll(100, 200, 150, 300, 1080, 1920, TimeMarker(CaseN))
function scroll(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	if isAutoTest then
		local resolution_x, resolution_y = Android:getScreenResolution()
		local X1 = (x1*resolution_x)/record_resolution_x
		local Y1 = (y1*resolution_y)/record_resolution_y
		local X2 = (x2*resolution_x)/record_resolution_x
		local Y2 = (y2*resolution_y)/record_resolution_y
		Android:cacheMove(X1, Y1, X2, Y2, 110)
	else
		scroll_original(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	end
end

function scroll_original(x1, y1, x2, y2, record_resolution_x, record_resolution_y, path)
	local action = 'scroll'
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':'..action..' false '..getSystemTimemap()) 
	local info = ''
	if x1 > x2 and y1 > y2 then
		info = 'scroll to the top left'
	elseif x1 > x2 and y1 < y2 then
		info = 'scroll to the bottom left'
	elseif x1 > x2 and y1 == y2 then
		info = 'scroll to the left'
	elseif x1 == x2 and y1 > y2 then
		info = 'scroll to the top'
	elseif x1 == x2 and y1 < y2 then
		info = 'scroll to the bottom'
	elseif x1 < x2 and y1 < y2 then
		info = 'scroll to the bottom right'
	elseif x1 < x2 and y1 == y2 then
		info = 'scroll to the right'
	elseif x1 < x2 and y1 > y2 then
		info = 'scroll to the top right'
	end
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : '..info)
	end
	local resolution_x, resolution_y = Android:getScreenResolution()
	local X1 = (x1*resolution_x)/record_resolution_x
	local Y1 = (y1*resolution_y)/record_resolution_y
	local X2 = (x2*resolution_x)/record_resolution_x
	local Y2 = (y2*resolution_y)/record_resolution_y
	if path == nil or path == 0 then

		Android:move(X1, Y1, X2, Y2, 110)
		sleep(2000)
	else
		Android:capScreen_move(X1, Y1, X2, Y2, path)
		sleep(1000)

		Android:move(X1, Y1, X2, Y2, 110)
		sleep(1000)
	end
	autoCP('', 0, 0, 0, 0, 0, 0)
	info = 'step '..stepId..' > scroll: '..info..'\n'
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
	getHookVersion()
end

 --- 双击操作
 -- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @number wPercent 被点击元素的矩形区域横坐标相对百分比
 -- @number hPercent 被点击元素的矩形区域纵坐标相对百分比
 -- @string clicktime 点击等待的时间 ms
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @string activity 录制现场的activity名
 -- @treturn boolean 双击成功返回true,失败返回false
 -- @usage doubleClick(-1, 'key', 'qqchat', '%com.tencent.mobileqq.widget.QQTabHost#0', 0.5, 0.5,'6000', TimeMarker(CaseN), 'com.jm.android.jumei.SpecialTimeSaleActivity')
function doubleClick(id, key, ctext, classpath, wPercent, hPercent, clicktime, path, activity)
	if isAutoTest then
		Android:cacheDoubleClick(id, key, ctext, classpath, wPercent, hPercent, '', activity)
	else
		return doubleClick_original(id, key, ctext, classpath, wPercent, hPercent, clicktime, path, activity)
	end
end

function doubleClick_original(id, key, ctext, classpath, wPercent, hPercent, clicktime, path, activity)
	local classpath = pathTranslate(classpath)
	action = 'doubleClick'
	actionInit(ctext)
	if activity == nil then activity = '' end
	local mypath = path
	if path == 0 or path == nil then mypath = '' end
	local info = ''
	local status = ''
	local result = false
	local x, y, dx, dy = 0, 0, 0, 0
	local resolution_x, resolution_y = Android:getScreenResolution()
	local start_time = os.time()
	local end_time = start_time + 20
	while os.time() <= end_time do
		status, x, y, dx, dy = decodeResult(Android:doubleClick(id, key, ctext, classpath, wPercent, hPercent, mypath, activity))
		sleep(clicktime)
		-- LIKE_IT = 1         模糊匹配
		-- ALL_RIGHT = 2       完全匹配
		-- ERR_SYSTEM = 0      系统
		-- ERR_ACTIVITY = -1   Activity不匹配
		-- ERR_TIMEOUT = -2    超时
		-- ERR_NOTHING = -3    未找到
		-- ERR_OTHER = -4	   其它
		if status > 0 then
			local Temp_x = math.floor(x + dx*wPercent)
			local Temp_y = math.floor(y + dy*hPercent)
			if 0 <= Temp_x and Temp_x <= resolution_x and 0 <= Temp_y and Temp_y <= resolution_y then
				result = true
				break
			end
		elseif status == 0 then --返回系统错误直接返回失败
			break
		end
	end
	autoCP(ctext, x, y, dx, dy, wPercent, hPercent)
	if not result then
		isStepFail = true
		if isPlayToast then
			_notifyMessage('Step '..stepId..' '..STEP_ERROR)
		end
		_snapshotWholeScreen(TimeMarker(Case_Name), action..'|not find:'..tostring(id)..'+'..key..'+'..ctext..'+'..classpath)
	end
	info = 'step '..stepId..' > '..action..' '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n' 
	write_file_video(VIDEO_INFO_PATH, ' '..tostring(result)..'\n')
	if Debug then log(info) end
	stepId = stepId + 1
	tooManyfail(info)
	getHookVersion()
	return result
end

 --- 判断控件是否在当前页面
 -- @within 1-General
  -- @number id 元素id
  -- @string key 元素key值
  -- @string ctext 元素文本
  -- @string classpath 元素页面布局
  -- @string activity 录制现场的activity名
  -- @treturn boolean 如果在当前页面返回true,否则返回false
 -- @usage local isIn = isCurrentPage(-1, 'icon', 'qqchat','%com.tencent.mobileqq.widget.QQTabHost#0', 'com.jm.android.jumei.SpecialTimeSaleActivity')
function isCurrentPage(id, key, ctext, classpath, activity)
	local classpath = pathTranslate(classpath)
	local resolution_x, resolution_y = Android:getScreenResolution() 
	local info = ''
	local result = false
	if activity == nil then activity = '' end
	local status, x, y, dx, dy = decodeResult(Android:findControl(id, key, ctext, classpath, activity))
	if status > 0 then
		local isGet, Temp_x, Temp_y, Temp_dx, Temp_dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
		local x = Temp_x + Temp_dx/2
		local y = Temp_y + Temp_dy/2
		if (0<x and x<resolution_x) and (0<y and y<resolution_y) then
			result = true
		end
	end
	info = 'isCurrentPage '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
	return result
end

 --- 获取控件文本属性值
 -- @within 1-General
  -- @number id 元素id
  -- @string key 元素key值
  -- @string ctext 元素文本
  -- @string classpath 元素页面布局
  -- @string activity 录制现场的activity名
  -- @treturn {boolean,string} 成功返回true,获取的控件文本属性值;失败返回false,字符串'nil in getControlerText'
  -- @usage local result,content = getControlerText(-1,'title','','%com.tencent.mobileqq.widget.QQTabHost#0','com.jm.android.jumei.SpecialTimeSaleActivity')
function getControlerText(id, key, ctext, classpath, activity)
	local info = ''
	local result = false
	local classpath = pathTranslate(classpath)
	local content = 'nil in getControlerText'
	if activity == nil then activity = '' end
	for i=1,10 do
		content =  Android:getControlerText(id, key, ctext, classpath, activity)
		if content ~= nil then
			result = true
			break 
		end
		_sleep(500)
	end
	info = 'getControlerText '..tostring(result)..': '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n' 
	if Debug then log(info) end
	return result, content
end

 --- 在指定的控件下查找字符串
 -- @within 1-General
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string text 将要查找的字符串
 -- @string activity 录制现场的activity名
 -- @treturn {boolean,number,number,number,number} 找到返回true,并追加控件坐标值,否则返回false
 -- @usage local isFound,x,y,dx,dy = findTextFromControler(-1,'name','qchat', '%com.tencent.mobileqq.widget.QQTabHost#0','text', 'com.jm.android.jumei.SpecialTimeSaleActivity')
function findTextFromControler(id, key, ctext, classpath, text, activity)
	local info = ''
	if activity == nil then activity = '' end
	local result = false
	local status, x, y, dx, dy = Android:findTextFromControler(id, key, ctext, classpath, text, activity)
	if status > 0 then result = true end
	info = 'findTextFromControler: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..text..', '..activity..'\n'
	if Debug then log(info) end
	return result, x, y, dx, dy
end

 --- 判断是否找到控件
  -- @within 1-General
  -- @number id 元素id
  -- @string key 元素key值
  -- @string ctext 元素文本
  -- @string classpath 元素页面布局
  -- @string activity 录制现场的activity名
  -- @treturn boolean 找到控件返回true,否则返回false
  -- @usage local isFound = findControl(-1,'text','qqchat','%com.tencent.mobileqq.widget.QQTabHost#0', 'com.jm.android.jumei.SpecialTimeSaleActivity')
function findControl(id, key, ctext, classpath, activity)
	local info = ''
	local classpath = pathTranslate(classpath)
	local result = false
	if activity == nil then activity = '' end
	local status, x, y, dx, dy = decodeResult(Android:findControl(id, key, ctext, classpath, activity))
	if status > 0 then
		result = true
	end
	info = 'findControl '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
	return result
end

  --- 得到控件的坐标值
 -- @within 1-General
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string activity 录制现场的activity名
 -- @treturn {boolean,number,number,number,number} 成功得到返回true,并追加控件的边界坐标值;否则返回false
 -- @usage local result,x,y,dx,dy = getControlerRect(-1,'id','qqchat','%com.tencent.mobileqq.widget.QQTabHost#0', 'com.jm.android.jumei.SpecialTimeSaleActivity')
function getControlerRect(id, key, ctext, classpath, activity)
	local info = ''
	local classpath = pathTranslate(classpath)
	local result = false
	if activity == nil then activity = '' end
	local status, x, y, dx, dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
	if status > 0 then
		result = true
	end
	info = 'getControlerRect '..tostring(result)..': '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
	return result, x, y, dx, dy
end


--- 向控件输入文本信息
 -- @within 1-General
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string content 文本信息
 -- @string activity 录制现场的activity名
 -- @number mode 文本内容按字符输入--0  文本作为整体直接输入--1
 -- @treturn  boolean 成功返回true；失败返回false
 -- @usage setControlerText(-1,'id1','qchat', '%com.tencent.mobileqq.widget.QQTabHost#0','hello!kat', 'com.test.activity',0)
function setControlerText(id, key, ctext, classpath, content, activity, mode)
	if isAutoTest then
		Android:cacheInput(id, key, ctext, classpath, tostring(content), activity)
	else 
		return setControlerText_original(id, key, ctext, classpath, content, activity, mode)
	end
end

function setControlerText_original(id, key, ctext, classpath, content, activity, mode)
	if mode == 1 then Android:setInputTextMode(mode) end
	action = 'inputText'
	local classpath = pathTranslate(classpath)
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':'..action..' false '..getSystemTimemap())
	if isPlayToast then
		Android:notifyMessage('Step '..stepId..' : '..action..' ['..content..']')
	end
	if activity == nil then activity = '' end
	local info = ''
	local status = ''
	local result = false
	local x, y, dx, dy = 0, 0, 0, 0
	local start_time = os.time()
	local end_time = start_time + 20
	while os.time() <= end_time do
		status, x, y, dx, dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
		-- LIKE_IT = 1         模糊匹配
		-- ALL_RIGHT = 2       完全匹配
		-- ERR_SYSTEM = 0      系统
		-- ERR_ACTIVITY = -1   Activity不匹配
		-- ERR_TIMEOUT = -2    超时
		-- ERR_NOTHING = -3    未找到
		-- ERR_OTHER = -4	   其它
		if status > 0 then
			if _isCurrentPage(id, key, ctext, classpath, activity) then
				_snapshotScreen(x, y, dx, dy, TimeMarker(Case_Name))
				Android:setControlerText(id, key, ctext, classpath, tostring(content), activity)

				Android:hideSoftInputFromWindow(id, key, ctext, classpath, activity)
				sleep(2000)
				result = true
				break
			end
		elseif status == 0 then --返回系统错误直接返回失败
			break
		else
			sleep(2500)
		end
	end
	autoCP(content, 0, 0, 0, 0, 0, 0)
	if not result then
		isStepFail = true 
		if isPlayToast then
			_notifyMessage('Step '..stepId..' '..STEP_ERROR)
		end
		_snapshotWholeScreen(TimeMarker(Case_Name), ' '..action..'|not find:'..tostring(id)..'+'..key..'+'..ctext..'+'..classpath)
	end
	info = 'step '..stepId..' > '..action..' '..tostring(result)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..tostring(content)..', '..activity..'\n'
	write_file_video(VIDEO_INFO_PATH, ' '..tostring(result)..'\n') 
	if Debug then log(info) end
	stepId = stepId + 1
	tooManyfail(info)
	getHookVersion()
	return result
end

 --- 滑动寻找控件
 -- @within 2-Gesture
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @number moveTimes 滑动次数
 -- @string activity 录制现场的activity名
 -- @treturn boolean 找到控件返回true,否则返回false
 -- @usage local isFound = moveFindControler(-1, 'key', 'qchat',  '%com.tencent.mobileqq.widget.QQTabHost#0', 4, 'com.jm.android.jumei.SpecialTimeSaleActivity')
function moveFindControler(id, key, ctext, classpath, moveTimes, activity) --滑动找控件
	local classpath = pathTranslate(classpath)
	action = 'moveFindControler'
	actionInit(ctext)
	local resolution_x, resolution_y = Android:getScreenResolution()
	local info = ''
	local status = ''
	local x, y, dx, dy = 0, 0, 0, 0
	local isFound = false
	if activity == nil then activity = '' end
	for i = 1, moveTimes, 1 do
		if _isCurrentPage(id, key, ctext, classpath, activity) then
			status, x, y, dx, dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
			-- if (y + 3*dy/2) > resolution_y then
			if  y > 6*resolution_y/7 then --如果找到太靠下,也滑动一下
				Android:move(resolution_x/2, 3*resolution_y/4, resolution_x/2, resolution_y/2, 110)
				_sleep(2000)
			else
				isFound = true
				break
			end
		else
			Android:move(resolution_x/2, 3*resolution_y/4, resolution_x/2, resolution_y/2, 110)
			_sleep(2000)
		end
	end
	if not isFound then
		isStepFail = true 
		if isPlayToast then
			_notifyMessage('Step '..stepId..' '..STEP_ERROR)
		end
		_snapshotWholeScreen(TimeMarker(Case_Name), ' '..action..'|not find:'..tostring(id)..'+'..key..'+'..ctext..'+'..classpath)
	end
	info = 'moveFindControler '..tostring(isFound)..'['..status..']'..'['..x..','..y..','..dx..','..dy..']: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..tostring(moveTimes)..', '..activity..'\n'
	write_file_video(VIDEO_INFO_PATH, ' '..tostring(isFound)..'\n') 
	if Debug then log(info) end
	stepId = stepId + 1
	tooManyfail(info)
	getHookVersion()
	return isFound
end

 --- 等待控件出现
 -- @within 1-General
 -- @number id 元素id
 -- @string key 元素key值
 -- @string ctext 元素文本
 -- @string classpath 元素页面布局
 -- @string activity 元素所在activity
 -- @number timeout 超时时间,单位s
 -- @treturn boolean 控件出现返回true,否则返回false
 -- @usage local isFound = waitForControler(-1, 'id', 'qchat',  '%com.tencent.mobileqq.widget.QQTabHost#0', 'com.leo.test.mainActivity', 20)
function waitForControler(id, key, ctext, classpath, activity, timeout)
	local classpath = pathTranslate(classpath)
	local info = ''
	local isFound = false
	local startTime = os.time()
	local endTime = startTime + timeout
	while endTime >= os.time() do
		if _isCurrentPage(id, key, ctext, classpath, activity) then
			isFound = true
			break
		else
			sleep(1500)
		end
	end
	info = 'waitForControler '..tostring(isFound)..': '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..', '..timeout..'\n'
	if Debug then log(info) end
	return isFound
end

 --- 匹配控件并滑动
 -- @within 2-Gesture
 -- @number id_1 元素1 id
 -- @string key_1 元素1 key值
 -- @string ctext_1 元素1 文本
 -- @string classpath_1 元素1 页面布局
 -- @number id_2 元素2 id
 -- @string key_2 元素2 key值
 -- @string ctext_2 元素2 文本
 -- @string classpath_2 元素2 页面布局
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
 -- @usage findControlerAndMove(-1,'number1','button_1', '%com.tencent.mobileqq.widget.QQTabHost#0',-1,'number2','button_2', '%com.tencent.mobileqq.widget.QQTabHost#0',TimeMarker(CaseN))
function findControlerAndMove(id_1, key_1, ctext_1, classpath_1,id_2, key_2, ctext_2, classpath_2, path)
	local info = ''
	local result1, x1, y1, dx1, dy1 = Android:getControlerRect(id_1, key_1, ctext_1, classpath_1, '')
	local result2, x2, y2, dx2, dy2 = Android:getControlerRect(id_2, key_2, ctext_2, classpath_2, '')
	_move(x1 + dx1/2, y1 + dy1/2, x2 + dx2/2, y2 + dy2/2, path)
	info = 'findControlerAndMove: '..tostring(id_1)..', '..key_1..', '..ctext_1..', '..classpath_1..', '..tostring(id_2)..', '..key_2..', '..ctext_2..', '..classpath_2..'\n'
	if Debug then log(info) end
end

 --- 通过文本属性点击控件
  -- @within 2-Gesture
  -- @string ctext 元素文本
  -- @string path 截屏的图片保存路径
  -- @treturn boolean 点击成功返回true,否则返回false
  -- @usage findTextAndClick('qchat',TimeMarker(CaseN))
function findTextAndClick(ctext, path) 
	local info = ''
	local findTextAndClick_result = false
	if path == nil or path == 0 then
		findTextAndClick_result = Android:click(-1, '', ctext, '', 0)
	else
		findTextAndClick_result = Android:click(-1, '', ctext, '', 0, path)
	end
	if findTextAndClick_result then
		info = 'findTextAndClick true: '..ctext..', '..path..'\n'
	else
		info = 'findTextAndClick false: '..ctext..', '..path..'\n'
	end
	if Debug then log(info) end
	return findTextAndClick_result
end

 --- 隐藏与控件绑定的软键盘
  -- @within 1-General
  -- @number id 元素id
  -- @string key 元素key值
  -- @string ctext 元素文本
  -- @string classpath 元素页面布局
  -- @string activity 录制现场的activity名
  -- @usage hideSoftInputFromWindow(-1, 'num', 'qchat', '%com.tencent.mobileqq.widget.QQTabHost#0', 'com.jm.android.jumei.SpecialTimeSaleActivity')
function hideSoftInputFromWindow(id, key, ctext, classpath, activity)
	local info = ''
	if activity == nil then activity = '' end
	Android:hideSoftInputFromWindow(id, key, ctext, classpath, activity)
	info = 'hideSoftInputFromWindow: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..activity..'\n'
	if Debug then log(info) end
end

 --- 得到类似CompoundButton的控件当前状态
  -- @within 1-General
  -- @number id 元素id
  -- @string key 元素key值
  -- @string ctext 元素文本
  -- @string classpath 元素页面布局
  -- @string fieldname 控件状态字的名称
  -- @number superindex 索引值
  -- @string type 控件状态字类型
  -- @treturn status 返回控件当前状态
  -- @usage local status = getClassFieldValue(-1,'id','button1', '%com.tencent.mobileqq.widget.QQTabHost#0','fieldname',1,'boolean')
function getClassFieldValue(id, key, ctext, classpath, fieldname, superindex, type)
	local info = ''
	local status = Android:getClassFieldValue(id, key, ctext, classpath, fieldname, superindex, type)
	info = 'getClassFieldValue: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..tostring(fieldname)..', '..tostring(superindex)..', '..tostring(type)..'\n'
	if Debug then log(info) end
	return status
end

 --- monkey测试专用
  -- @within 3-Exploratory
  -- @string pkgName 包名字
  -- @number runTime 测试时长,单位分钟
  -- @string logPath 日志存储位置
  -- @usage monkey('com.tencent.mobileqq', 60, '/sdcard/KapalaiAutoTest/QQlite/')
function monkey(pkgName, runTime, logPath)
	log('into kat_monkey '..runTime..'\n')
	_logcat('i', '---kat---', 'into kat_monkey')
	local info = ''
	isMonkey = true
	isTraversal = false
	Android:monkey(pkgName, runTime, logPath)
	isMonkey = false
	info = 'monkey: '..pkgName..', '..tostring(runTime)..' mins, '..logPath..'\n' 
	if Debug then log(info) end
end

 --- monkey测试专用
 -- @within 3-Exploratory
 -- @string pkgName 包名字
 -- @number runTime 测试时长,单位分钟
 -- @string logPath 日志存储位置
 -- @usage simpleMonkey('com.tencent.mobileqq', 60, '/sdcard/KapalaiAutoTest/QQlite/')
function simpleMonkey(pkgName, runTime, logPath)
	log('into kat_simpleMonkey '..runTime..'\n')
	_logcat('i', '---kat---', 'into kat_simpleMonkey')
	local info = ''
	isMonkey = true
	isTraversal = false
	Android:simpleMonkey(pkgName, runTime, logPath)
	isMonkey = false
	info = 'simpleMonkey: '..pkgName..', '..tostring(runTime)..' mins, '..logPath..'\n' 
	if Debug then log(info) end
end

 --- 加强型monkey测试
  -- @within 3-Exploratory
  -- @number click 单击动作权重
  -- @number doubleclick 双击动作权重
  -- @number input 文本输入动作权重
  -- @number scroll 滚动动作权重
  -- @number longtouch 长按动作权重
  -- @number fingertouch 双指滑动动作权重
  -- @number randomclick 随机点击动作权重
  -- @usage setMonkeyProbability(5, 4, 2, 2, 1, 1, 1)
function setMonkeyProbability(click, doubleclick, input, scroll, longtouch, fingertouch, randomclick)
	local info = ''
	if string.find(Android:getApiVersion(), '3.5') or string.find(Android:getApiVersion(), '3.6') then
		--因为目前2.3及5.0以上版本不支持权重设置,所以写一个空方法
	else
		Android:setMonkeyProbability(click, doubleclick, input, scroll, longtouch, fingertouch, randomclick)
	end
	info = 'setMonkeyProbability: '..tostring(click)..', '..tostring(doubleclick)..', '..tostring(input)..', '..tostring(scroll)..', '..tostring(longtouch)..', '..tostring(fingertouch)..', '..tostring(randomclick)..'\n' 
	if Debug then log(info) end
end

 --- 局部全路径覆盖
 -- @within 3-Exploratory
 -- @string pkgname 应用程序包名
 -- @number runTime 测试时长,单位秒
 -- @treturn string 用:分割的字符串,前面代表是否在开始执行的界面(1为在初始页面,否则为不在初始页面),后面代表还剩多少控件没有遍历,1:23
 -- @usage  local result= startSimpleTest('com.tencent.qqmobile'，10*60)
function startSimpleTest(pkgname, runTime)
	log('into startSimpleTest'..'\n')
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':startSimpleTest '..getSystemTimemap())
	if isPlayToast then
		_notifyMessage('Step '..stepId..' : startSimpleTest')
	end
	local info = ''
	isTraversal = true
	isMonkey = false
	Android:setCaseFolder(getFileName(debug.getinfo(caseFactory).source))
	setScanTime(runTime)
	local result = Android:startSimpleTest(pkgname)
	isTraversal = false
	info = 'step '..stepId..' > startSimpleTest: '..tostring(pkgname)..', '..runTime..'\n' 
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
	getHookVersion()
	return result
end

function clearIgnoreControl()
	Android:clearIgnoreControl()
end

function cacheClear()
	Android:cacheClear()
end

 
function ignoreControl(key, text, activity)
	Android:setIgnoreControl(key, text, activity)
end

function ignoreBack()
	Android:setIgnoreBack(true)
end

function setMarkControl(id, key, text, activity)
	Android:setMarkControl(id, key, text, activity)
end

 --- 全路径执行前设置执行时长
  -- @within 3-Exploratory
  -- @string time 单位是秒
  -- @usage setScanTime(60)
function setScanTime(time)
	Android:setScanTime(time)
end

 --- 全路径执行前设置是否截图
  -- @within 3-Exploratory
  -- @number tag 1表示截图；0表示不截图 
  -- @usage setActionClip(1)
function setActionClip(tag)
	Android:setActionClip(tag)
end

 --- 新版本全路径遍历
  -- @within 3-Exploratory
  -- @string pkgname 应用程序包名
  -- @number depth 遍历深度
  -- @number scanTime 设置执行时长(单位s)
  -- @bool isScreenshot 遍历是否截图
  -- @usage startAutoTest('com.tencent.mm', 3, 60*30, true)
function startAutoTest(pkgname, depth, scanTime, isScreenshot)
	log('into startAutoTest'..'\n')
	hashmap:put('PackageName', PackageName)
	hashmap:put('callback', 'handler')
	hashmap:put('haswatertext', ISPOINT)
	hashmap:put('autoCPFrequency', tostring(AUTO_CP_FREQUENCY))
	Android:setLuaContext(hashmap)
	local info = ''
	cacheClear()
	isTraversal = true
	isMonkey = false
	Android:setDepth(depth)
	Android:setScanTime(scanTime)
	if isScreenshot then
		Android:setActionClip(1)
	else
		Android:setActionClip(0)
	end
	-- @int deepPrior 深度优先or广度优先: 0 广度优先  1: 深度优先  2：随机
	Android:setDeepPrior(1)
	Android:setCaseFolder(getFileName(debug.getinfo(caseFactory).source))
	Android:startAutoTest(pkgname)
	isTraversal = false
	info = 'startAutoTest: '..tostring(pkgname)..', '..tostring(depth)..', '..tostring(scanTime)..', '..tostring(isScreenshot)..'\n'
	os.remove(ACTION_INFO_PATH)
	if Debug then log(info) end
end


function cocos2dx_findControl(id, key, ctext, classpath)
	local info = ''
	local result = Android:cocos2dx_findControl(id, key, ctext,classpath) 
	info = 'cocos2dx_findControl: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	if Debug then log(info) end
	return result
end


function cocos2dx_getControlerRect(id,key,ctext,classpath)
	local info = ''
	local result, x,y,dx,dy = Android:cocos2dx_getControlerRect(id, key, ctext, classpath)
	if result then
		info = 'cocos2dx_getControlerRect true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	else
		info = 'cocos2dx_getControlerRect false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	end
	if Debug then log(info) end
	return result,x,y,dx,dy
end

function cocos2dx_setControlerText(id, key, ctext, classpath, content)
	local info = ''
	Android:cocos2dx_SetControlerText(id, key, ctext, classpath, content)
	info = 'cocos2dx_setControlerText: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..content..'\n'
	if Debug then log(info) end
end


function cocos2dx_click(id, key, ctext, classpath, clicktime,path)
	local info = ''
	local temp_clicked = false
	if path == 0 or path == nil then
		temp_clicked = Android:cocos2dx_click(id, key, ctext, classpath,0)
		_sleep(clicktime) 
	else 
		temp_clicked = Android:cocos2dx_click(id, key, ctext, classpath, 0, path) 
		_sleep(clicktime)
	end
	if not temp_clicked then
		info = 'cocos2dx_click false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	else
		info = 'cocos2dx_click true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	end
	if Debug then log(info) end
	return temp_clicked
end

 
function cocos2dx_clickByEvent(id, key, ctext, classpath, event, path)
	local info = ''
	local result = false
	if path == 0 or path == nil then
		result = Android:cocos2dx_click(id, key, ctext, classpath, event)
	else
		result = Android:cocos2dx_click(id, key, ctext, classpath, event, path)
	end
	if result then
		info = 'cocos2dx_clickByEvent true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..event..'\n'
	else
		info = 'cocos2dx_clickByEvent false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..', '..event..'\n'
	end
	if Debug then log(info) end
	return result 
end

 
function cocos2dx_waitAndClick(id, key, ctext, classpath, Timeout, path)
	local info = ''
	local temp_clicked = false
	for i = 1,4 do
	_sleep(Timeout/4)
	if path == 0 or path == nil then
		_sleep(clicktime) 
	else 
		temp_clicked = Android:cocos2dx_click(id, key, ctext, classpath, 0, path) 
		_sleep(clicktime) 
	end
	if temp_clicked then
		break
	end
	end
	if temp_clicked then
		info = 'cocos2dx_waitAndClick true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	else
		info = 'cocos2dx_waitAndClick false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	end
	if Debug then log(info) end
	return temp_clicked
end

 
function cocos2dx_getControlerRect_AllChild(id, key, ctext, classpath)
	local info = ''
	local isFind, Cocos2dxContainer = Android:cocos2dx_getControlerRect_AllChild(id, key, ctext, classpath)
	info = 'cocos2dx_getControlerRect_AllChild: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	if Debug then log(info) end
	return isFind, Cocos2dxContainer
end


function cocos2dx_getListOfContainer(Cocos2dxContainer)
	local info = ''
	local ListOfContainer = Cocos2dxContainer:getList()
	info = 'cocos2dx_getListOfContainer: '..tostring(Cocos2dxContainer)..'\n'
	if Debug then log(info) end
	return ListOfContainer
end

 
function cocos2dx_sizeOfContainerList(ListOfCocos2dxContainer)
	local info = ''
	local size = ListOfCocos2dxContainer:size()
	info = 'cocos2dx_sizeOfContainerList: '..tostring(ListOfCocos2dxContainer)..'\n'
	if Debug then log(info) end
	return size
end

 
function cocos2dx_getChildOfContainerList(ListOfCocos2dxContainer, i)
	local info = ''
	local Cocos2dxElement = ListOfCocos2dxContainer:get(i)
	info = 'cocos2dx_getChildOfContainerList: '..tostring(ListOfCocos2dxContainer)..', '..tostring(i)..'\n'
	if Debug then log(info) end
	return Cocos2dxElement
end


function cocos2dx_getTextOfChild(Cocos2dxElement)
	local info = ''
	local textOfChild = Cocos2dxElement:getText()
	info = 'cocos2dx_getTextOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return textOfChild
end

 
function cocos2dx_getXOfChild(Cocos2dxElement)
	local info = ''
	local x = Cocos2dxElement:getX()
	info = 'cocos2dx_getXOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return x
end

 
function cocos2dx_getYOfChild(Cocos2dxElement)
	local info = ''
	local y = Cocos2dxElement:getY()
	info = 'cocos2dx_getYOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return y
end


function cocos2dx_getDxOfChild(Cocos2dxElement)
	local info = ''
	local dx = Cocos2dxElement:getDx()
	info = 'cocos2dx_getDxOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return dx
end

 
function cocos2dx_getDyOfChild(Cocos2dxElement)
	local info = ''
	local dy = Cocos2dxElement:getDy()
	info = 'cocos2dx_getDyOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return dy
end

 
function cocos2dx_getPathOfChild(Cocos2dxElement)
	local info = ''
	local path = Cocos2dxElement:getPath()
	info = 'cocos2dx_getPathOfChild: '..tostring(Cocos2dxElement)..'\n'
	if Debug then log(info) end
	return path
end

 
function cocos2dx_getControl_XY(id, key, ctext, classpath)
	local info = ''
	local result, Temp_x, Temp_y, Temp_dx, Temp_dy = Android:cocos2dx_getControlerRect(id, key, ctext, classpath)
	local X = Temp_x + Temp_dx/2
	local Y = Temp_y + Temp_dy/2
	if result then
		info = 'cocos2dx_getControl_XY true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	else
		info = 'cocos2dx_getControl_XY false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	end
	if Debug then log(info) end
	return result,X, Y
end

function cocos2dx_findControlerAndMove(id_1, key_1, ctext_1, classpath_1,id_2, key_2, ctext_2, classpath_2, path) 
	local result1, x1, y1, dx1, dy1 = Android:cocos2dx_getControlerRect(id_1, key_1, ctext_1, classpath_1)
	local result2, x2, y2, dx2, dy2 = Android:cocos2dx_getControlerRect(id_2, key_2, ctext_2, classpath_2)
	move(x1 + dx1/2, y1 + dy1/2, x2 + dx2/2, y2 + dy2/2, path)
end

 
function cocos2dx_longTouch(id, key, ctext, classpath, TouchTime, path) 
	local info = ''
	local temp_clicked = false
	if path == 0 or path == nil then
		temp_clicked = Android:cocos2dx_click(id, key, ctext, classpath, 1)
		_sleep(TouchTime)
		Android:cocos2dx_click(id, key, ctext, classpath, 2)
	else 
		temp_clicked = Android:cocos2dx_click(id, key, ctext, classpath, 1, path)
		_sleep(TouchTime)
		Android:cocos2dx_click(id, key, ctext, classpath, 2) 
	end
	if temp_clicked then
		info = 'cocos2dx_longTouch true: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n'
	else
		info = 'cocos2dx_longTouch false: '..tostring(id)..', '..key..', '..ctext..', '..classpath..'\n' 
	end
	if Debug then log(info) end
	return temp_clicked
end

 
function cocos2dx_getControlContext(ctext)
	local info = ''
	local isFind,Cocos2dxContainer = Android:cocos2dx_getControlContext(ctext)
	info = 'cocos2dx_getControlContext: '..tostring(ctext)..'\n'
	if Debug then log(info) end
	return isFind, Cocos2dxContainer
end

 
function cocos2dx_getAllControl()
	local info = ''
	local isFind, Cocos2dxContainer = Android:cocos2dx_getAllControl()
	info = 'cocos2dx_getAllControl: '..'\n'
	if Debug then log(info) end
	return isFind, Cocos2dxContainer
end


function TimeMarker(CaseN) --以当前时间命名的图片路径
	local path
	if string.find(CaseN, '%d') then
		path = CasePath..CaseN..'/'..getSystemTime('yyyyMMdd-HHmmss')..'.jpg'
	else
		path = ResultPath..CaseN..'/'..getSystemTime('yyyyMMdd-HHmmss')..'.jpg'
	end
	return path
end

 --- 可选事件类型的点击操作
  -- @within 2-Gesture
  -- @number x 元素x坐标值
  -- @number y 元素y坐标值
  -- @number record_resolution_x 录制手机的x轴分辨率
  -- @number record_resolution_y 录制手机的y轴分辨率
  -- @number event 点击类型 0-click 1-down 2-up
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
  -- @usage click_XYByEvent(100,200,1680,1920,0,TimeMarker(CaseN))
function click_XYByEvent(x, y, record_resolution_x, record_resolution_y, event, path)
	local info = ''
	local resolution_x, resolution_y = Android:getScreenResolution()
	local X = (x*resolution_x)/record_resolution_x
	local Y = (y*resolution_y)/record_resolution_y
	if path == 0 or path == nil then
		Android:click(X,Y,event)
	else
		Android:click(X, Y, event, path)
	end
	info = 'click_XYByEvent:'..tostring(X)..', '..tostring(Y)..', '..tostring(event)..'\n' 
	if Debug then log(info) end
end
 
 --- 按屏幕相对位置进行点击
  -- @within 2-Gesture
  -- @number px 元素x坐标值所占屏幕位置的百分比
  -- @number py 元素y坐标值所占屏幕位置的百分比
  -- @number clicktime 点击后的预留时间,单位ms
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
  -- @usage clickpx(0.2, 0.3, 6000, TimeMarker(CaseN))
function clickpx(px, py, clicktime, path)
	action = 'clickpx'
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':clickpx false '..getSystemTimemap()) 
	local info = ''
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : clickpx')
	end
	if path == 0 or path == nil then
		Android:clickpx(px, py, 0)
	else
		Android:clickpx(px, py, 0, path)
	end
	sleep(clicktime)
	local resolution_x, resolution_y = Android:getScreenResolution()
	autoCP('', 0, 0, resolution_x, resolution_y, px, py)
	info = 'step '..stepId..' > clickpx: '..tostring(px)..', '..tostring(py)..'\n' 
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n')
	getHookVersion()
end

 --- 获取当前屏幕分辨率
  -- @within 1-General
  -- @treturn {number,number} 屏幕的x,y分辨率
  -- @usage local x,y = getScreenResolution()
function getScreenResolution()
	local info = ''
	local x,y = Android:getScreenResolution()
	info = 'getScreenResolution: '..'\n' 
	if Debug then log(info) end
	return x, y
end 

 --- 检查被测包是否已安装成功
 -- @within 1-General
 -- @string PackageName 测试包的名字
 -- @treturn boolean 安装成功返回true,否则返回false
 -- @usage local isInstalled = isInstall('com.tencent.qqmusic')
function isInstall(PackageName) 
	local info = ''
	local result = false
	result = Android:isInstall(PackageName)
	info = 'isInstall '..tostring(result)..': '..PackageName..'\n' 
	if Debug then log(info) end
	return result
end

 --- 让程序睡眠 N毫秒
 -- @within 1-General
 -- @number n 单位ms
 -- @usage sleep(4000)
function sleep(n)
	if isAutoTest then
		_cacheSleep(n)
	else 
		sleep_original(n)
	end
end

function sleep_original(n)
	local info = ''
	local sleepTime = n/1000
	local intTime = tonumber(string.format('%d', sleepTime))
	local floatTime = tonumber(string.sub(string.format('%.3f', sleepTime), -3))
	for i=1, intTime do

		Android:mSleep(1000)
	end
	if floatTime ~= 0 then
		
		Android:mSleep(floatTime)
	end
	info = 'sleep: '..tostring(n)..'\n' 
	if Debug then log(info) end
end

 --- 截屏并做区域标记
  -- @within 1-General
  -- @number x 区域边框左上角x坐标值
  -- @number y 区域边框左上角y坐标值
  -- @number dx 区域宽度
  -- @number dy 区域高度
  -- @string path 截屏后图片保存路径
  -- @usage snapshotScreen(100,100,200,200,TimeMarker(CaseN))
function snapshotScreen(x, y, dx, dy, path)
	local info = ''
	Android:snapshotScreen(x, y, dx, dy, path)
	info = 'snapshotScreen: '..tostring(x)..', '..tostring(y)..', '..tostring(dx)..', '..tostring(dy)..'\n' 
	if Debug then log(info) end
end

 --- 截屏整个屏幕并自定义显示标签
  -- @within 1-General
  -- @string path 截屏后图片保存路径
  -- @string tag 自定义标签显示内容,省略则不显示标签
  -- @usage snapshotWholeScreen(TimeMarker(CaseN))
  -- @usage snapshotWholeScreen(TimeMarker(CaseN),'tag_name')
function snapshotWholeScreen(path, tag)
	local info = ''
	if tag == nil then
		Android:snapshotScreen(path)
		info = 'snapshotWholeScreen: '..tostring(path)..'\n' 
	else
		Android:snapshotScreen(path, tag)
		info = 'snapshotWholeScreen: '..tostring(path)..', '..tostring(tag)..'\n' 
	end
	if Debug then log(info) end
end

 --- 将信息复制进剪切板中,执行后必须预留时间
  -- @within 1-General
  -- @string content 要复制到剪切板中的信息
  -- @usage setClipboardText('test for kat')
function setClipboardText(content)
	local info = ''
	Android:setClipboarText(content)
	info = 'setClipboardText: '..content..'\n' 
	if Debug then log(info) end
end

 --- 得到剪切板内容
  -- @within 1-General
  -- @treturn string 剪切板内容
  -- @usage local content = getClipboardText()
function getClipboardText()
	local info = ''
	local content = Android:getClipboarText()
	info = 'getClipboardText: '..'\n' 
	if Debug then log(info) end
	return content
end

 --- 菜单Hard Key:menu(少部分手机不适用,慎用)
  -- @within 2-Gesture
  -- @number touchTime 点击持续时间,单位为ms
  -- @usage menu(500)
function menu(touchTime)
	local info = ''
	Android:menu(touchTime)
	info = 'menu: '..tostring(touchTime)..'\n' 
	if Debug then log(info) end
end

 --- 主界面Hard Key:home(少部分手机不适用,慎用)
  -- @within 2-Gesture
  -- @number touchTime 点击持续时间,单位为ms
  -- @usage home(500)
function home(touchTime)
	local info = ''
	Android:home(touchTime)
	info = 'home: '..tostring(touchTime)..'\n' 
	if Debug then log(info) end
end

 --- 返回Hard Key:back
  -- @within 2-Gesture
  -- @number touchTime 点击持续时间,单位为ms
  -- @usage back(500)
function back(touchTime)
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':back false '..getSystemTimemap())
	action = 'back' 
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : back')
	end
	_snapshotWholeScreen(TimeMarker(Case_Name), 'back')
	_sleep(2500)
	local info = ''
	Android:back(touchTime)
	autoCP('back键', 0, 0, 0, 0, 0, 0)
	info = 'back: '..tostring(touchTime)..'\n' 
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
end

--- 向main.lua中添加lua执行模块
 -- @within 1-General
 -- @string luaPath 模块执行全路径
 -- @usage addLuaPlan('/sdcard/kat/Init.lua')
function addLuaPlan(luaPath)
	Android:addLuaPlan(luaPath)
end

 --- 弹出toast消息
  -- @within 1-General
  -- @string data 准备弹出的消息
  -- @number time 显示toast的属性,0表示短显示,1表示长显示
  -- @usage notifyMessage('toast message in phone', 0)
function notifyMessage(data, time)
	local info = ''
	local data = tostring(data)
	if time == nil or time == 0 then
		Android:notifyMessage(data)
	else
		Android:notifyMessage(data, 1)
	end
	info = 'notifyMessage: '..data..'\n' 
	if Debug then log(info) end
end

 --- 播放通知铃声
  -- @within 1-General
  -- @string path mp3文件全路径
  -- @usage notifyVoice('/mnt/sdcard/TestTool/Alarm_Kapalai.mp3')
function notifyVoice(path)
	Android:notifyVoice(path)
end
	
--- 启动应用程序,如果已启动,则kill掉后再重新启动,如果没有启动,则直接启动
 -- @within 1-General
 -- @string pkgName 测试包的名字
 -- @treturn boolean 成功启动返回true,失败返回false
 -- @usage restartApp('com.tencent.qqmusic')
function restartApp(pkgName)
	local info = ''
	local result = false
	endApp(pkgName)
	Android:notifyMessage('Test app init!', 1)
	Android:notifyMessage('--- Start App ---')
	_sleep(700)
	Android:startApp(pkgName)
	if CURRENT_TOOLS == 'kat' then sleep(7000) end
	for i=1, 10 do
		if _isForeground(pkgName) then --应用是否被拉到前台
			result = true
			break
		else
			print('被测应用启动失败--!'..i)
			sleep(3000)
		end
	end
	_shell('ps > /sdcard/kat/Result/ps_'..Case_Name..'.txt')
	info = 'restartApp '..tostring(result)..': '..pkgName..'\n' 
	if Debug then log(info) end
	getHookVersion()
	return result
end

 --- 启动应用程序
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @usage startApp('com.tencent.qqmusic')
function startApp(pkgName)
	local info = ''
	Android:startApp(pkgName)
	if (Performance and (PackageType =='cocos2dx')) then 
		sleep(15*1000)
		cocos2dx_fps_start() 
	end
	info = 'startApp: '..pkgName..'\n' 
	if Debug then log(info) end
end

--- 关闭应用程序
 -- @within 1-General
 -- @string pkgName 应用程序包名
 -- @usage endApp('com.tencent.qqmusic')
function endApp(pkgName)
	local info = ''
	if pkgName == nil or pkgName == '' then
		print('pkgName is null, please check!!')
	else
		Android:endApp(pkgName)
	end
	info = 'endApp: '..pkgName..'\n' 
	if Debug then log(info) end
end

 --- 将应用切换至后台
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @usage backgroundApp('com.tencent.qqmusic')
function backgroundApp(pkgName)
	local info = ''
	Android:backgroundApp(pkgName)
	info = 'backgroundApp: '..pkgName..'\n' 
	if Debug then log(info) end
end

 --- 将处在后台的应用切换至前台
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @usage resumeApp('com.tencent.qqmusic')
function resumeApp(pkgName)
	local info = ''
	Android:resumeApp(pkgName)
	info = 'resumeApp: '..pkgName..'\n' 
	if Debug then log(info) end
end

 --- 安装应用程序
  -- @within 1-General
  -- @string path apk的完整路径
  -- @treturn {boolean, string} 安装成功返回true并且返回安装应用程序耗时,失败返回false
  -- @usage local result,installTime = installApp('/sdcard/kat/demo.apk')
function installApp(path)
	local info = ''
	local installTime = '-'
	local result = false
	if _fileIsExist(path) then
		local startTime = getSystemTimemap()/1000
		result = Android:installAPP(path)
		local endTime  = getSystemTimemap()/1000
		if result then
			installTime = string.format('%.3f', endTime - startTime)
		else
			snapshotWholeScreen(ResultPath, path..' install fail !')
		end
	else
		result = 'false '..path..' is not found'
	end
	info = 'installApp '..path..': '..tostring(result)..' ->'..installTime..'s\n'
	if Debug then log(info) end
	return result, installTime
end

 --- 清除软件应用数据
  -- @within 1-General
  -- @string pkgname 软件包名
  -- @usage clearAppData('com.tencent.mobileqq')
function clearAppData(pkgname)
	local info = ''
	local result = isInstall(pkgname)
	if result then
		Android:notifyMessage('Clear app data!')
		endApp(pkgname)
		_sleep(700)
		if Android:getAndroidSDK() > 19 then
			Android:runShCommand('/data/local/tmp/utest_shell -c "pm clear '..pkgname..'"')
		else
			Android:runShCommand('pm clear '..pkgname)
		end
		_sleep(700)
	end
	info = 'clearAppData '..tostring(result)..': '..pkgname..'\n' 
	if Debug then log(info) end
end

 --- 卸载应用程序
  -- @within 1-General
  -- @string pkgName 安装包名字
  -- @treturn string 卸载时间
  -- @usage local uninstallTime = uninstallApp('com.tencent.qqmusic')
function uninstallApp(pkgName)
	local info = ''
	local uninstallTime = '-'
	local result = false
	if isInstall(pkgName) then
		local startTime = getSystemTimemap()/1000
		result = Android:uninstallApp(pkgName)
		local endTime = getSystemTimemap()/1000
		uninstallTime =  string.format('%.3f', endTime - startTime)
	end
	info = 'uninstallApp: '..pkgName..': '..tostring(result)..', uninstallTime: '..uninstallTime..'\n' 
	if Debug then log(info) end
	return uninstallTime
end

 --- 得到设备的SDK的APIlevel
  -- @within 1-General
  -- @treturn string 设备SDK的APIlevel
  -- @usage local API_LEVEL = getAndroidSDK()
function getAndroidSDK()
	local info = ''
	local API_LEVEL = tostring(Android:getAndroidSDK())
	info = 'getAndroidSDK'..'\n' 
	if Debug then log(info) end
	return API_LEVEL
end

 --- 得到设备的SDK版本号
  -- @within 1-General
  -- @treturn string 设备的SDK版本号
  -- @usage local SDK_VERSION = getAndroidVersion()
function getAndroidVersion()
	local info = ''
	local SDK_VERSION = Android:getAndroidVersion()
	info = 'getAndroidVersion'..'\n' 
	if Debug then log(info) end
	return SDK_VERSION
end

 --- 得到设备的名字
  -- @within 1-General
  -- @treturn string 设备的名字
  -- @usage local DEVICE_NAME = getDeviceName()
function getDeviceName()
	local info = ''
	local DEVICE_NAME = Android:getDeviceName()
	info = 'getDeviceName'..'\n' 
	if Debug then log(info) end
	return DEVICE_NAME
end

 --- 得到应用程序的名字
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @treturn string 应用程序名字
  -- @usage local app_name = getAppName('com.tencent.qqmusic')
function getAppName(pkgName)
	local info = ''
	local app_name = Android:getAppName(pkgName)
	info = 'getAppName: '..tostring(pkgName)..'\n'
	if Debug then log(info) end
	return app_name
end

 --- 获得应用程序主activity名
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @treturn mainactivity 应用程序的主activity名
  -- @usage local appMainActivity = getMainActivity('com.tencent.qqmusic')
function getMainActivity(pkgName)
	local mainActivity = ''
	if Android:isInstall(pkgName) then
		mainActivity = pkgName..'/'..Android:getMainActivity(pkgName)
	else
		print(pkgName..' is not installed!!')
	end
	return mainActivity
end

 --- 获得应用程序安装完成的app所在的具体位置
  -- @within 1-General
  -- @string pkgName 应用程序包名
  -- @treturn string App安装的位置
  -- @usage local appPath = getApkPath('com.tencent.qqmusic')
function getApkPath(pkgName)
	local apkPath = ''
	if Android:isInstall(pkgName) then
		apkPath = Android:getApkPath(pkgName)
	else
		print(pkgName..' is not installed!!')
	end
	return apkPath
end

---获得应用当前时刻接受到的流量字节
 -- @within 1-General
 --@string pkgName 应用程序包名
 --@treturn number 当前时刻接受流量值,单位Bytes
 --@usage local Rx = getUidRxBytes('com.qzone')
function getUidRxBytes(pkgName)
	local info = ''
	local Rx = Android:getUidRxBytes(pkgName)
	info = 'getUidRxBytes: '..pkgName..'\n'
	if Debug then log(info) end
	return Rx
end

---获得应用当前时刻发送出的流量字节
 -- @within 1-General
 --@string pkgName 应用程序包名
 --@treturn number 当前时刻发送的流量值,单位Bytes
 --@usage local Tx = getUidTxBytes('com.qzone')
function getUidTxBytes(pkgName)
	local info = ''
	local Tx = Android:getUidTxBytes(pkgName)
	info = 'getUidTxBytes: '..pkgName..'\n'
	if Debug then log(info) end
	return Tx
end

---得到top进程包名
 -- @within 1-General
 --@treturn string top进程包名
 --@usage local top_packagename = getTopProcessPkgName()
function getTopProcessPkgName()
	local info = ''
	local pkg = Android:getTopProcessPkgName()
	info = 'getTopProcessPkgName'..'\n'
	if Debug then log(info) end
	return pkg
end

---判断指定包是否前台可见
 -- @within 1-General
 --@string pkgname 应用程序包名
 --@treturn boolean 前台可见返回true,否则返回false
 --@usage local isForegrouded = isForeground('com.tencent.qqmusic')
function isForeground(pkgname)
	local info = ''
	local result = false
	result = Android:isforeground(pkgname)
	info = 'isForeground: '..tostring(pkgname)..'\n'
	if Debug then log(info) end
	return result
end

function initWebView()
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':webviewInit false '..getSystemTimemap()) 
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : webviewInit')
	end
	local info = ''
	Android:initWebView()
	info = 'initWebView'..'\n' 
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
end

function findTextAndClick_WebView(ctext, path)
	local info = ''
	local findTextAndClick_WebView_result = false
	if path == nil or path == 0 then
		findTextAndClick_WebView_result = Android:click(-2, '', ctext, '', 0)
	else
		findTextAndClick_WebView_result = Android:click(-2, '', ctext, '', 0, path)
	end
	if findTextAndClick_WebView_result then
		info = 'findTextAndClick_WebView true: '..ctext..', '..path..'\n'
	else
		info = 'findTextAndClick_WebView false: '..ctext..', '..path..'\n'
	end
	if Debug then log(info) end
	return findTextAndClick_WebView_result
end

 --- 获取app的版本号
  -- @within 1-General
  -- @string pkgName 安装包名字
  -- @treturn string app的版本号
  -- @usage local myAppVersion = getVersionNumber('com.tencent.qqmusic')
function getVersionNumber(pkgName)
	local info = ''
	local myAppVersion = Android:getVersionNumber(pkgName)
	info = 'getVersionNumber: '..pkgName..'\n' 
	if Debug then log(info) end
	return myAppVersion
end

function shell(command)
	local info = ''
	local respond = Android:runShCommand(command)
	info = 'shell: '..command..'\n' 
	if Debug then log(info) end
	return respond
end

 --- 获取手机品牌信息
  -- @within 1-General
  -- @treturn string 手机品牌信息
  -- @usage local DEVICE_BRAND = getBRAND()
function getBRAND()
	local info = ''
	local DEVICE_BRAND = Android:getBRAND()
	info = 'getBRAND: '..'\n' 
	if Debug then log(info) end
	return DEVICE_BRAND
end

 --- 拉起指定的桌面应用,出现多个桌面时,如何选择默认
  -- @within 1-General
  -- @string pkgName 桌面应用包名
  -- @usage setDefaultlauncher('com.tencent.qlauncher')
function setDefaultlauncher(pkgName)
	local info = ''
	Android:setDefaultlauncher(pkgName)
	info = 'setDefaultlauncher: '..pkgName..'\n' 
	if Debug then log(info) end
end

--- 输出logcat信息
 -- @within 1-General
 -- @string level 日志可选级别: 'i','e'
 -- @string tag 日志标签名字
 -- @string msg 日志信息
 -- @usage logcat('i', 'kat', 'kat-log')
function logcat(level, tag, msg)
	local info = ''
	Android:Log(level, tag, msg)
	info = 'logcat: '..level..', '..tag..', '..msg..'\n' 
	if Debug then log(info) end
end

 --- 检查当前是否连接到移动网络
  -- @within 4-Network
  -- @treturn boolean 连接移动网络则返回true,否则返回false
  -- @usage local isMobileConnected = isMobileConnect()
function isMobileConnect()
	local info = ''
	local result = Android:isMobileConnect()
	info = 'isMobileConnect'..'\n'
	if Debug then log(info) end
	return result
end

 --- 检查屏幕方向
  -- @within 1-General
  -- @treturn number 竖屏是0, 横屏是1
  -- @usage local screen_direction = isScreenOriatationPortrait()
function isScreenOriatationPortrait()
	local info = ''
	local direction = Android:isScreenOriatationPortrait()
	info = 'isScreenOriatationPortrait'..'\n'
	if Debug then log(info) end
	return direction
end

 --- 分割字符串
  -- @within 1-General
  -- @string szFullString 原始字符串
  -- @string szSeparator 分隔符
  -- @return table 分割后的字符串保存在一张表中
  -- @usage local splited_string_table = split('kat_is_not_bad' , '_')
function split(szFullString, szSeparator) 
	local info = ''
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	info = 'split: '..tostring(szFullString)..', '..tostring(szSeparator)..'\n'
	if Debug then log(info) end
	return nSplitArray
end

 --- 模拟传感器事件
  -- @within 1-General
  -- @string type 代表想要模拟的sensor类型(如'ACCELEROMETER')
  -- @string action 代表当前sensor功能的标识,(如 '摇')
  -- @usage sendSensorEvent('ACCELEROMETER', '摇')
function sendSensorEvent(type, action)
	local info = ''
	Android:sendSensorEvent(type, action)
	info = 'sendSensorEvent: '..tostring(type)..', '..tostring(action)..'\n'
	if Debug then log(info) end
end

 --- 4.2以上手机,打开设置中的GPU开关
  -- @within 1-General
  -- @usage startGpu()
function startGpu()
	local info = ''
	Android:startGpu()
	info = 'startGpu'..'\n'
	if Debug then log(info) end
end

 --- 4.2以上手机,关闭设置中的GPU开关
  -- @within 1-General
  -- @usage stopGpu()
function stopGpu()
	local info = ''
	Android:stopGpu()
	info = 'stopGpu'..'\n'
	if Debug then log(info) end
end

 --- 4.2以上手机,打开设置中的Msaa开关
  -- @within 1-General
  -- @usage startMsaa()
function startMsaa()
	local info = ''
	Android:startMsaa()
	info = 'startMsaa'..'\n'
	if Debug then log(info) end
end

 --- 4.2以上手机,关闭设置中的Msaa开关
  -- @within 1-General
  -- @usage stopMsaa()
function stopMsaa()
	local info = ''
	Android:stopMsaa()
	info = 'stopMsaa'..'\n'
	if Debug then log(info) end
end

 --- 捕获当前窗口并转化为bitmapcode
  -- @within 1-General
  -- @treturn string 64位的字符串
  -- @usage local bitmapcode = getWindowhash()
function getWindowhash()
	local info = ''
	local bitmapcode = Android:getWindowhash()
	info = 'getWindowhash'..'\n'
	if Debug then log(info) end
	return bitmapcode
end

 --- 比较页面相似度方法
  -- @within 1-General
  -- @string bitmapcode 需要比较相似性的页面指纹
  -- @treturn number 值越小,相似度越高
  -- @usage local value = compareSimilar(getWindowhash())
function compareSimilar(bitmapcode)
	local info = ''
	local value = Android:compareSimilar(bitmapcode)
	info = 'compareSimilar: '..tostring(bitmapcode)..'\n'
	if Debug then log(info) end
	return value
end

 --- 打开辅助功能
  -- @within 1-General
  -- @usage startKatAccessbility()
function startKatAccessbility()
	local info = ''
	Android:startKatAccessbility()
	info = 'startKatAccessbility\n'
	if Debug then log(info) end
end

 --- 解锁
  -- @within 1-General
  -- @usage disableKeyguard()
function disableKeyguard()
	print('into disableKeyguard')
	local info = ''
	local device_name = getDeviceName()
	Android:disableKeyguard()
	if device_name == 'vivo X3t' or device_name == 'vivo X3V' or device_name == 'vivo Xshot' or device_name == 'vivo Y22' or device_name == 'vivo X3L'  then
		shell('input keyevent 26')
	end
	info = 'disableKeyguard\n'
	if Debug then log(info) end
end

 --- 锁屏
  -- @within 1-General
  -- @usage reenableKeyguard()
function reenableKeyguard()
	print('into reenableKeyguard')
	local info = ''
	Android:reenableKeyguard()
	info = 'reenableKeyguard\n'
	if Debug then log(info) end
end 

 --- 输出自定义日志到log.txt
  -- @within 1-General
  -- @string info 自定义信息日志
  -- @usage print('print log info in /sdcard/kat/Result/log.txt')
function print(info)
	if type(info) == 'table' then
		info_n = #info
		local file = io.open(LogPath, 'a')
		file:write(getSystemTime('MM-dd HH:mm:ss')..': ['..Case_Name..'] print: table {')
		file:close()
		for i,v in ipairs(info) do
			local file = io.open(LogPath, 'a')
			if i ~= info_n then
				file:write(tostring(v)..', ')
			else
				file:write(tostring(v))
			end
			file:close()
		end
		local file = io.open(LogPath, 'a')
		file:write('}\n')
		file:close()
	else
		local file = io.open(LogPath, 'a')
		file:write(getSystemTime('MM-dd HH:mm:ss')..': ['..Case_Name..'] print: '..tostring(info)..'\n')
		file:close()
	end
end

 --- 创建文件并保存
  -- @within 5-File
  -- @string FolderPath 目标文件夹全路径
  -- @string FileName 目标文件名字
  -- @string content 要保存的数据记录
  -- @usage writeFileToFolder('/sdcard/kat/', 'FileName.txt', 'hello! kat')
function writeFileToFolder(FolderPath, FileName, content) 
	local info = ''
	if _fileIsExist(FolderPath) then
		Android:newFolder(FolderPath)
		_sleep(1500)
	end
	local FilePath = FolderPath..FileName
	local file = io.open(FilePath, 'a')
	file:write(Case_Name..':'..content)
	file:close()
	info = 'writeFileToFolder: '..FolderPath..', '..FileName..', '..content..'\n' 
	if Debug then log(info) end
end

function updateCaseFolder(CaseN) 
	local info = ''
	if string.find(CaseN, '%d') then
		Android:delete(CasePath..CaseN..'/')
		Android:newFolder(CasePath..CaseN..'/')
		if testEndIsCleanPic then
			if string.find(Android:getApiVersion(), '3.5') then
			--如果是3.5版本就不增加OK.txt标志位
			else
				Android:newFile(CasePath..CaseN..'/OK.txt') --若出现crash就删除OK.txt
			end
		end
	else
		Android:delete(ResultPath..CaseN..'/')
		Android:newFolder(ResultPath..CaseN..'/')
	end
	info = 'updateCaseFolder: '..CaseN..'\n' 
	if Debug then log(info) end
end

 --- 创建目录
  -- @within 5-File
  -- @string path 目录全路径
  -- @usage newFolder('/sdcard/kat/Result/')
function newFolder(path)
	local info 
	Android:newFolder(path)
	info = 'newFolder: '..path..'\n' 
	if Debug then log(info) end
end

 --- 创建文件
  -- @within 5-File
  -- @string path 文件全路径,文件依赖路径必须预先存在
  -- @usage newFile('/sdcard/kat/Result/newfile.txt')
function newFile(path)
	local info = ''
	Android:newFile(path)
	info = 'newFile: '..path..'\n' 
	if Debug then log(info) end
end

 --- 复制一份文件到指定文件夹,目标文件夹需要已存在
  -- @within 5-File
  -- @string FilePath 源文件全路径
  -- @string FolderPath 目标文件夹全路径
  -- @usage copyFileToFolder('/sdcard/kat/Result/Case/testFile.png', '/sdcard/kat/')
function copyFileToFolder(FilePath,FolderPath)
	local info = ''
	Android:copyFileToFolder(FilePath,FolderPath)
	info = 'copyFileToFolder: '..FilePath..', '..FolderPath..'\n' 
	if Debug then log(info) end
end

 --- 调用媒体扫描器扫描指定文件夹
  -- @within 5-File
  -- @string FolderPath 被扫描的文件夹的路径
  -- @usage scanFolder('/sdcard/DICM/testPicPackage/')
function scanFolder(FolderPath)
	local info = ''
	Android:scanFolder(FolderPath)
	info = 'scanFolder: '..FolderPath..'\n' 
	if Debug then log(info) end
end

 --- 复制源文件夹内的资源到目标文件夹
  -- @within 5-File
  -- @string SourcePath 源文件夹的全路径
  -- @string DestinationPath 目标文件夹的全路径
  -- @usage copyFolderToFolder('/sdcard/kat/Folder1/', '/sdcard/kat/Folder2/')
function copyFolderToFolder(SourcePath,DestinationPath)
	local info = ''
	Android:copyFolderToFolder(SourcePath,DestinationPath)
	info = 'copyFolderToFolder: '..SourcePath..', '..DestinationPath..'\n' 
	if Debug then log(info) end
end

 --- 将指定文件夹打包成zip文件,打包完成后放到指定路径,方法中有30秒延时
  -- @within 5-File
  -- @string srcFilePath 文件夹全路径
  -- @string zipFilePath 压缩文件全路径
  -- @usage zipFolder('/sdcard/kat/Result/', 'sdcard/kat/Result.zip')
function zipFolder(srcFilePath, zipFilePath)
	local info = ''
	Android:zipFolder(srcFilePath, zipFilePath)
	_sleep(1000*30)
	info = 'zipFolder: '..srcFilePath..', '..zipFilePath..'\n' 
	if Debug then log(info) end
end

 --- 删除文件或者文件夹
  -- @within 5-File
  -- @string Path 文件或者文件夹全路径
  -- @usage delete('/sdcard/kat/Deleted_Folder/'); delete('/sdcard/kat/deleted_log.txt')
function delete(Path)
	local info = ''
	Android:delete(Path)
	info = 'delete: '..Path..'\n' 
	if Debug then log(info) end
end

 --- 判断文件是否存在
  -- @within 5-File
  -- @string filePath 文件全路径
  -- @treturn boolean 存在返回true,不存在返回false
  -- @usage local isExisted = fileIsExist('/sdcard/kat/Your_file_name.txt')
function fileIsExist(filePath) 
	local info = ''
	local result = false
	local file = io.open(filePath, 'rb')
	if file then 
		file:close()
		result = true
	end
	info = 'fileIsExist '..tostring(result)..': '..filePath..'\n'
	if Debug then log(info) end
	return result
end

--- 向左滑动,自定义滑动次数
 -- @within 2-Gesture
 -- @number sleepTime 滑动后等待时间 单位是ms
 -- @number moveTimes 滑动次数
 -- @string path 截屏后图片保存路径,如果为0或者省略,则不截屏
 -- @usage leftMove(2000, 4, TimeMarker(CaseN))
function leftMove(sleepTime, moveTimes, path)
	local resolution_x, resolution_y = Android:getScreenResolution()
	action = 'leftMove'
	local info = ''
	local i = 1
	while i < moveTimes + 1 do
		if isPlayToast then
			_notifyMessage('向左滑动：第'..i..'次--共'..moveTimes..'次')
		end
		if path == 0 or path == nil then 
			--不截图
		else
			path = TimeMarker(Case_Name)
		end
		_move(9*resolution_x/10, resolution_y/2, resolution_x/10, resolution_y/2, path)
		log('向左滑动：第'..i..'次--共'..moveTimes..'次\n')
		_sleep(sleepTime)
		i = i + 1 
	end
	autoCP(tostring(moveTimes)..'次', 0, 0, 0, 0, 0, 0)
	info = 'leftMove: '..tostring(sleepTime)..', '..tostring(moveTimes)..'\n'
	if Debug then log(info) end
end

 --- 向右滑动,自定义滑动次数
  -- @within 2-Gesture
  -- @number sleepTime 滑动后等待时间，单位是ms
  -- @number moveTimes 滑动次数
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不截屏
  -- @usage rightMove(2000,4,TimeMarker(CaseN))
function rightMove(sleepTime, moveTimes, path) 
	local resolution_x, resolution_y = Android:getScreenResolution()
	action = 'rightMove'
	local info = ''
	local i = 1
	while i < moveTimes + 1 do
		if isPlayToast then
			_notifyMessage('向右滑动：第'..i..'次--共'..moveTimes..'次')
		end
		if path == 0 or path == nil then 
			--不截图
		else
			path = TimeMarker(Case_Name)
		end
		_move(resolution_x/10, resolution_y/2, 9*resolution_x/10, resolution_y/2, path)
		log('向右滑动：第'..i..'次--共'..moveTimes..'次\n')
		_sleep(sleepTime)
		i = i + 1 
	end
	autoCP(tostring(moveTimes)..'次', 0, 0, 0, 0, 0, 0)
	info = 'rightMove: '..tostring(sleepTime)..', '..tostring(moveTimes)..'\n'
	if Debug then log(info) end
end

 --- 向上滑动,自定义滑动次数
  -- @within 2-Gesture
  -- @number sleepTime 滑动后等待时间，单位是ms
  -- @number moveTimes 滑动次数
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不截屏
  -- @usage upMove(2000,4,TimeMarker(CaseN))
function upMove(sleepTime, moveTimes, path) --向上滑
	local resolution_x, resolution_y = Android:getScreenResolution()
	action = 'upMove'
	local info = ''
	local i = 1
	while i < moveTimes + 1 do
		if isPlayToast then
			_notifyMessage('向上滑动：第'..i..'次--共'..moveTimes..'次')
		end
		if path == 0 or path == nil then 
			--不截图
		else
			path = TimeMarker(Case_Name)
		end
		_move(resolution_x/2, 4*resolution_y/5, resolution_x/2, resolution_y/5, path)
		log('向上滑动：第'..i..'次--共'..moveTimes..'次\n')
		_sleep(sleepTime)
		i = i + 1 
	end
	autoCP(tostring(moveTimes)..'次', 0, 0, 0, 0, 0, 0)
	info = 'upMove: '..tostring(sleepTime)..', '..tostring(moveTimes)..'\n'
	if Debug then log(info) end
end

 --- 向下滑动,自定义滑动次数
  -- @within 2-Gesture
  -- @number sleepTime 滑动后等待时间，单位ms
  -- @number moveTimes 滑动次数
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不截屏
  -- @usage downMove(2000,4,TimeMarker(CaseN))
function downMove(sleepTime, moveTimes, path) --向下滑
	local resolution_x, resolution_y = Android:getScreenResolution()
	action = 'downMove'
	local info = ''
	local i = 1
	while i < moveTimes + 1 do
		if isPlayToast then
			_notifyMessage('向下滑动：第'..i..'次--共'..moveTimes..'次')
		end
		if path == 0 or path == nil then 
			--不截图
		else
			path = TimeMarker(Case_Name)
		end
		_move(resolution_x/2, resolution_y/5, resolution_x/2, 4*resolution_y/5, path)
		log('向下滑动：第'..i..'次--共'..moveTimes..'次\n')
		_sleep(sleepTime)
		i = i + 1 
	end
	autoCP(tostring(moveTimes)..'次', 0, 0, 0, 0, 0, 0)
	info = 'downMove: '..tostring(sleepTime)..', '..tostring(moveTimes)..'\n'
	if Debug then log(info) end
end

 --- 获取起始与终止坐标并滑动
  -- @within 2-Gesture
  -- @number x1 起始x坐标值
  -- @number y1 起始y坐标值
  -- @number x2 终止x坐标值
  -- @number y2 终止y坐标值
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
  -- @usage move(100,100,200,200,TimeMarker(CaseN))
function move(x1, y1, x2, y2, path) 
	local info = ''
	if path == nil or path == 0 then
		Android:move(x1, y1, x2, y2)
	else
		Android:move(x1, y1, x2, y2, path)
	end
	info = 'move: '..tostring(x1)..', '..tostring(y1)..', '..tostring(x2)..', '..tostring(y2)..'\n'
	if Debug then log(info) end
end

 --- 多点滑动，比如手势密码类滑动操作
  -- @within 2-Gesture
  -- @string info 多点滑动信息,如'100,100:200:200,300:300',每个冒号代表一个点的坐标
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
  -- @usage multipleMove('50,50:100,100:400,400', TimeMarker(CaseN))
function multipleMove(info, path)
	if path == nil or path == 0 then 
		Android:move(info, 0, path)
	else
		Android:move(info, 0)
	end
end

 --- 长按(x1,y1)一段时间,然后滑动到(x2,y2)
  -- @within 2-Gesture
  -- @number x1 起始点x坐标值
  -- @number y1 起始点y坐标值
  -- @number x2 终止点x坐标值
  -- @number y2 终止点y坐标值
  -- @number BeginTouchTime 长按持续时间，单位是ms
  -- @string path 截屏后图片保存路径,如果为0或者省略,则不做截屏
  -- @usage longTouchAndMove(50,50,100,100,4000,TimeMarker(CaseN))
function longTouchAndMove(x1, y1, x2, y2, BeginTouchTime, path)
	local info = ''
	if path == nil or path == 0 then
		Android:longTouchAndMove(x1, y1, x2, y2, BeginTouchTime)
	else
		Android:longTouchAndMove(x1, y1, x2, y2, BeginTouchTime, path)
	end
	info = 'longTouchAndMove: '..tostring(x1)..', '..tostring(y1)..', '..tostring(x2)..', '..tostring(y2)..', '..tostring(BeginTouchTime)..'\n'
	if Debug then log(info) end
end

 --- 自定义模式滑动
  -- @within 2-Gesture
  -- @number x1 起始点x坐标值
  -- @number y1 起始点y坐标值
  -- @number x2 终止点x坐标值
  -- @number y2 终止点y坐标值
  -- @number mode 滑动模式--111有按下有抬起,110没有抬起,011没有按下
  -- @usage moveByMode(50,50,100,100,110)
function moveByMode(x1, y1, x2, y2, mode)
	local info = ''
	Android:move(x1, y1, x2, y2, mode)
	info = 'moveByMode: '..tostring(x1)..', '..tostring(y1)..', '..tostring(x2)..', '..tostring(y2)..', '..tostring(mode)..'\n'
	if Debug then log(info) end
end

 --- 双指滑动
  -- @within 2-Gesture
  -- @number xOneStart 起始点(One)x坐标值
  -- @number yOneStart 起始点(One)y坐标值
  -- @number xTwoStart 起始点(Two)x坐标值
  -- @number yTwoStart 起始点(Two)y坐标值
  -- @number xOneEnd 终止点(One)x坐标值
  -- @number yOneEnd 终止点(One)y坐标值
  -- @number xTwoEnd 终止点(Two)x坐标值
  -- @number yTwoEnd 终止点(Two)y坐标值
  -- @number record_resolution_x 录制手机的x分辨率
  -- @number record_resolution_y 录制手机的y分辨率
  -- @string path 截屏后图片保存路径
  -- @usage fingerTouchMove(40, 40, 120, 120, 80, 80, 200, 200, 1080, 1920, TimeMarker(CaseN))
function fingerTouchMove(xOneStart, yOneStart, xTwoStart, yTwoStart, xOneEnd, yOneEnd, xTwoEnd, yTwoEnd, record_resolution_x, record_resolution_y, path)
	action = 'fingerTouchMove'
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':fingerTouchMove false '..getSystemTimemap()) 
	if isPlayToast then
		_notifyMessage('Step'..stepId..' : fingerTouchMove')
	end
	local resolution_x, resolution_y = Android:getScreenResolution()
	local info = ''
	local X1_start = (xOneStart*resolution_x)/record_resolution_x
	local Y1_start = (yOneStart*resolution_y)/record_resolution_y
	local X2_start = (xTwoStart*resolution_x)/record_resolution_x
	local Y2_strat = (yTwoStart*resolution_y)/record_resolution_y
	local X1_end = (xOneEnd*resolution_x)/record_resolution_x
	local Y1_end = (yOneEnd*resolution_y)/record_resolution_y
	local X2_end = (xTwoEnd*resolution_x)/record_resolution_x
	local Y2_end = (yTwoEnd*resolution_y)/record_resolution_y  
	Android:fingerTouchMove(X1_start, Y1_start, X2_start, Y2_strat, X1_end, Y1_end, X2_end, Y2_end, path)
	autoCP('', 0, 0, 0, 0, 0, 0)
	info = 'step '..stepId..' > fingerTouchMove: '..tostring(xOneStart)..', '..tostring(yOneStart)..', '..tostring(xTwoStart)..', '..tostring(yTwoStart)..', '..tostring(xOneEnd)..', '..tostring(yOneEnd)..', '..tostring(xTwoEnd)..', '..tostring(yTwoEnd)..', '..tostring(path)..'\n'
	if Debug then log(info) end
	stepId = stepId + 1
	write_file_video(VIDEO_INFO_PATH, ' true\n')
end

function setWifiEnable(isEnable)
	local info = ''
	local isSuccessed = Android:setWifiEnable(isEnable)
	info = 'setWifiEnable: '..tostring(isEnable)..'\n'
	if Debug then log(info) end
	return isSuccessed
end

function forgetWifi(wifiAP)
	local info = ''
	Android:forgetWifi(wifiAP)
	info = 'forgetWifi: '..tostring(wifiAP)..'\n'
	if Debug then log(info) end
end

function connectWifi(wifiAP, PassWord)
	local info = ''
	local isConnected = Android:connectWifi(wifiAP, PassWord)
	info = 'connectWifi: '..tostring(wifiAP)..', '..PassWord..'\n'
	if Debug then log(info) end
end


 --- 检查当前是否连接到wifi
  -- @within 4-Network
  -- @treturn boolean 连接wifi则返回true,否则返回false
  -- @usage local isWifiConnected = isWifiConnect()
function isWifiConnect()
	local info = ''
	local isWifiConnected = Android:isWifiConnect()
	info = 'isWifiConnect: '..tostring(isWifiConnected)..'\n'
	if Debug then log(info) end
	return isWifiConnected
end

 --- 打开蓝牙开关
  -- @within 4-Network
  -- @usage openBluetooth()
function openBluetooth()
	local info = ''
	Android:openBluetooth()
	info = 'openBluetooth\n'
	if Debug then log(info) end
end

 --- 关闭蓝牙开关
  -- @within 4-Network
  -- @usage closeBluetooth()
function closeBluetooth()
	local info = ''
	Android:closeBluetooth()
	info = 'closeBluetooth\n'
	if Debug then log(info) end
end

 --- 收起通知栏
  -- @within 1-General
  -- @usage collapseStatusBar()
function collapseStatusBar()
	local info = ''
	Android:collapseStatusBar()
	info = 'collapseStatusBar\n'
	if Debug then log(info) end
end

 --- 检查当前ip地址是否畅通
  -- @within 4-Network
  -- @string ip_adr 需要检查的ip地址
  -- @treturn boolean 畅通返回true,否则返回false
  -- @usage local isEnabled = isNetworkEnable('202.96.64.68')
function isNetworkEnable(ip_adr)
	local info = ''
	local isEnabled = Android:isNetworkEnable(ip_adr)
	info = 'isNetworkEnable('..ip_adr..'): '..tostring(isEnabled)..'\n'
	if Debug then log(info) end
	return isEnabled
end

 --- 当被测应用需要启动系统图库读取图片之前,设置指定路径的图片作为返回值,需要在操作之前调用,配合com.kapalai.picture使用
  -- @within 4-Network
  -- @string path 指定测试图片的位置信息
  -- @usage setPickPicture('sdcard/kat/test.jpg')
function setPickPicture(path)
	local info = ''
	Android:setPickPicture(path)
	info = 'setPickPicture'..'\n'
	if Debug then log(info) end
end

 --- 短信验证码
  -- @within 4-Network
  -- @string num 发送短信的号码
  -- @number timeout 搜索号码超时时间，单位s
  -- @treturn {boolean，string} 畅通返回true并且返回短信验证码,否则返回false
  -- @usage local result, smsInfo = getSmsCode('13356652546', 60)
function getSmsCode(num, timeout)
	local info = ''
	local startTime = os.time()
	local endTime = startTime + timeout
	local result = false
	local smsInfo = ''
	Android:SmSReceiver_start(num)
	while os.time() <= endTime do
		result, smsInfo = Android:SmSReceiver_get()
		if result then
			break
		end
		_sleep(5000)
	end
	Android:SmSReceiver_stop()
	info = 'getSmsCode '..tostring(result)..': '..tostring(smsInfo)..'\n'
	if Debug then log(info) end
	return result, smsInfo
end

--- 设置手机系统语言
 -- @within 1-General
 -- @string language 设置语言 比如（'zh'或者'en')
 -- @string country 设置国家 比如（'CN'或者'US'）
 -- @usage setLanguage('zh', 'CN')
function setLanguage(language, country)
	local  localLanguage = Android:getLanguage()
	if not (language == localLanguage) then
		_shell('pm grant com.kunpeng.kapalai.kat android.permission.CHANGE_CONFIGURATION')
	   Android:setLanguage(language, country)
    end
end

 --- 检查点语句
  -- @within 6-Assertion
  -- @bool isTrue 断言结果
  -- @string content 请用户定义断言失败时的描述
  -- @usage checkPoint(false,'此时没有找到xxx控件元素')
function checkPoint(isTrue,content)
	local mtype = "fw_cp"
	local function_info = ''
	local result = isTrue
	local info = 'pass'
	if not isTrue then
		_snapshotWholeScreen(TimeMarker(Case_Name), 'fw_cp_fail')
		info = 'fail'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring(content)
	else
		info = 'pass'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring('Success')
	end
	--add into t_info, t_result
	t_info[#t_info + 1] = info
	t_result[#t_result + 1] = result 
	function_info = 'checkPoint: '..tostring(isTrue)..', '..content..'\n'
	if Debug then log(function_info) end
end

 --- 断言语句
  -- @within 6-Assertion
  -- @bool isTrue 断言结果,如果为false,则结束当前用例执行
  -- @string content 请用户定义断言失败时的描述
  -- @usage assert(false,'此时没有找到xxx控件元素')
function assert(isTrue,content)
	local mtype = 'fw_as'
	local function_info = ''
	local result = isTrue
	local info = 'pass'
	if not isTrue then
		_snapshotWholeScreen(TimeMarker(Case_Name), 'fw_as_fail')
		info = 'fail'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring(content)
		t_info[#t_info + 1] = info
		t_result[#t_result + 1] = result 
		collectResult()
		function_info = 'assert: '..tostring(isTrue)..', '..content..'\n'
		if Debug then log(function_info) end
		log('WIFI '..tostring(Android:isWifiConnect())..' | NET '..tostring(Android:isNetworkEnable('180.149.132.47'))..'\n')
		luaError()
	else
		info = 'pass'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring('Success')
		t_info[#t_info + 1] = info
		t_result[#t_result + 1] = result 
		function_info = 'assert: '..tostring(isTrue)..', '..'Success'..'\n'
		if Debug then log(function_info) end
	end
end

 --- 断言语句
  -- @within 6-Assertion
  -- @bool isTrue 断言结果,如果为false,则结束所有用例执行
  -- @string content 请用户定义断言失败时的描述
  -- @usage assert_final(false,'login failed')
function assert_final(isTrue,content)
	local mtype = 'fw_asf'
	local function_info = ''
	local result = isTrue
	local info = 'pass'
	if not isTrue then
		_snapshotWholeScreen(TimeMarker(Case_Name), 'fw_asf_fail')
		info = 'fail'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring(content)
		t_info[#t_info + 1] = info
		t_result[#t_result + 1] = result 
		collectResult()
		local assert_final_file = RootPath..'fw_asf.txt'
		local asf_f = io.open(assert_final_file,'a')
		asf_f:close()
		function_info = 'assert_final: '..tostring(isTrue)..', '..content..'\n'
		if Debug then log(function_info) end
		log('WIFI '..tostring(Android:isWifiConnect())..' | NET '..tostring(Android:isNetworkEnable('180.149.132.47'))..'\n')
		luaError()
	else
		info = 'pass'..CHECK_POINT_SEPARATOR..mtype..CHECK_POINT_SEPARATOR..tostring('Success')
		t_info[#t_info + 1] = info
		t_result[#t_result + 1] = result 
		function_info = 'assert_final: '..tostring(isTrue)..', '..'Success'..'\n'
		if Debug then log(function_info) end
	end
end

 --- 实现图片断言
  -- @within 6-Assertion
  -- @string describe 截图打印水印内容到图片上
  -- @usage check_point_pic('水印内容')
function check_point_pic(describe)
	--注意最好不要把checkpoint放到if语句中,或保证if和else里面都有相同的checkpoint
	if describe == nil then describe = '' end
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..': false '..getSystemTimemap())
	if isPlayToast then
		_notifyMessage('Step '..stepId..' : compare screenshot')
		_sleep(800)
	end
	local info = ''
	cp_pic_path = 'sdcard/kat/Result/case/'
	cp_pic_case_path = cp_pic_path..Case_Name..'/'
	local systemTimemap = getSystemTime('yyyyMMdd-HHmmss')
	readCPInfo(systemTimemap..'_cp-'..picCheckPointCounter..'.jpg', describe)
	_snapshotWholeScreen(cp_pic_case_path..systemTimemap..'_cp-'..picCheckPointCounter..'.jpg')
	_sleep(2000)
	os.remove(ACTION_INFO_PATH)
	info = 'step '..stepId..' > check_point_pic('..cp_pic_case_path..systemTimemap..'_cp-'..picCheckPointCounter..'.jpg)\n'
	picCheckPointCounter = picCheckPointCounter + 1
	if Debug then log(info) end
	write_file_video(VIDEO_INFO_PATH, ' true\n') 
	stepId = stepId + 1
	getHookVersion()
end 

function _check_point_pic(describe)
	if describe == nil then describe = '' end
	_sleep(3000)
	local systemTimemap = getSystemTime('yyyyMMdd-HHmmss')
	local cp_pic_path = CasePath..Case_Name..'/'..systemTimemap..'_cp-'..picCheckPointCounter..'.jpg'
	readCPInfo(systemTimemap..'_cp-'..picCheckPointCounter..'.jpg', describe)
	_snapshotWholeScreen(cp_pic_path)
	_sleep(2000)
	os.remove(ACTION_INFO_PATH)
	picCheckPointCounter = picCheckPointCounter + 1
end

 --- 人机交互自动化测试断言，发起后会弹窗并阻塞，直到人工确认后才继续脚本自动化运行
  -- @within 6-Assertion
  -- @string title 人机交互专项测试标题
  -- @string content 人机交互专项测试描述
  -- @usage interactive('听音识曲', '人工确认听歌操作流程')
function interactive(title, content)
	Android:interactive(title, content)
end


function autoCP(text, x, y, dx, dy, wPercent, hPercent)
	local info = ''
	local position = ''
	if action == 'tap' or action == 'clickpx' or action == 'back' or action == 'longTouch' or action == 'doubleClick' then
		position = '('..math.floor(x + dx*wPercent)..','..math.floor(y + dy*hPercent)..')'
	end 
	if text == '' then text = '操作' end
	if action == 'tap' or action == 'clickpx' or action == 'back' then
		info = '点击'
	elseif action == 'longTouch' then
		info = '长按'
	elseif action == 'doubleClick' then
		info = '双击'
	elseif action == 'inputText' then
		info = '输入:'
	elseif action == 'scroll' then
		info = '滑动'
	elseif action == 'fingerTouchMove' then
		info = '双指缩放'
	elseif action == 'leftMove' then
		info = '向左滑动'
	elseif action == 'rightMove' then
		info = '向右滑动'
	elseif action == 'upMove' then
		info = '向上滑动'
	elseif action == 'downMove' then
		info = '向下滑动'
	end
	_writeFile(ACTION_INFO_PATH, info..text..position..'\n')
	if isAutoCheckPoint and actionCounter%AUTO_CP_FREQUENCY == 0 then
		_check_point_pic()
	end
	actionCounter = actionCounter + 1
end


function readCPInfo(picPath, content)
	_writeFile(CHECK_POINT_INFO_PATH, picPath..'@')
	if _fileIsExist(ACTION_INFO_PATH) and content == '' then
		local file = io.open(ACTION_INFO_PATH,'r')
		local text = file:read("*all")
		file:close()
		local lines = _split(text, '\n')
		local length = #lines - 1
		for i=1, length do
			local info = lines[i]
			if i < length then
				_writeFile(CHECK_POINT_INFO_PATH, info..',')
			else
				_writeFile(CHECK_POINT_INFO_PATH, info..'')
			end
		end
	elseif not _fileIsExist(ACTION_INFO_PATH) and content == '' then
		_writeFile(CHECK_POINT_INFO_PATH, '无操作')
	end 
	_writeFile(CHECK_POINT_INFO_PATH, content..'--截图\n')
end

---深度遍历用,设置自定义登陆
 -- @within 3-Exploratory
 -- @string id 账号
 -- @string sn 密码
 -- @string login_key_text 登录按钮的 key 值 + "_" + 登录按钮的 text 值
 -- @string activity 登录页面的activity,可以通过录制工具获得
 -- @usage setNormalLogin('123','123456','key_登录', 'com.tencent.mobileqq.activity.SplashActivity')
function setNormalLogin(id, sn, login_key_text, activity)
	info = 'setNormalLogin > '..id..', '..sn..', '..login_key_text..', '..activity..'\n' 
	Android:setNormalLogin(id, sn, login_key_text, activity)
	if Debug then log(info) end
end

function topercent(f) 
	f = f*100
	local s = string.format('%.2f',f)
	s = s..'%'
	return s
end

function keyevent(Key, ClickTime)
	Android:keyevent(Key, ClickTime)
	_sleep(2000)
end

function setInjectProcessName(processName)
	Android:setInjectProcessName(processName)
end

function removeSpace(data) 
	local t = {}
	for w in string.gmatch(data, '%S+') do
		table.insert(t, w)
	end
	return t
end

function isNum(Data) 
	local len = string.len(Data)
	local c
	local x = -1
	for i=1,len do
		c = string.sub(Data,i, i)
		x = string.byte(c)
		-- ascii码表中字符0～9对应的值是48～57
		if x < 48  or x > 57 then
			return false
		end
	end
	return true
end

function _cacheSleep(time)
	Android:cacheSleep(time)
end

 
function setPerformance(isOpen)
	Android:setPerformance(isOpen)
end

function delPicForNotFindCrash()
	if fileIsExist(CasePath..Case_Name..'/OK.txt') then
		print('not found crash, delete pic !')
		delete(CasePath..getFileName(debug.getinfo(caseFactory).source)..'/')
	end
end

function max(tab) 
	local max = tab[1]
	for i,v in ipairs(tab) do
		if tab[i] > max then
			max = tab[i]
		end
	end
	return max
end

function min(tab) 
	local min = tab[1]
	for i,v in ipairs(tab) do
		if tab[i] < min then
			min = tab[i]
		end
	end
	return min
end

function average(tab) 
	local count = 0
	local sum = 0
	local avg = nil
	for i,v in ipairs(tab) do
		sum = sum + tab[i]
		count = count + 1
	end
	avg = sum/count
	return avg
end

function InitTestSuite()
	Case_Name = 'Init'
	Android:notifyMessage('--- Test Start ---')
	setLuaContext()
	basicDataUpdate() --delete and new
	-- gameLibCheck()
	devInfo() --show dev name、s2creen resolution、pkg name、ver info...
	-- openAccessibilty()
	-- permission() --check system permission popup
	if isClearAppData then clearAppData(PackageName) end
	-- if CURRENT_TOOLS == 'kat' then Android:back(0) else clicktime = 300 end
	_logcat('i', '---kat---', Case_Name..'|InitTestSuite true: \n')
end

function InitTestCase(CaseName)
	Case_Name = CaseName
end

function TearDownTestSuite()
	Case_Name = 'TearDown'
	stepId = 1
	actionCounter = 1 
	picCheckPointCounter = 1
	-- write checkpoints' statistic data into Result.txt file
	if _fileIsExist(TotalResultLogPath) then
		for line in io.lines(TotalResultLogPath) do
			CHECK_POINT_SUM = CHECK_POINT_SUM + 1
			if string.find(line, 'fail') then
				CHECK_POINT_FAIL = CHECK_POINT_FAIL + 1
			elseif string.find(line, 'pass') then
				CHECK_POINT_PASS = CHECK_POINT_PASS + 1
			end
		end
		local totalresult = io.open(TotalResultLogPath,'a')
		totalresult:write(tostring(CHECK_POINT_SUM)..CHECK_POINT_SEPARATOR..tostring(CHECK_POINT_FAIL)..CHECK_POINT_SEPARATOR..tostring(CHECK_POINT_PASS)..'\n')
		totalresult:close()
	end

	--Record teardown_over log, first check filePath is existed
	if not _fileIsExist(LogPath) then
		_logcat('i', '---kat---', "Maybe Init.lua isn't executed")
		Android:newFolder(ResultPath)
		Android:newFile(LogPath)
	end
	analysis()
	-- stop performance test:
	if Performance then stopPerformanceTest() end
	if (Performance and (PackageType == 'cocos2dx')) then cocos2dx_fps_stop() end
	endApp(PackageName)
	_shell('ime disable com.kunpeng.kapalai.kat/com.kunpeng.kat.core.ADBKeyBoard')
	if isGetStartTime then appTimeTest(PackageName) end
	_snapshotWholeScreen(ResultPath..'fw_check.jpg', 'fw_check')
	notifyMessage('--- Test End ---')
	_logcat('i', '---kat---', Case_Name..'|TearDownTestSuite true: \n')
end

function getFileName(content)
	local array = _split(content,'/')
	local casewithextension = array[#array]
	local casename = _split(casewithextension,'.lua')[1]
	return casename
end

function log(info)
	local file = io.open(LogPath, 'a')
	file:write(getSystemTime('MM-dd HH:mm:ss')..': ['..Case_Name..'] '..info)
	file:close()
end

function analysis()
	Android:newFile(ResultPath..'message.json')
	local file_json = io.open(ResultPath..'message.json','a')
	file_json:write('{')
	file_json:write('"screen_image":[')
	if _fileIsExist(CHECK_POINT_INFO_PATH) then
		local file_cp = io.open(CHECK_POINT_INFO_PATH,'r')
		local text = file_cp:read("*all")
		file_cp:close()
		local lines = _split(text, '\n')
		local length = #lines - 1
		for i=1, length do
			local info = lines[i]
			local info_table = _split(info, 'jpg@')
			file_json:write('{')
			file_json:write('"imageName":"'..info_table[1]..'jpg",'..'"imageMessage":"'..info_table[2]..'"}')
			if i < length then file_json:write(',') end
		end
	end
	file_json:write(']')
	file_json:write('}')
	file_json:close()
	-- Android:delete(CHECK_POINT_INFO_PATH)
end

function collectResult()
	local checkpoint_path = ResultPath..'checkpoint/'..Case_Name..'/'
	Android:newFolder(checkpoint_path)
	_sleep(1000)
	if #t_info==0 then --用户没有使用任何断言语句
		local uncheckpath = checkpoint_path..'uncheck.txt'
		Android:newFile(uncheckpath)
		local file_uncheck = io.open(TotalResultLogPath,'a')
		-- local message = ""
		-- local ResultText_uncheck = Case_Name..CHECK_POINT_SEPARATOR..'uncheck'..CHECK_POINT_SEPARATOR..message..'\n'
		file_uncheck:write('')
		file_uncheck:close()
		return
	end
	do
		local result = true
		for i, r in pairs(t_result) do
			result = r and result
		end
		if result then
			local passpath = checkpoint_path..'pass.txt'
			local passfile = io.open(passpath,'a')
			for i, v in pairs(t_info) do
				passfile:write(v..'\n')
				_sleep(500)
			end
			passfile:close()
			_sleep(1000)
			local file_pass = io.open(TotalResultLogPath, 'a')
			-- local ResultText_pass = Case_Name..'-pass\n'
			-- file_pass:write(ResultText_pass)
			for i, v in pairs(t_info) do
				file_pass:write(Case_Name..CHECK_POINT_SEPARATOR..v..'\n')
				_sleep(500)
			end
			file_pass:close()
		else
			local failpath = checkpoint_path..'fail.txt'
			local failfile = io.open(failpath,'a')
			for i, v in pairs(t_info) do
				failfile:write(v..'\n')
				_sleep(500)
			end
			failfile:close()
			_sleep(3000)
			local file_fail = io.open(TotalResultLogPath, 'a')
			-- local ResultText_fail = Case_Name..'-fail\n'
			-- file_fail:write(ResultText_fail)
			for i, v in pairs(t_info) do
				file_fail:write(Case_Name..CHECK_POINT_SEPARATOR..v..'\n')
				_sleep(500)
			end
			file_fail:close()
		end
	end
end

function doRun()
	stepId = 1
	continuePlaybackFailTimes = 1 
	palybackFailMaxTimes = 1
	local info = debug.getinfo(caseFactory).source
	local CaseName = getFileName(info)
	InitTestCase(CaseName)
	picCheckPointCounter = 1
	actionCounter = 1 
	--check fw_asf.txt is available or not:
	if not _fileIsExist(RootPath..'fw_asf.txt') then
		checkAppIsInstall()
		_notifyMessage('Case-'..Case_Name)
		local result = caseFactory()
		_shell('ime enable com.kunpeng.kapalai.kat/com.kunpeng.kat.core.ADBKeyBoard')
		_shell('ime set com.kunpeng.kapalai.kat/com.kunpeng.kat.core.ADBKeyBoard')
		if result then result = 'Success' else result = 'Failure' end
		_writeFile(TEST_RUNNING_RESULT_PATH, 'startApp:'..result..'\n')
		_check_point_pic('启动应用')
		checkAppIsVisiable()
		--collect performance data:
		if Performance then startPerformanceTest() end
		if (Performance and (PackageType == 'cocos2dx')) then cocos2dx_fps_start() end
		--execute Case with traceback
		xpcall(executeCase, lua_handler)
		if Performance then pausePerformanceTest() end
		--check crash:
		getHookVersion()
		if testEndIsCleanPic then
			delPicForNotFindCrash()
		end
		--this case is test over, delete OK.txt
		Android:delete(CasePath..Case_Name..'/OK.txt')
		if _fileIsExist(ACTION_INFO_PATH) then
			_check_point_pic('')
		end
		os.remove(ACTION_INFO_PATH)
		if KAT_LUAEND then
			error('KAT_LUAEND')
		elseif TRACEBACK ~= '' then
			_notifyMessage('Script error, please check!')
			error(TRACEBACK)
		end
		--send injection event manually
		collectResult()
		_notifyMessage('Case-'..Case_Name..' is finished...')
		_logcat('i', '---kat---', Case_Name..' is finished...')
		log('WIFI '..tostring(Android:isWifiConnect())..' | NET '..tostring(Android:isNetworkEnable('180.149.132.47'))..'\n')
	end
end

function _isCurrentPage(id, key, ctext, classpath, activity)
	local classpath = pathTranslate(classpath)
	local resolution_x, resolution_y = Android:getScreenResolution() 
	local result = false
	if activity == nil then activity = '' end
	local status, x, y, dx, dy = decodeResult(Android:findControl(id, key, ctext, classpath, activity))
	if status > 0 then
		local isGet, Temp_x, Temp_y, Temp_dx, Temp_dy = decodeResult(Android:getControlerRect(id, key, ctext, classpath, activity))
		local x = Temp_x + Temp_dx/2
		local y = Temp_y + Temp_dy/2
		if (0<x and x<resolution_x) and (0<y and y<resolution_y) then
			result = true
		end
	end
	return result
end

function _move(x1,y1,x2,y2,path) 
	if path == nil or path == 0 then
		Android:move(x1,y1,x2,y2)
	else
		Android:move(x1,y1,x2,y2,path)
	end
end

function _zipFolder(srcFilePath, zipFilePath)
	Android:zipFolder(srcFilePath, zipFilePath)
	_sleep(3000)
end

function getApiVersion()
	Android:getApiVersion()
end

function getDeviceVersion()
	Android:getDeviceVersion()
end

function actionInit(ctext)
	write_file_video(VIDEO_INFO_PATH, 'Step_'..stepId..':'..action..' false '..getSystemTimemap())
	if isPlayToast then
		if ctext ~= '' then
			_notifyMessage('Step '..stepId..' : '..action..' ['..ctext..']')
		else
			_notifyMessage('Step'..stepId..' : '..action)
		end
	end
end

function cpuNum()
	_shell('ls /sys/devices/system/cpu > /sdcard/cpuCore.txt')
	local cpuNum = ''
	if _fileIsExist('/sdcard/cpuCore.txt') then
		file = io.open('/sdcard/cpuCore.txt', 'r')
		for line in file:lines() do
			if string.find(line, 'cpu') then
				if isNum(_split(line, 'cpu')[2]) then
					cpuNum = _split(line, 'cpu')[2] + 1
				end
			end
		end
	else
		print('not found cpuCore.txt')
	end
	print(cpuNum)
	return cpuNum
end

function cpuModel()
	_shell('cat /proc/cpuinfo > /sdcard/cpuModel.txt')
	local cpuModel = ''
	if _fileIsExist('/sdcard/cpuModel.txt') then
		file = io.open('/sdcard/cpuModel.txt', 'r')
		for line in file:lines() do
			if string.find(line, 'Processor') then
				cpuModel = _split(line, ':')[2]
				break
			end
		end
	else
		print('not found cpuCore.txt')
	end
	print(cpuModel)
	return cpuModel
end

function cpuMaxFreq()
	_shell('cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq > /sdcard/cpuMaxFreq.txt')
	local cpuMaxFreq = ''
	if _fileIsExist('/sdcard/cpuMaxFreq.txt') then
		file = io.open('/sdcard/cpuMaxFreq.txt', 'r')
		for line in file:lines() do
			cpuMaxFreq = line
		end
	else
		print('not found cpuCore.txt')
	end
	print(cpuMaxFreq)
	return cpuMaxFreq
end

function kernelVersion()
	_shell('cat /proc/version > /sdcard/kernelVersion.txt')
	local kernelVersion = ''
	if _fileIsExist('/sdcard/kernelVersion.txt') then
		file = io.open('/sdcard/kernelVersion.txt', 'r')
		for line in file:lines() do
			kernelVersion = removeSpace(line)[3]
			break
		end
	else
		print('not found cpuCore.txt')
	end
	print(kernelVersion)
	return kernelVersion
end

function memInfo()
	_shell('cat /proc/meminfo > /sdcard/memInfo.txt')
	local memTotal = ''
	local memFree = ''
	if _fileIsExist('/sdcard/memInfo.txt') then
		file = io.open('/sdcard/memInfo.txt', 'r')
		for line in file:lines() do
			if string.find(line, 'MemTotal') then
				memTotal = removeSpace(line)[2]..'KB'
			elseif string.find(line, 'MemFree') then
				memFree = removeSpace(line)[2]..'KB'
				break
			end
		end
	else
		print('not found cpuCore.txt')
	end
	print(memTotal)
	print(memFree)
	return memInfo, memFree
end

function getSDCardMemory()
	return Android:getSDCardMemory()
end

function getHookVersion()
	Android:getHookVersion()
end

function stopPerformanceTest()
	Android:stopPerformanceTest()
end

function pausePerformanceTest()
	Android:pausePerformanceTest()
end

function startPerformanceTest()
	Android:startPerformanceTest(PackageName, 2000, Case_Name)
end

function _split(szFullString, szSeparator) --字符串分割函数,szFullString：被分割字符串,szSeparator：分隔符
	local nFindStartIndex = 1
	local nSplitIndex = 1
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1
	end
	return nSplitArray
end

function cocos2dx_fps_start()
	Android:cocos2dx_fps_start(2000, Case_Name, 1000*3600)
end

function cocos2dx_fps_stop()
	Android:cocos2dx_fps_stop()
end

function getCrashStatus()
   return Android:getCrashStatus()
end

--getFileInfo('sdcard/Tencent/wns/logs/test.log', 'onPageStarted: ', 0, nil, 'int')
function getFileInfo(filename, startstr, length, endstr, returntype)
	local isFound = false
	local info = 0
	if _fileIsExist(filename) then
		isFound, info = Android:getFileInfo(filename, startstr, length, endstr, returntype)
	end
	return isFound, info
end

function _logcat(level, tag, msg)
	Android:Log(level, tag, msg)
end

function createFolder(CaseN)
	local createFolder_path 
	if string.find(CaseN, '%d') then
		Android:newFolder(CasePath..CaseN..'/')
		_sleep(1000)
		createFolder_path = CasePath..CaseN..'/'
	else
		Android:newFolder(ResultPath..CaseN..'/')
		_sleep(1000)
		createFolder_path = ResultPath..CaseN..'/'
	end
	return createFolder_path
end

function _isForeground(pkgname)
	return Android:isforeground(pkgname)
end

function crashsnapshotScreen(path, tag)
	Android:crashsnapshotScreen(path, tag)
end

function lua_handler(msg)
	TRACEBACK = debug.traceback()
	TRACEBACK = tostring(msg) .. '\n'..TRACEBACK
end

function executeCase()
	executeCaseN(Case_Name)
end

function luaError()
	KAT_LUAEND = true
	error('KAT_LUAEND')
end

function luaStop(info)
	Android:endLua(info)
end

function _writeFileToFolder(FolderPath, FileName, content) 
	if not _fileIsExist(FolderPath) then
		Android:newFolder(FolderPath)
	end
	local FilePath = FolderPath..FileName
	local file = io.open(FilePath, 'a')
	file:write(content)
	file:close()
end

function _writeFile(path, content)
	local file = io.open(path, 'a')
	file:write(content)
	file:close()
end

function _log_(info)
	local file = io.open(LogPath, 'a')
	file:write(getSystemTime('MM-dd HH:mm:ss')..': ['..Case_Name..'] '..info..'\n')
	file:close()
end

function _shell(command)
	local respond = Android:runShCommand(command)
	return respond
end

function _fileIsExist(filePath)
	local file = io.open(filePath, 'rb')
	if file then 
		file:close()
		return true
	else
		return false
	end
end


function getSystemTime(format)
	return Android:getSystemTime(format)
end


function tooManyfail(text)
	_logcat('i', 'xtest', text)
	if isStepFail then 
		--当前步骤回放失败了
		if continuePlaybackFailTimes >= COUNTINUE_FAIL_NUM or palybackFailMaxTimes >= MAX_FAIL_NUM then
			--并且连续回放失败到最大次数或总失败次数达到最大次数,就停止运行当前case
			_notifyMessage(PLAY_BACK_FAIL_TIP, 1)
			Android:delete(CasePath..Case_Name..'/OK.txt')
			_writeFile(TEST_RUNNING_RESULT_PATH, 'controlerFail:Failure')
			assert(false, PLAY_BACK_FAIL_TIP)
			luaStop('KAT_LUAEND')
		else
			--虽然失败了,但还没有出现连续失败到最大次数,计数器+1
			continuePlaybackFailTimes = continuePlaybackFailTimes + 1
		end
		palybackFailMaxTimes = palybackFailMaxTimes + 1
	else
		--当前步骤回放正确了,就把连续回放失败计数器清零
		continuePlaybackFailTimes = 1
	end
	isStepFail = false
end

function getSimpleValidResultCount()
	local rstCount = Android:getSimpleValidResultCount()
	print('rstCount:'..rstCount)
	return rstCount
end

function getSimpleExectime()
	local testTime = Android:getSimpleExectime()
	print('testTime:'..testTime)
	return testTime
end

function getAutoTestVersion()
	local simpleVer = Android:getAutoTestVersion()
	print('simpleVer:'..simpleVer)
	return simpleVer
end

function setQQLogin(id, sn, login_key_text)
	Android:setQQLogin(id, sn, login_key_text)
end

function setWXLogin(id, sn, login_key_text)
	Android:setWXLogin(id, sn, login_key_text)
end

function setWBLogin(id, sn, login_key_text)
	Android:setWBLogin(id, sn, login_key_text)
end

function getSystemTimemap()
	return Android:getSystemTimemap()
end

function write_file_video(path, content)
	if _fileIsExist(path) then
		local file = io.open(path, 'a')
		file:write(content)
		file:close()
	end
end

function getString(fullString, demoString)
	print(fullString)
	local i, j = string.find(fullString, demoString)
	if i == nil then
		return nil
	end
	return string.sub(fullString, i, j)
end


function netRequest(host, port, request)
	return Android:netRequest(host, port, request)
end

function appTimeTest(pkgName)
	function writeInfo(t1, t2, t3)
		newFile('/sdcard/kat/Result/taskinfo')
		local file = io.open('/sdcard/kat/Result/taskinfo', 'a')
		file:write(t1..'\n')
		file:write(t2..'\n')
		file:write(t3..'\n')
		file:close()
	end
	function write(installStatus, uninstallStatus)
		local file = io.open(TEST_RUNNING_RESULT_PATH, 'a')
		file:write('install:'..installStatus..'\n')
		file:write('uninstall:'..uninstallStatus..'\n')
		file:close()
	end
	local installTime = '-'
	local startupAppTime = '-'
	local uninstallTime = '-'
	local appName = ''
	if Android:isInstall(pkgName) then
		-- local appPath = getApkPath(pkgName)
		-- local appPathTable = _split(appPath, '/')
		-- appName = appPathTable[#appPathTable]
		-- Android:copyFileToFolder(appPath, '/sdcard/kat/Result/')
		-- Android:uninstallApp(pkgName)
		-- _sleep(3000)
	else
		writeInfo(installTime, startupAppTime, uninstallTime)
		return installTime..':'..startupAppTime..':'..uninstallTime
	end
	-- local startIsOK = false
	-- local isInstallSuccess = false
	-- local isTimeout = true
	local installInfo = ''
	-- if _fileIsExist('/sdcard/kat/Result/'..appName) then
	-- 	local start_time = getSystemTimemap()/1000
	-- 	isInstallSuccess, installInfo = Android:installAPP('/sdcard/kat/Result/'..appName)
	-- 	for i=1, 30 do
	-- 		if Android:isInstall(pkgName) then
	-- 			isTimeout = false
	-- 			break
	-- 		else
	-- 			_sleep(1500)
	-- 		end
	-- 	end
	-- 	if installInfo == nil then 
	-- 		installInfo = 'Success' 
	-- 	elseif isTimeout then
	-- 		installInfo = 'INSTALL_FAILED_TIMEOUT' 
	-- 	end
	-- 	local end_time = getSystemTimemap()/1000
	-- 	installTime = string.format('%.3f', end_time - start_time)
	-- else
	-- 	print('/sdcard/kat/Result/'..appName..' is not found!!')
	-- end
	-- _sleep(2000)
	-- if not _fileIsExist('/sdcard/kat/Result/'..appName) then
	-- 	local appPath = getApkPath(pkgName)
	-- 	Android:copyFileToFolder(appPath, '/sdcard/kat/Result/')
	-- end
	if isClearAppData then clearAppData(pkgName) end
	_sleep(1500)
	startupAppTime = getString(_shell('am start -W '..getMainActivity(pkgName)), 'TotalTime: %d+')
	if startupAppTime == nil then
		startupAppTime = '-'
	else
		startupAppTime = string.format('%.3f', (removeSpace(startupAppTime)[2])/1000)
	end
	-- --这里需要先停止用在卸载,否则有可能会导致被测应用数据残留,影响后续安装
	-- endApp(pkgName)
	-- _sleep(2000)
	local uninstallInfo = ''
	-- local isUninstalled = false
	-- if Android:isInstall(pkgName) then
	-- 	local start_time = getSystemTimemap()/1000
	-- 	isUninstalled = Android:uninstallApp(pkgName)
	-- 	local end_time = getSystemTimemap()/1000
	-- 	uninstallTime = string.format('%.3f', end_time - start_time)
	-- 	Android:installAPP('/sdcard/kat/Result/'..appName)
	-- 	Android:delete('/sdcard/kat/Result/'..appName)
	-- end
	-- if isUninstalled then uninstallInfo = 'Success' end
	writeInfo(installTime, startupAppTime, uninstallTime)
	write(installInfo, uninstallInfo)
	endApp(pkgName)
	return installTime..':'..startupAppTime..':'..uninstallTime
end

 
function findTagFromFile(path, tag)
	local result = false
	local data = ''
	if _fileIsExist(path) then
		file = io.open(path,'r')
		for line in file:lines() do
			if string.find(line, tag) then
				result = true
				data = line
				break
			end
		end
		file:close()
	end
	return result, data
end

function checkAppIsInstall()
	if not Android:isInstall(PackageName) then
		_snapshotWholeScreen(ResultPath..'install_fail.png', 'fw_error_install_fail')
		_logcat('i', '---kat---', 'Package('..PackageName..") isn't installed")
		_notifyMessage('Package('..PackageName..") isn't installed")
		luaStop('KAT_LUAEND')
	end
end

function checkAppIsVisiable()
	if not _isForeground(PackageName) then
		local createFolder_path = createFolder(Case_Name)
		_snapshotWholeScreen(createFolder_path..'foreground_fail.jpg', 'fw_error_foreground_fail')
		_logcat('i', '---kat---', "pkg isn't visiable, foreground failed")
	end 
end

function openAccessibilty()
	if isAccessbility and Android:getAndroidSDK() < 21 then
		Android:startKatAccessbility()
		Android:notifyMessage('Test framework init')
		Android:startApp('com.kunpeng.accessmanager')
	end
end

function isOpenLog(isTrue)
	Android:openLog(isTrue)
end

function setLuaContext()
	hashmap:put('PackageName', PackageName)
	hashmap:put('callback', 'handler')
	hashmap:put('haswatertext', ISPOINT)
	hashmap:put('autoCPFrequency', tostring(AUTO_CP_FREQUENCY))
	hashmap:put('needresign', Needresign)
	hashmap:put('checkPoint', 'checkPoint')
	Android:setLuaContext(hashmap)
end

function _snapshotWholeScreen(path, tag)
	if tag == nil then
		Android:snapshotScreen(path)
	else
		Android:snapshotScreen(path, tag)
	end
end

function decodeResult(str)
	if str == nil then
		return 0,0,0,0,0
	end
	local items = _split(str, ':')
	local st = tonumber(items[1])
	local x = tonumber(items[2])
	local y = tonumber(items[3])
	local dx = tonumber(items[4])
	local dy = tonumber(items[5])	
	return st, x, y, dx, dy
end

function _snapshotScreen(x, y, dx, dy, path)
	Android:snapshotScreen(x, y, dx, dy, path)
end

function pathTranslate(classpath) --新版本path check方案,若原始path是空,则转化为@
	local path = classpath
	if classpath == '' then
		path = '@'
	end
	return path
end


function closeIme()
	local imeList = _shell('ime list -s')
	for i,v in ipairs(_split(imeList, '%c')) do
		if string.find(v, '/') then
			Android:endApp(_split(v, '/')[1])
			sleep(500)
		end
	end
end

function _notifyMessage(data, time)
	local data = tostring(data)
	if time == nil or time == 0 then
		Android:notifyMessage(data)
		_sleep(2000)
	else
		Android:notifyMessage(data, 1)
		_sleep(3500)
	end
end

function _sleep(n)
	local sleepTime = n/1000
	local intTime = tonumber(string.format('%d', sleepTime))
	local floatTime = tonumber(string.sub(string.format('%.3f', sleepTime), -3))
	for i=1, intTime do
		Android:mSleep(1000)
	end
	Android:mSleep(floatTime)
end

function devInfo()
	local x, y = Android:getScreenResolution()
	local ApiVersion = Android:getVersionNumber('com.kunpeng.kapalai.kat')
	local devVersion = Android:getDeviceVersion()
	local cpuInfo = Android:getCpuInfo()
	local memInfo = Android:getTotalMemory()
	local ApiVersion_testkat = 'nil'
	local devIMEI = 'nil'
	if Android:getIMEI() ~= nil then devIMEI = Android:getIMEI() end
	if not Android:isInstall('com.kunpeng.kat.test') then
		ApiVersion_testkat = 'com.kunpeng.kat.test not found !!'
	else
		ApiVersion_testkat = Android:getVersionNumber('com.kunpeng.kat.test')
	end
	log(Device..' | '..x..'x'..y..' | Android '..Android:getAndroidVersion()..' | API_LEVEL '..Android:getAndroidSDK()..' | IMEI '..devIMEI..'\n')
	log('Kat '..ApiVersion..'\n')
	log('KatTest '..ApiVersion_testkat..'\n')
	local file = io.open('/sdcard/kat/Result/deviceinfo', 'a')
	file:write(_split(devVersion, ':')[6]..'\n')   --手机厂商
	file:write(Device..'\n')					   --手机型号
	file:write('Android OS '..Android:getAndroidVersion()..'\n')  --Android版本
	file:write(_split(devVersion, ':')[4]..'\n')   --内核版本
	file:write(x..'x'..y..'\n')   --手机分辨率
	file:write(_split(cpuInfo, ':')[1]..'\n')      --Cpu型号
	file:write(_split(cpuInfo, ':')[2]..'\n')
	file:write(_split(cpuInfo, ':')[3]..'\n')	   --Cpu内核数
	file:write(_split(cpuInfo, ':')[4]..'\n')	   --Cpu最高主频
	file:write(_split(memInfo, ':')[1]..'\n')	   --内存
	file:write(_split(memInfo, ':')[2])	   --空闲内存
	file:close()
end

function basicDataUpdate()
	Android:delete('/sdcard/kat/katlog.txt')
	Android:delete('/sdcard/kat/Result')
	Android:delete('/sdcard/kat/fw_asf.txt')
	Android:delete('/sdcard/kat/Result.zip')
	Android:newFolder(CasePath)
	Android:newFile(LogPath)
	Android:newFile('/sdcard/kat/Result/deviceinfo')
	Android:newFile(CRASH_DATA_PATH)
	Android:newFile(TEST_RUNNING_RESULT_PATH)
end

function gameLibCheck()
	if PackageType == 'cocos2dx' then
		Android:delete('/data/local/tmp/kat/libkatcocos.so')
		_sleep(1000)
		if _fileIsExist('/sdcard/kat/libkatcocos.so') then
			Android:copyFileToFolder('/sdcard/kat/libkatcocos.so', '/data/local/tmp/kat/')
			_sleep(1000)
			Android:runShCommand('chmod 777 /data/local/tmp/kat/libkatcocos.so')
			_sleep(1000)
		else
			_logcat('i', '---kat---', "fw_error Don't find libkatcocos.so in sdcard/kat/")
			assert_final(false, "fw_error Don't find libkatcocos.so in sdcard/kat/")
		end  
	end
end

function permission()
	if Device == 'R8207' then
		--拉取安全中心权限管理页面
		Android:endApp('com.oppo.safe')
		_sleep(2000)
		Android:runShCommand('am start -n com.oppo.safe/com.oppo.safe.permission.PermissionTopActivity')
		_sleep(2000)
		--判断权限开关是否已经开启,若已经开启就关掉它
		if Android:getClassFieldValue(-1, 'checkbox', '', '%android.widget.LinearLayout#1%com.oppo.widget.OppoListView#1%android.widget.LinearLayout#2%android.widget.LinearLayout#0', 'mChecked', 1, 'boolean') then
			Android:click(-1, 'widget_frame', '', '%android.widget.LinearLayout#1%com.oppo.widget.OppoListView#1%android.widget.LinearLayout#2', 0)
		end
		Android:endApp('com.oppo.safe')
		_sleep(2000)
	elseif Device == 'R7005' then
		--拉取安全中心权限管理页面 
		Android:endApp('android.process.safer')
		_sleep(2000)
		Android:runShCommand('am start -n com.oppo.safe/com.oppo.safe.permission.PermissionTopActivity')
		_sleep(2000)
		--判断权限开关是否已经开启,若已经开启就关掉它
		if Android:getClassFieldValue(-1, 'check_box', '', '%android.widget.LinearLayout#0%android.widget.RelativeLayout#1', 'mChecked', 1, 'boolean') then
			Android:click(-1, 'check_box', '', '%android.widget.LinearLayout#0%android.widget.RelativeLayout#1', 0)
		end
		Android:endApp('android.process.safer')
		_sleep(2000)
	elseif Device == 'R8007' or Device == 'R831T' then
		--拉取安全中心权限管理页面
		Android:endApp('android.process.safer')
		_sleep(2000)
		Android:runShCommand('am start -n com.oppo.safe/com.oppo.safe.permission.PermissionTopActivity')
		_sleep(2000)
		--判断权限开关是否已经开启,若已经开启就关掉它
		if Android:getClassFieldValue(-1, 'check_box', '', '%android.widget.LinearLayout#0%com.oppo.safe.widget.MainStateView#1%android.widget.LinearLayout#1', 'mChecked', 1, 'boolean') then
			Android:click(-1, 'check_box', '', '%android.widget.LinearLayout#0%com.oppo.safe.widget.MainStateView#1%android.widget.LinearLayout#1', 0)
		end
		Android:endApp('android.process.safer')
		_sleep(2000)
	elseif Device == 'GN9001' or Device == 'GN709L' then
		--拉取安全中心权限管理页面
		Android:endApp('com.gionee.softmanager')
		_sleep(2000)
		Android:runShCommand('am start -n com.gionee.softmanager/com.gionee.softmanager.PermissionMrgActivity')
		_sleep(2000)
		Android:click(-1, '', '应用', '@', 0)
		_sleep(2000)
		local app_name = Android:getAppName(PackageName)
		Android:click(-1, '', app_name, '@', 0)
		_sleep(2000)
		--判断权限开关是否已经开启,若已经开启就关掉它
		if Android:getClassFieldValue(-1, 'permission_trust_switch', '', '%android.widget.FrameLayout#0%android.widget.LinearLayout#1%android.widget.FrameLayout#0%android.widget.RelativeLayout#0%android.widget.LinearLayout#0%android.widget.RelativeLayout#1%android.widget.FrameLayout#0', 'mChecked', 1, 'boolean') ~= true then
			Android:click(-1, 'permission_trust_switch', '', '%android.widget.FrameLayout#0%android.widget.LinearLayout#1%android.widget.FrameLayout#0%android.widget.RelativeLayout#0%android.widget.LinearLayout#0%android.widget.RelativeLayout#1%android.widget.FrameLayout#0', 0)
			_sleep(2000)
		end
		Android:endApp('com.gionee.softmanager')
		_sleep(2000)
	elseif Device == 'vivo X3V' or Device == 'vivo X3L' or Device == 'vivo Y22iL' or Device == 'vivo X5L' or Device == 'vivo Xshot' or Device == 'vivo X3S W' or Device == 'vivo Y29L' or Device == 'vivo Y28L' or Device == 'vivo Y22L' or Device == 'vivo X710F' or Device == 'vivo Y13L' or Device == 'vivo Y23L' or Device == 'vivo X5S L' then
		Android:endApp('com.iqoo.secure')
		_sleep(2000)
		Android:runShCommand('am start -n com.iqoo.secure/com.iqoo.secure.safeguard.PurviewTabActivity')
		_sleep(2000)
		Android:click(-1, '', '软件', '@', 0)
		_sleep(2000)
		local app_name = Android:getAppName(PackageName)
		Android:click(-1, '', app_name, '@', 0)
		_sleep(2000)
		--判断权限开关是否已经开启,若已经开启就关掉它
		if Android:getClassFieldValue(-1, 'lbsbutton', '', '%android.widget.RelativeLayout#2%android.widget.LinearLayout#0%android.widget.ListView#0%android.widget.RelativeLayout#0%android.widget.LinearLayout#1', 'mChecked', 0, 'boolean') ~= true then
			Android:click(-1, 'lbsbutton', '', '@', 0)
			_sleep(2000)
		end
		Android:endApp('com.iqoo.secure')
		_sleep(2000)
	elseif Device == 'Coolpad S6-NC1' or Device == 'Coolpad8295C' or Device == 'Coolpad 8690_T00' or Device == 'Coolpad Y80D' or Device == 'Coolpad 5951' or Device == 'Coolpad 8730L' then
		Android:endApp('com.yulong.android.security')
		_sleep(1500)
		Android:runShCommand('am start -n com.yulong.android.security/com.yulong.android.security.ui.activity.dataprotection.AppListActivity')
		_sleep(2000)
		local app_name = Android:getAppName(PackageName)
		Android:click(-1, '', app_name, '@', 0)
		_sleep(2000)
		Android:click(-1, '', '批量操作', '@', 0)
		_sleep(2000)
		Android:click(-1, '', '全部允许', '@', 0)
		_sleep(2000)
		Android:endApp('com.yulong.android.security')
		_sleep(1500)
	end
 end
