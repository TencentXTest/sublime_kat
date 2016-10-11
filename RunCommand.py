#coding:utf-8
import sublime, sublime_plugin, os, subprocess, sys, time, threading, re, urllib
adbpath = "adb"
delimiter = '\\'
tmpFolder = 'KatTmpFolder'

class RunCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
		print "================================run kat !! (run main.lua)================================"
		# get target folder path
		filePath = self.view.file_name().split(delimiter)
		folderPath = ""
		for i in range(0, len(filePath) - 1):
			folderPath = folderPath + filePath[i] + delimiter
		# traversal of the suffix ".Lua" file name
		fileList = []
		for i in os.listdir(folderPath):
			resultFilePath = folderPath + i
			if i.endswith('.lua') or i.endswith('.so') or i.endswith('.txt') or i.endswith('.xls') or i.endswith('.jar') or i.endswith('.jpg') or i.endswith('.png') or i.endswith('.apk'):
				fileList.append(resultFilePath)
		# run adb Command
		try:
			self.pushFileToDevice(fileList)
		except Exception, e:
			print e
			sublime.error_message(e)
		t = threading.Thread(target=self.showlog)
		t.setDaemon(True)
		t.start()
		# t.join()
		
	def pushFileToDevice(self, pathlist):
		# check adb is connection, if 'device not found', pop up error!
		self.view.run_command('stop_stop')
		for i in range(0, len(pathlist)):
			result = subprocess.Popen(adbpath + " push " + pathlist[i] + " /sdcard/kat/", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			# print result.communicate()
		isKatInstall = subprocess.Popen(adbpath + " shell am start -n com.kunpeng.kapalai.kat/com.kunpeng.kapalai.kat.core.TesttoolActivity --es luapath  /sdcard/kat/Main.lua", shell = True, stdout = subprocess.PIPE)
		infooutput_kat, erroutput_kat = isKatInstall.communicate()
		# print infooutput_kat
		if infooutput_kat.find("does not exist") != -1:
			sublime.error_message("kat not found OR kat version is older!!")
		else:
			pass

	def showlog(self):
		time.sleep(8)
		lastTimeLogRow = 0 
		error_lastTimeLogRow = 0
		begin_time = time.time()
		end_time = begin_time + 3600
		while time.time() < end_time:
			temp_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/Log.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			data_Log = temp_Log.communicate()
			temp_switch = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/show_log_stop.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			is_close_switch = temp_switch.communicate()
			error_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/error.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			error_data = error_Log.communicate()

			if is_close_switch[0].find('No such file') == -1:
				# print "---------Log thread is over---------"
				break
			if not data_Log[1]:
				count =  data_Log[0].count('\r\r\n')
				# print data_Log
				if lastTimeLogRow != count :
					if lastTimeLogRow > count :
						break
					else:
						for i in range(lastTimeLogRow, count):
							if data_Log[0].find('No such file') == -1:
								print '',data_Log[0].split('\r\r\n')[i]
						lastTimeLogRow = count
				time.sleep(0.3)
			else:
				print "--------------------------------------"
				print data_Log[1]
				break
			# error.txt解析
			error_count = error_data[0].count('\r\r\n')
			if error_lastTimeLogRow != error_count:
				if error_lastTimeLogRow > error_count:
					break
				else:
					for i in range(error_lastTimeLogRow, error_count):
						if error_data[0].find('No such file') == -1:
							print '---Error---',error_data[0].split('\r\r\n')[i]
					error_lastTimeLogRow = error_count

class RunLabKatCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
		print "================================run kat !! (run main.lua)================================"
		# get target folder path
		filePath = self.view.file_name().split(delimiter)
		folderPath = ""
		for i in range(0, len(filePath) - 1):
			folderPath = folderPath + filePath[i] + delimiter
		# traversal of the suffix ".Lua" file name
		fileList = []
		for i in os.listdir(folderPath):
			resultFilePath = folderPath + i
			if i.endswith('.lua') or i.endswith('.so') or i.endswith('.txt') or i.endswith('.xls') or i.endswith('.jar') or i.endswith('.jpg') or i.endswith('.png') or i.endswith('.apk'):
				fileList.append(resultFilePath)
		# run adb Command
		try:
			tt = threading.Thread(target=self.pushFileToDevice, args=(fileList,))
			tt.setDaemon(True)
			tt.start()
		except Exception, e:
			print e
			sublime.error_message(e)
		t = threading.Thread(target=self.showlog)
		t.setDaemon(True)
		t.start()
		# t.join()
		
	def pushFileToDevice(self, pathlist):
		# check adb is connection, if 'device not found', pop up error!
		# self.view.run_command('stop_stop')
		for i in range(0, len(pathlist)):
			# print adbpath + " push " + pathlist[i] + " /sdcard/kat/"
			result = subprocess.Popen(adbpath + " push " + pathlist[i] + " /sdcard/kat/", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		print "<<< " + adbpath + " shell am instrument -w com.kunpeng.kapalai.kat/com.kunpeng.kat.base.KatInstrumentationTestRunner >>>"
		isKatInstall = subprocess.Popen(adbpath + " shell am instrument -w com.kunpeng.kapalai.kat/com.kunpeng.kat.base.KatInstrumentationTestRunner", shell = True, stdout = subprocess.PIPE)
		infooutput_kat, erroutput_kat = isKatInstall.communicate()
		# print infooutput_kat
		if infooutput_kat.find("does not exist") != -1:
			sublime.error_message("kat not found OR kat version is older!!")
		else:
			pass

	def showlog(self):
		time.sleep(8)
		lastTimeLogRow = 0 
		error_lastTimeLogRow = 0
		begin_time = time.time()
		end_time = begin_time + 3600
		while time.time() < end_time:
			temp_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/Log.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			data_Log = temp_Log.communicate()
			temp_switch = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/show_log_stop.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			is_close_switch = temp_switch.communicate()
			error_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/error.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			error_data = error_Log.communicate()

			if is_close_switch[0].find('No such file') == -1:
				# print "---------Log thread is over---------"
				break
			if not data_Log[1]:
				count =  data_Log[0].count('\r\r\n')
				# print data_Log
				if lastTimeLogRow != count :
					if lastTimeLogRow > count :
						break
					else:
						for i in range(lastTimeLogRow, count):
							if data_Log[0].find('No such file') == -1:
								print '',data_Log[0].split('\r\r\n')[i]
						lastTimeLogRow = count
				time.sleep(0.3)
			else:
				print "--------------------------------------"
				print data_Log[1]
				break
			# error.txt解析
			error_count = error_data[0].count('\r\r\n')
			if error_lastTimeLogRow != error_count:
				if error_lastTimeLogRow > error_count:
					break
				else:
					for i in range(error_lastTimeLogRow, error_count):
						if error_data[0].find('No such file') == -1:
							print '---Error---',error_data[0].split('\r\r\n')[i]
					error_lastTimeLogRow = error_count

class RunXtestCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
		print "================================run xtest !! (run main.lua)================================"
		# get target folder path
		filePath = self.view.file_name().split(delimiter)
		folderPath = ""
		for i in range(0, len(filePath) - 1):
			folderPath = folderPath + filePath[i] + delimiter
		# traversal of the suffix ".Lua" file name
		fileList = []
		for i in os.listdir(folderPath):
			resultFilePath = folderPath + i
			if i.endswith('.lua') or i.endswith('.so') or i.endswith('.txt') or i.endswith('.xls') or i.endswith('.jar') or i.endswith('.jpg') or i.endswith('.png') or i.endswith('.apk'):
				fileList.append(resultFilePath)
		# run adb Command
		try:
			tt = threading.Thread(target=self.pushFileToDevice, args=(fileList,))
			tt.setDaemon(True)
			tt.start()
		except Exception, e:
			print e
			sublime.error_message(e)
		t = threading.Thread(target=self.showlog)
		t.setDaemon(True)
		t.start()
		# t.join()
		
	def pushFileToDevice(self, pathlist):
		# check adb is connection, if 'device not found', pop up error!
		# self.view.run_command('stop_stop')
		for i in range(0, len(pathlist)):
			# print adbpath + " push " + pathlist[i] + " /sdcard/kat/"
			result = subprocess.Popen(adbpath + " push " + pathlist[i] + " /sdcard/kat/", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		print "<<< " + adbpath + " shell am instrument -e class com.kunpeng.kat.base.TestMainInstrumentation -w com.tencent.utest.recorder/com.kunpeng.kat.base.KatInstrumentationTestRunner >>>"
		isKatInstall = subprocess.Popen(adbpath + " shell am instrument -e class com.kunpeng.kat.base.TestMainInstrumentation -w com.tencent.utest.recorder/com.kunpeng.kat.base.KatInstrumentationTestRunner", shell = True, stdout = subprocess.PIPE)
		infooutput_kat, erroutput_kat = isKatInstall.communicate()
		# print infooutput_kat
		if infooutput_kat.find("does not exist") != -1:
			sublime.error_message("kat not found OR kat version is older!!")
		else:
			pass

	def showlog(self):
		time.sleep(8)
		lastTimeLogRow = 0 
		error_lastTimeLogRow = 0
		begin_time = time.time()
		end_time = begin_time + 3600
		while time.time() < end_time:
			temp_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/Log.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			data_Log = temp_Log.communicate()
			temp_switch = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/show_log_stop.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			is_close_switch = temp_switch.communicate()
			error_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/kat/Result/error.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			error_data = error_Log.communicate()

			if is_close_switch[0].find('No such file') == -1:
				# print "---------Log thread is over---------"
				break
			if not data_Log[1]:
				count =  data_Log[0].count('\r\r\n')
				# print data_Log
				if lastTimeLogRow != count :
					if lastTimeLogRow > count :
						break
					else:
						for i in range(lastTimeLogRow, count):
							if data_Log[0].find('No such file') == -1:
								print '',data_Log[0].split('\r\r\n')[i]
						lastTimeLogRow = count
				time.sleep(0.3)
			else:
				print "--------------------------------------"
				print data_Log[1]
				break
			# error.txt解析
			error_count = error_data[0].count('\r\r\n')
			if error_lastTimeLogRow != error_count:
				if error_lastTimeLogRow > error_count:
					break
				else:
					for i in range(error_lastTimeLogRow, error_count):
						if error_data[0].find('No such file') == -1:
							print '---Error---',error_data[0].split('\r\r\n')[i]
					error_lastTimeLogRow = error_count

class StopCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		print "================================kill kat!!================================"
		# run adb Command
		os.popen(adbpath + " shell service call activity 79 s16 com.kunpeng.kapalai.kat")
		os.popen(adbpath + " shell service call activity 79 s16 com.tencent.utest.recorder")
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			f = open(folderPath + delimiter + 'show_log_stop.txt', 'w')
			f.close()
		else:
			os.mkdir(folderPath)
			f = open(folderPath + delimiter + 'show_log_stop.txt', 'w')
			f.close()
		self.pushFileToDevice(folderPath + delimiter + 'show_log_stop.txt')

	def pushFileToDevice(self, path):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " push d:/a1l1.txt /sdcard/kat/", shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		if erroutput[1].split(':')[0] == 'error':
			sublime.error_message(erroutput[1])
		else:
			result = os.popen(adbpath + " push " + path + " /sdcard/kat/Result/")

class StopStopCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		# run adb Command
		os.popen(adbpath + " shell service call activity 79 s16 com.kunpeng.kapalai.kat")
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			f = open(folderPath + delimiter + 'show_log_stop.txt', 'w')
			f.close()
		else:
			os.mkdir(folderPath)
			f = open(folderPath + delimiter + 'show_log_stop.txt', 'w')
			f.close()
		self.pushFileToDevice(folderPath + delimiter + 'show_log_stop.txt')

	def pushFileToDevice(self, path):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " push d:/a1l1.txt /sdcard/kat/", shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		if erroutput[1].split(':')[0] == 'error':
			sublime.error_message(erroutput[1])
		else:
			result = os.popen(adbpath + " push " + path + " /sdcard/kat/Result/")

class ErrorCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print "==========get error.txt!!=========="
		# get target folder path 
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath)

	def pullFile(self, srcFolder):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " pull /sdcard/kat/Result/error.txt " + srcFolder, shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		# print erroutput
		if erroutput[1].find("device") != -1:
			sublime.error_message(erroutput[1])
		elif erroutput[1].find("does not exist") != -1:
			sublime.error_message("error.txt is not found !!")
		else:
			pass

class LogCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print "=============get log.txt!!============="
		# get target folder path 
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath)

	def pullFile(self, srcFolder):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " pull /sdcard/kat/Result/Log.txt " + srcFolder, shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		# print erroutput
		if erroutput[1].find("device") != -1:
			sublime.error_message(erroutput[1])
		elif erroutput[1].find("does not exist") != -1:
			sublime.error_message("Log.txt is not found !!")
		else:
			pass

class ResultCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		print "=================get Result.txt!!==================="
		# get target folder path 
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath)

	def pullFile(self, srcFolder):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " pull /sdcard/kat/Result/Result.txt " + srcFolder, shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		# print erroutput
		if erroutput[1].find("device") != -1:
			sublime.error_message(erroutput[1])
		elif erroutput[1].find("does not exist") != -1:
			sublime.error_message("Result.txt is not found !!")
		else:
			pass

