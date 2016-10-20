require("/sdcard/kat/Core")
require("/sdcard/kat/QQID")
----------------------------------------------------------------------
function executeCaseN(CaseN) --CaseN为当前lua文件的名称，并作为当前用例名称
	--这里插入录制代码



end

---------------------------Customize your own init operation..。-----------------
function caseFactory()
	updateCaseFolder(Case_Name)
	return restartApp(PackageName)
end
------------------------------------------------------------------------------

doRun()
