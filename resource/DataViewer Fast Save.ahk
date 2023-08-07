#Requires AutoHotkey v2.0
; 程序名
A_ScriptName := "DataViewer 一次保存 4 张图"
; DataViewer 的窗体类名
DataViewerClassName := "ahk_class " . "SkyScan DataViewer"
; 选择程序保存路径
ImageDirectory := FileSelect("D", A_InitialWorkingDir)
if (!DirExist(ImageDirectory)) {
	MsgBox "您选择的文件夹不存在"
	ExitApp
}

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

	SavePic("Coronal(X-Z) Image As a Single Image", "X-Z")
	SavePic("Sagittal(Z-Y) Image As a Single Image", "Z-Y")
	SavePic("Transaxial(X-Y) Image As a Single Image", "X-Y")
	SavePic("Screen Display", "Screen")

	SavePic(menuName, postfix)
	{
		MenuSelect Hwnd ,, "Actions" , "Save", menuName ; 点击菜单
		SWHwnd := WinWait(subWinClass) ; 等待同进程ID下的 #32770 窗口
		SWTitle := WinGetTitle(SWHwnd) ; 获得弹出窗口标题
		
		if (InStr(SWTitle,"Attention")) { ;如果弹出的是警告窗口
			SetControlDelay 0  ; 可以提高可靠性, 减少副作用.
			ControlClick(InStr(SWTitle,"!") ? "Button2" : "Button1", SWHwnd) ; 有感叹号的是 屏幕显示 点下第二个按钮（否），否则是旋转警告，点下第一个按钮（是）
			WinWaitClose(SWHwnd) ; 等待警告窗口关闭
			SWHwnd := WinWait("Save " . subWinClass) ; 等待同进程ID下的 Save 开头的 #32770 窗口
		}

		fileName := Format("{1}\{2}_{3}", ImageDirectory, FilenamePre, postfix) ; 生成时间格式
		SetControlDelay 0  ; 可以提高可靠性, 减少副作用.
		ControlSetText(fileName, "Edit1", SWHwnd) ; 将路径填入文件名内
		ControlClick("Button2", SWHwnd) ; 点击保存按钮
		WinWaitClose(SWHwnd) ; 等待保存窗口关闭
	}
}