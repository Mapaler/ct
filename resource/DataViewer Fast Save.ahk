﻿#Requires AutoHotkey v2.0
; 程序名
A_ScriptName := "DataViewer 一次保存 4 张图 v2.0.1"
;DataViewerSystemfolder := RegRead("HKEY_CURRENT_USER\SOFTWARE\SkyScan\DataViewer\Preferences", "System folder", "C:\ProgramFree\SkyScan\DataViewer")
; IconPosition := DataViewerSystemfolder . "\DataViewer.exe"
;if (FileExist(IconPosition)) {
;	TraySetIcon(IconPosition,0)
;}
TraySetIcon("imageres.dll",289)
A_IconTip := A_ScriptName
helpText := "快捷键：F10`n功能：DataViewer 打开 3D viewing 并激活为当前窗口时，按下快捷键，可以一次保存 3 张方位图片和屏幕显示图片。`n提示：`n1.请选择纯英文路径（要有非 ASCii 字符）`n2.如需关闭程序或重新选择保存路径，请使用任务栏托盘按钮的右键菜单。`n3.如果调整了色彩映射范围，会因为有一个额外的确认框导致保存失败，可以在托盘键菜单里打开“监测并关闭‘色彩映射改变确认’窗口”功能"

ShowHelp("","","") 

A_TrayMenu.Delete() ;删除所有右键菜单
; 选择程序保存路径
ImageDirectory := ""

OpenSaveDirectory(ItemName, ItemPos, MyMenu)
{
	Run("explorer.exe `"" . ImageDirectory . "`"")
}
A_TrayMenu.Add("打开当前的图片保存文件夹", OpenSaveDirectory)
A_TrayMenu.SetIcon("打开当前的图片保存文件夹", "imageres.dll", 109)

ChooseSaveDirectory(ItemName, ItemPos, MyMenu)
{
	newDirectory := FileSelect("D", ImageDirectory || A_Desktop, "选择保存图片的文件夹")
	if (DirExist(newDirectory)){
		global ImageDirectory := newDirectory
	}
}
A_TrayMenu.Add("重新选择图片保存文件夹", ChooseSaveDirectory)
A_TrayMenu.SetIcon("重新选择图片保存文件夹", "imageres.dll", 229)

DataDynamicRangeChangeMenuName := "监测并关闭“色彩映射改变确认”窗口"
WillShowDataDynamicRangeChange := false
ChangeShowDataDynamicRangeChange(ItemName, ItemPos, MyMenu)
{
	global WillShowDataDynamicRangeChange := !WillShowDataDynamicRangeChange
	WillShowDataDynamicRangeChange ? A_TrayMenu.Check(DataDynamicRangeChangeMenuName) : A_TrayMenu.Uncheck(DataDynamicRangeChangeMenuName)
}

A_TrayMenu.Add()
A_TrayMenu.Add(DataDynamicRangeChangeMenuName, ChangeShowDataDynamicRangeChange)
A_TrayMenu.Add()

ShowHelp(ItemName, ItemPos, MyMenu)
{
	MsgBox(helpText,"使用说明",0x20)
}
A_TrayMenu.Add("再次显示启动时的帮助", ShowHelp)
A_TrayMenu.SetIcon("再次显示启动时的帮助", "imageres.dll", 95)

CloseScript(ItemName, ItemPos, MyMenu)
{
	ExitApp
}
A_TrayMenu.Add("退出脚本", CloseScript)
A_TrayMenu.SetIcon("退出脚本", "imageres.dll", 236)

;第一次使用脚本需要先选择文件夹
ChooseSaveDirectory("","","") 
if (!DirExist(ImageDirectory)) {
	MsgBox("您选择的文件夹不存在，本程序退出。`n若需再次使用请重新运行。",,0x10)
	ExitApp
}

; DataViewer 的窗体类名
DataViewerClassName := "ahk_class " . "SkyScan DataViewer"
; 指定必须 DataViewer 窗口在前台时才起作用
#HotIf WinActive(DataViewerClassName)
F10:: ; F10 快捷键启动
{
	SoundBeep ; 响一声
	ActiveHwnd := WinActive(DataViewerClassName)
	Start(ActiveHwnd, ImageDirectory)
}

; 正式开始的主程序
Start(Hwnd, Dir)
{
	WindowTitle := WinGetTitle(Hwnd) ; 获取窗口标题
	PID := WinGetPID(Hwnd)
	subWinClass := "ahk_class #32770 ahk_pid " . PID
	DatasetPre := SubStr(WindowTitle, StrLen("DataViewer - ") + 1) ; 获得数据集名称
	TimePre := Format("{1}-{2}-{3}_{4}-{5}-{6}", A_YYYY, A_MM, A_DD, A_Hour, A_Min, A_Sec) ; 生成时间格式
	FilenamePre := DatasetPre "_" TimePre ; 组合成保存文件名的前缀

	SavePic("Coronal(X-Z) Image As a Single Image", "X-Z(Coronal)")
	SavePic("Sagittal(Z-Y) Image As a Single Image", "Z-Y(Sagittal)")
	SavePic("Transaxial(X-Y) Image As a Single Image", "X-Y(Transaxial)")
	SavePic("Screen Display", "ScreenDisplay")

	SavePic(menuName, postfix)
	{
		MenuSelect Hwnd ,, "Actions" , "Save", menuName ; 点击菜单
		SWHwnd := WinWait(subWinClass) ; 等待同进程ID下的 #32770 窗口
		SWTitle := WinGetTitle(SWHwnd) ; 获得弹出窗口标题
		OutputDebug SWTitle . "`n"

		if (InStr(SWTitle,"Attention")) { ;如果弹出的是警告窗口
			SetControlDelay 0  ; 可以提高可靠性, 减少副作用.
			ControlClick(InStr(SWTitle,"!") ? "Button2" : "Button1", SWHwnd) ; 有感叹号的是 屏幕显示图 点下第二个按钮（否），否则是旋转警告，点下第一个按钮（是）
			WinWaitClose(SWHwnd) ; 等待警告窗口关闭
			SWHwnd := WinWait("Save " . subWinClass) ; 等待同进程ID下的 Save 开头的 #32770 窗口
		}

		fileName := Format("{1}\{2}_{3}", ImageDirectory, FilenamePre, postfix) ; 生成文件路径
		SetControlDelay 0  ; 可以提高可靠性, 减少副作用.
		ControlSetText(fileName, "Edit1", SWHwnd) ; 将路径填入文件名内
		FoundItem := ControlChooseString(postfix=="ScreenDisplay"?"(24-bit)BMP":"(8-bit)BMP", "ComboBox2" , SWHwnd) ;查找bmp选项，Screen Display是24bit开头
		ControlChooseIndex(FoundItem, "ComboBox2" , SWHwnd) ;选中bmp选项
		ControlClick("Button2", SWHwnd) ; 点击保存按钮
		WinWaitClose(SWHwnd) ; 等待保存窗口关闭

		if (WillShowDataDynamicRangeChange) ;监测并关闭“色彩映射改变确认”窗口
		{
			CDHwnd := WinWait("DataViewer " . subWinClass, "Data dynamic range", 2.0) ; 等待色彩映射压缩确认窗口
			if (CDHwnd) {
				ControlClick("Button1", CDHwnd) ; 点下确认按钮
				WinWaitClose(CDHwnd) ; 等待保存窗口关闭
				WinWaitClose(SWHwnd) ; 等待保存窗口关闭
			}
		}
	}
}