# class CrashCommand(sublime_plugin.TextCommand):
# 	# main
# 	def run(self, edit):
# 		print "===================get crashlog.txt!!===================="
# 		# get target folder path 
# 		filePathMember = self.view.file_name().split(delimiter)
# 		folderTools = FolderTools()
# 		folderPath = folderTools.getFolderList(filePathMember)
# 		if os.path.exists(folderPath):
# 			self.pullFile(folderPath)
# 		else:
# 			os.mkdir(folderPath)
# 			self.pullFile(folderPath)

# 	def pullFile(self, srcFolder):
# 		# check adb is connection, if 'device not found', pop up error!
# 		p = subprocess.Popen(adbpath + " pull /sdcard/kat/Result/crashlog.txt " + srcFolder, shell = True, stderr = subprocess.PIPE)
# 		erroutput = p.communicate()
# 		# print erroutput
# 		if erroutput[1].find("device") != -1:
# 			sublime.error_message(erroutput[1])
# 		elif erroutput[1].find("does not exist") != -1:
# 			sublime.error_message("crashlog.txt is not found !!")
# 		else:
# 			pass

class GetTestToolScriptCommand(sublime_plugin.WindowCommand):
	# main
	def run(self):
		print "=================input script name!!=================="
		self.window.show_input_panel("scriptName:", "", self.on_done, None, None)

	def on_done(self, text):
		try:
			if self.window.active_view():
				self.window.active_view().run_command("pull_test_tool_script", {"text": text} )
		except ValueError:
			pass


class PullTestToolScriptCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit, text):
		print "==============pull script.lua!!==============="
		# get target folder path 
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath, text)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath, text)

	def pullFile(self, srcFolder, text):
		# check adb is connection, if 'device not found', pop up error!
		try:
			p = subprocess.Popen(adbpath + " pull /sdcard/TestTool/" + text + ".lua " + srcFolder, shell = True, stderr = subprocess.PIPE)
			erroutput = p.communicate()
			if erroutput[1].find("device") != -1:
				sublime.error_message(erroutput[1])
			elif erroutput[1].find("does not exist") != -1:
				sublime.error_message(text + ".lua is not found !!")
			else:
				pass
		except Exception, e:
			sublime.error_message(u"要拉取的文件路径为: /sdcard/TestTool/" + text + u".lua\n不能包含中文!!") 

class CatKatInfoCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		print "=============cat kat info!!=============="
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath)
		
	def pullFile(self, srcFolder):		
		p = subprocess.Popen(adbpath + " shell ls /data/local/tmp/kat -l", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		infooutput, erroutput = p.communicate()
		if erroutput.find("device") != -1:
			sublime.error_message(erroutput)
		elif infooutput.find("No such file") != -1:
			sublime.error_message(infooutput)
		else:
			infooutput = infooutput.split('\r\r\n')
			fl = file(srcFolder + delimiter +'CatKatInfo.txt', 'w')
			for i in xrange(0, len(infooutput)):
				fl.write(infooutput[i])
				fl.write("\n")
			fl.close()
	    
class GetKatDataCommand(sublime_plugin.WindowCommand):
	# main
	def run(self):
		print "===============input script name!!================"
		self.window.show_input_panel("fileName:", "", self.on_done, None, None)

	def on_done(self, text):
		try:
			if self.window.active_view():
				self.window.active_view().run_command("pull_kat_data", {"text": text} )
		except ValueError:
			pass


class PullKatDataCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit, text):
		print "===============pull /data/local/tmp/kat file!!================="
		# get target folder path 
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath, text)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath, text)
		
	def pullFile(self, srcFolder, text):
		# check adb is connection, if 'device not found', pop up error!
		print "======================pull /data/local/tmp/kat/" + text + " " + srcFolder +"========================"
		try:
			p = subprocess.Popen(adbpath + " pull /data/local/tmp/kat/" + text + " " + srcFolder, shell = True, stderr = subprocess.PIPE)
			erroutput = p.communicate()
			# print erroutput
			if erroutput[1].find("device") != -1:
				sublime.error_message(erroutput[1])
			elif erroutput[1].find("does not exist") != -1:
				sublime.error_message(text + " is not found !!")
			else:
				pass
		except Exception:
			sublime.error_message(u"要拉取的文件路径为: /data/local/tmp/kat/" + text + u"\n不能包含中文!!") 
		
class GetLsCommand(sublime_plugin.WindowCommand):
	# main
	def run(self):
		print "================input script name!!================="
		self.window.show_input_panel("LsPath:", "", self.on_done, None, None)

	def on_done(self, text):
		try:
			if self.window.active_view():
				self.window.active_view().run_command("cat_ls", {"text": text} )
		except ValueError:
			pass

class CatLsCommand(sublime_plugin.TextCommand):

	def run(self, edit, text):
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath, text)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath, text)
		
	def pullFile(self, srcFolder, text):
		# check adb is connection, if 'device not found', pop up error!
		try:
			print adbpath + " shell su -c 'ls " + text + " -l'"
			p = subprocess.Popen(adbpath + " shell su -c 'ls " + text + " -l'", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			infooutput, erroutput = p.communicate()
			print infooutput
			if erroutput.find("device") != -1:
				sublime.error_message(erroutput)
			elif infooutput.find("No such file") != -1:
				sublime.error_message(infooutput)
			else:
				infooutput = infooutput.split('\r\r\n')
				fl = file(srcFolder + delimiter +'CatlsInfo.txt', 'w')
				for i in xrange(0, len(infooutput)):
					fl.write(infooutput[i])
					fl.write("\n")
				fl.close()
		except Exception:
			sublime.error_message(u"当前命令为:\n" + adbpath + " shell su -c 'ls " + text + " -l'" + u"\n不能包含中文!!")

class RunRecordKatCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		print '\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n'
		print "================================record kat !! (run main.lua)================================"
		# run adb Command
		try:
			tt = threading.Thread(target=self.recordkat)
			tt.setDaemon(True)
			tt.start()
		except Exception, e:
			print e
			sublime.error_message(e)
		# t.join()

	def recordkat(self):
		# check adb is connection, if 'device not found', pop up error!
		# self.view.run_command('stop_stop')
		print "================================record kat enter !! (run main.lua)================================"
		# run adb Command
		isKatInstall = subprocess.Popen(adbpath + " shell am instrument -w -e annotation com.kunpeng.kat.annotations.Record com.kunpeng.kapalai.kat/com.kunpeng.kat.base.KatInstrumentationTestRunner", shell = True, stdout = subprocess.PIPE)
		infooutput_kat, erroutput_kat = isKatInstall.communicate()
		# print infooutput_kat
		if infooutput_kat.find("does not exist") != -1:
			sublime.error_message("kat not found OR kat version is older!!")
		else:
			pass
		print "================================run success Command ================================"


class RunCurrentScriptCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		print "=================run current scrpit !!================="
		try:
			# get target folder path
			filePath = self.view.file_name()
			# run adb Command
			self.pushFileToDevice(filePath)
		except Exception:  
			sublime.error_message(u"当前脚本路径为:\n" + filePath + u"\n路径名不能包含中文!!")

	def pushFileToDevice(self, pathlist):
		# check adb is connection, if 'device not found', pop up error!
		tempList = pathlist.split(delimiter)
		Num_tempList = len(tempList)
		ScrpitName = tempList[Num_tempList - 1]
		print "currert script is=====>", ScrpitName
		p = subprocess.Popen(adbpath + " push d:/a1l1.txt /sdcard/kat/", shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		if erroutput[1].split(':')[0] == 'error':
			sublime.error_message(erroutput[1])
		else:
			print adbpath + " push " + pathlist + " /sdcard/kat/"
			os.popen(adbpath + " push " + pathlist + " /sdcard/kat/")
			isKatInstall = subprocess.Popen(adbpath + " shell am start -n com.kunpeng.kapalai.kat/com.kunpeng.kapalai.kat.core.TesttoolActivity --es luapath  /sdcard/kat/" + ScrpitName, shell = True, stdout = subprocess.PIPE)
			infooutput_kat, erroutput_kat = isKatInstall.communicate()

			if infooutput_kat.find("does not exist") != -1:
				sublime.error_message("kat not found OR kat version is older!!")
			else:
				pass

class PsCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		print "=============ps=============="
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			self.pullFile(folderPath)
		else:
			os.mkdir(folderPath)
			self.pullFile(folderPath)
		
	def pullFile(self, srcFolder):		
		p = subprocess.Popen(adbpath + " shell su -c 'ps'", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		infooutput, erroutput = p.communicate()
		if erroutput.find("device") != -1:
			sublime.error_message(erroutput)
		elif infooutput.find("No such file") != -1:
			sublime.error_message(infooutput)
		else:
			infooutput = infooutput.split('\r\r\n')
			fl = file(srcFolder + delimiter +'PS.txt', 'w')
			for i in xrange(0, len(infooutput)):
				fl.write(infooutput[i])
				fl.write("\n")
			fl.close()

class InputAppPkgNameCommand(sublime_plugin.WindowCommand):
	# main
	def run(self):
		print "================input need stop app pkg name!!================="
		self.window.show_input_panel("pkg name:", "", self.on_done, None, None)

	def on_done(self, text):
		try:
			if self.window.active_view():
				self.window.active_view().run_command("stop_app", {"text": text} )
		except ValueError:
			pass

class StopAppCommand(sublime_plugin.TextCommand):

	def run(self, edit, text):
		print "==========kill app!!=========="
		# run adb Command
		print adbpath + " shell su -c 'service call activity 79 s16 " + text + "'"
		os.popen(adbpath + " shell su -c 'service call activity 79 s16 " + text + "'")


# class InputLogCatCommand(sublime_plugin.WindowCommand):
# 	# main
# 	def run(self):
# 		self.window.show_input_panel("TAG", "", self.on_done, None, None)

# 	def on_done(self, text):
# 		try:
# 			if self.window.active_view():
# 				self.window.active_view().run_command("logcat", {"text": text} )
# 		except ValueError:
# 			pass

class LogcatCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		t = threading.Thread(target=self.log_cat_command, args=(folderPath,))
		t.setDaemon(True)
		t.start()

	# def run(self, edit, text):
	# 	filePathMember = self.view.file_name().split(delimiter)
	# 	folderTools = FolderTools()
	# 	folderPath = folderTools.getFolderList(filePathMember)
	# 	if os.path.exists(folderPath):
	# 		pass
	# 	else:
	# 		os.mkdir(folderPath)
	# 	t = threading.Thread(target=self.log_cat_command, args=(folderPath, text))
	# 	t.setDaemon(True)
	# 	t.start()
	# 	# t.join()
		
	def log_cat_command(self, srcFolder):
		if os.path.exists(srcFolder + delimiter +"logcat.txt"):	
			os.remove(srcFolder + delimiter +"logcat.txt")	
		print adbpath + ' logcat -v time >> ' + srcFolder + delimiter + 'logcat.txt'
		p = os.system(adbpath + ' logcat -v time >> ' + srcFolder + delimiter + 'logcat.txt')

class RecordCommand(sublime_plugin.TextCommand):

	def run(self, edit):
		# os.popen(adbpath + ' shell rm /sdcard/TestTool/record_stop.txt')
		temp_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/TestTool/.lua', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		# print adbpath + ' shell cat /sdcard/TestTool/.lua'
		data_Log = temp_Log.communicate()
		if data_Log[0].find('No such file') != -1:
			print '--->/sdcard/TestTool/.lua not found!!<---'
			return
		s = 0
		e = 0
		for x in xrange(0, len(data_Log[0].split('\n'))):
			if data_Log[0].split('\n')[x].find('restartApp(PackageName)') != -1:
				s = x
			if data_Log[0].split('\n')[x].find('Android:notifyVoice("/mnt/sdcard/TestTool/Alarm_Kapalai.mp3")') != -1:
				e = x
		for x in xrange(0, len(data_Log[0].split('\n'))):
			if s<x<e :
				self.insert_contents(edit, data_Log[0].split('\r\r\n')[x].decode("utf-8"))
				# print data_Log[0].split('\r\r\n')[x]
		# t = threading.Thread(target=self.isChanged, args=(edit,))
		# t.setDaemon(True)
		# t.start()

	def isChanged(self, edit):
		lastTimeLogRow = 0 
		begin_time = time.time()
		end_time = begin_time + 3600
		# j = 0 
		while time.time() < end_time:
			# j = j + 1
			# print 'j--->', j
			temp_Log = subprocess.Popen(adbpath + ' shell su -c "cat /data/local/tmp/kat/out.txt"', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			data_Log = temp_Log.communicate()
			temp_switch = subprocess.Popen(adbpath + ' shell cat /sdcard/TestTool/record_stop.txt', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			is_close_switch = temp_switch.communicate()

			if is_close_switch[0].find('No such file') == -1:
				print "---------Record thread is over---------"
				break
			if not data_Log[1]:
				count =  data_Log[0].count('\r\r\n')
				# print data_Log
				if lastTimeLogRow != count :
					if lastTimeLogRow > count :
						print '-----------Code is cleaned!!-----------'
						print "---------Record thread is over---------"
						break
					else:
						for i in range(lastTimeLogRow, count):
							if data_Log[0].find('No such file') == -1:
								print '',data_Log[0].split('\r\r\n')[i]

								# self.insert_contents(edit, data_Log[0].split('\r\r\n')[i])
						# sublime.set_timeout(self.view.insert(edit, 3156, '11111111111111'), 2000)
						lastTimeLogRow = count
				time.sleep(0.5)
			else:
				print "--------------------------------------"
				print data_Log[1]
				break

	def insert_contents(self, edit, contents):
		for region in self.view.sel():
			if region.empty():
				line = self.view.line(region)
				# print line
				if contents == '':
					pass
				else:
					contents = contents + '\n'
				self.view.insert(edit, line.begin(), contents)
			else:
				print "--------------error--------------"
                # self.view.insert(edit, region.begin(), "--------------error--------------")

class StopRecordCommand(sublime_plugin.TextCommand):
    
	def run(self, edit):
		for i in range(0, 3):
			print ''
		print "================================stop record !!================================"
		for i in range(0, 3):
			print ''
		# run adb Command
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			f = open(folderPath + delimiter + 'record_stop.txt', 'w')
			f.close()
		else:
			os.mkdir(folderPath)
			f = open(folderPath + delimiter + 'record_stop.txt', 'w')
			f.close()
		self.pushFileToDevice(folderPath + delimiter + 'record_stop.txt')

	def pushFileToDevice(self, path):
		# check adb is connection, if 'device not found', pop up error!
		p = subprocess.Popen(adbpath + " push d:/a1l1.txt /sdcard/kat/", shell = True, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		if erroutput[1].split(':')[0] == 'error':
			sublime.error_message(erroutput[1])
		else:
			result = os.popen(adbpath + ' push "' + path + '" /sdcard/TestTool/')

class GetPkgNameCommand(sublime_plugin.TextCommand):
    
	def run(self, edit):
		for i in range(0, 3):
			print ''
		print "================================get package name !!================================"
		for i in range(0, 3):
			print ''
		temp_Log = subprocess.Popen(adbpath + ' shell cat /sdcard/TestTool/.lua', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		data_Log = temp_Log.communicate()
		self.insert_contents(edit, data_Log[0].split('"')[1].decode("utf-8"))
		sublime.set_clipboard(data_Log[0].split('"')[1].decode("utf-8"))

	def insert_contents(self, edit, contents):
		for region in self.view.sel():
			if region.empty():
				self.view.insert(edit, region.b, contents)
			else:
				print "--------------error--------------"
                # self.view.insert(edit, region.begin(), "--------------error--------------")

class FolderTools():

	def getFolderList(self, filePathMember):
		size = len(filePathMember)
		folderPath = ""
		for i in range(0, size - 2):
			folderPath = folderPath + filePathMember[i] + delimiter
		folderPath = folderPath + filePathMember[len(filePathMember)-2]
		if folderPath.find(tmpFolder) != -1:
			pass
		else:
			folderPath = folderPath + delimiter + tmpFolder
		# print "Project Path===========>",folderPath
		return folderPath

class GetKatRunFileCommand(sublime_plugin.TextCommand):
	# main
	def run(self, edit):
		filePathMember = self.view.file_name().split(delimiter)
		folderTools = FolderTools()
		folderPath = folderTools.getFolderList(filePathMember)
		if os.path.exists(folderPath):
			print folderPath
			tt = threading.Thread(target=self.pullFile, args=(folderPath,))
			tt.setDaemon(True)
			tt.start()
		else:
			os.mkdir(folderPath)
			tt = threading.Thread(target=self.pullFile, args=(folderPath,))
			tt.setDaemon(True)
			tt.start()
		
	def pullFile(self, srcFolder):
		# check adb is connection, if 'device not found', pop up error!
		try:
			print adbpath + " pull /sdcard/kat/Result/ " + srcFolder
			os.system(adbpath + " pull /sdcard/kat/Result " + srcFolder)
		except Exception:
			sublime.error_message(u"当前命令为:\n" + adbpath + " pull /sdcard/kat/Result " + srcFolder + u"\n不能包含中文!!")


class OpenPicCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		filePath = self.view.file_name().split(delimiter)
		suffix = filePath[len(filePath) - 1]
		if suffix.endswith('.jpg') or suffix.endswith('.png') or suffix.endswith('.gif'):
			folderPath = ""
			for i in range(0, len(filePath) - 1):
				folderPath = folderPath + filePath[i] + delimiter
			picPath = folderPath + suffix
			subprocess.Popen(picPath, shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		else:
			print '---not pic---'

class OpenShellCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		shellFilePath = sublime.packages_path() + delimiter + u"kat" + delimiter + u"utest_shell"
		p = subprocess.Popen(adbpath + " push " + '\"' + shellFilePath + '\"' + " /data/local/tmp/", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		erroutput = p.communicate()
		if erroutput[1].split(':')[0] == 'error':
			sublime.error_message(erroutput[1])
		else:
			sdk = subprocess.Popen(adbpath + ' shell \"getprop ro.build.version.sdk\"', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
			sdk = sdk.communicate()
			p = re.compile(r'\D+')
			print 'SDK:' + p.split(sdk[0])[0]
			if int(p.split(sdk[0])[0]) > 20:
				t = threading.Thread(target=self.startTools)
				t.setDaemon(True)
				t.start()
			
	def startTools(self):
		subprocess.Popen(adbpath + ' shell \"chmod 777 /data/local/tmp/utest_shell\"', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		time.sleep(3)
		subprocess.Popen(adbpath + ' shell \"/data/local/tmp/utest_shell -s\"', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		command = subprocess.Popen(adbpath + ' shell \"/data/local/tmp/utest_shell -t\"', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		print re.split('\W+', command.communicate()[0])[0]

class NewFolderCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		filePath = self.view.file_name().split(delimiter)
		suffix = filePath[len(filePath) - 1]
		
		folderPath = ""
		for i in range(0, len(filePath) - 1):
			folderPath = folderPath + filePath[i] + delimiter
		subprocess.Popen('md ' + folderPath + delimiter + 'newFolder', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)

class UpdateKatPluginCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		self.urls = ["https://raw.githubusercontent.com/harryhappy/demo/master/leo/Context.sublime-menu",
                     "https://raw.githubusercontent.com/harryhappy/demo/master/leo/Default.sublime-keymap",
                     "https://raw.githubusercontent.com/harryhappy/demo/master/leo/RunCommand.py",
                     "https://raw.githubusercontent.com/harryhappy/demo/master/leo/Side Bar.sublime-menu",
                     "https://raw.githubusercontent.com/harryhappy/demo/master/leo/utest_shell"
                     ]
		for url in self.urls:
			filename = url.split("/")[-1]
			urllib.urlretrieve(url,os.path.join(r"C:\XTestScriptTools\Data\Packages\kat",filename))

class InstallCommand(sublime_plugin.TextCommand):
	def run(self, edit):
		t = threading.Thread(target=self.install)
		t.setDaemon(True)
		t.start()
			
	def install(self):
		p = subprocess.Popen("D:\\xadb\\xadb.exe" + " devices -l", shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		devicesListInfo = p.communicate()
		devicesList = devicesListInfo[0].split('\r\n')
		j = 1
		# isLock = False
		devices = ''
		for dl in devicesList:
			if 'attached' not in dl and 'device' in dl:
				dev = dl.split('	device')[0]
				print str(j) + ' ' + 'D:\\xadb\\xadb.exe' + u' -s ' + dev + u' install -r C:\\Users\\SJKP\\Desktop\\xtest.apk'
				# print 'D:\\xadb\\xadb.exe' + u' -s ' + dev + u' shell cat /system/build.prop'
				temp = subprocess.Popen('D:\\xadb\\xadb.exe' + u' -s ' + dev + u' shell cat /system/build.prop', shell = True, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
				infooutput_temp = temp.communicate()
				if not infooutput_temp[1]:
					tempinfo = infooutput_temp[0].split("\r\r\n")
					for i in range(0,len(tempinfo)):
						#            print tempinfo[i]
						if "ro.product.brand" in tempinfo[i]:
							brand = tempinfo[i].split("=")[1]
							brand = brand.split("\r")[0]
						elif "ro.product.model" in tempinfo[i]:
							devices = tempinfo[i].split("=")[1]
							devices = devices.split("\r")[0]
							if "SM" in devices:
								devices = devices.split("-")[1]
							break	
						elif "ZTE" in devices:
							devices = devices.split(" ")[1]
						elif "MI" in devices:
							devices = devices.split(" ")[1]
						elif "ro.build.version.ota" in tempinfo[i]:
							devices = tempinfo[i].split("=")[1].split("ROM")[0]    
						elif "ro.build.version.incremental" in tempinfo[i]:
							mi_version = tempinfo[i].split("=")[1]
							if mi_version == "V6.1.2.0.KXDCNBJ":
								devices = "4C" 
							elif mi_version == "V6.4.1.0.KXGCNCB":
								devices = "4LTE-CT" 
							elif mi_version == "V6.3.11.0.KXECNBL":
								devices = "NOTE-LTE"
							elif mi_version == "V6.2.1.0.KXDCNBK":
								devices = "4LTE-CMCC"
					j+=1
					print devices
				else:
					print infooutput_temp[1]
				os.system('D:\\xadb\\xadb.exe' + u" -s " + dev + u" install -r C:\\Users\\SJKP\\Desktop\\xtest.apk")
		print "install end!"
