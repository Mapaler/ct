[General]
SyntaxVersion=2
BeginHotkey=121
BeginHotkeyMod=0
PauseHotkey=0
PauseHotkeyMod=0
StopHotkey=123
StopHotkeyMod=0
RunOnce=1
EnableWindow=
MacroID=03f4fbfe-bfed-4c0c-9bfc-d7eb06f60d4e
Description=DataViewer同时保存4张图
Enable=1
AutoRun=0
[Repeat]
Type=0
Number=1

[Script]
Public Declare Function GetMenu Lib "user32.dll" (ByVal hwnd As Long) As Long
Public Declare Function GetSubMenu Lib "user32.dll" (ByVal hMenu As Long, ByVal nPos As Long) As Long
Public Declare Function GetMenuItemID Lib "user32.dll" (ByVal hMenu As Long, ByVal nPos As Long) As Long
Public Declare Function SendMessage Lib "user32" Alias "SendMessageW" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, lParam As Any) As Long
Public Declare Function PostMessage Lib "user32" Alias "PostMessageW" (ByVal hwnd As Long, ByVal wMsg As Long, ByVal wParam As Long, ByVal lParam As Long) As Long
'Public Declare Function GetWindow Lib "user32" (ByVal hwnd As Long, ByVal wCmd As Long) As Long
'Public Declare Function FindWindowEx Lib "user32" Alias "FindWindowExA" (ByVal hWnd1 As Long, ByVal hWnd2 As Long, ByVal lpsz1 As String, ByVal lpsz2 As String) As Long

Const DelayTime = 300 '延时毫秒，根据电脑反应速度调整

Const BM_CLICK = &HF5
Const WM_LBUTTONDOWN = &H201
Const WM_LBUTTONUP = &H202
Const WM_SETTEXT = &HC
Const WM_CLOSE = &H10
Const WM_COMMAND = &H111
Const WM_SETFOCUS = &H7

Const GW_CHILD = 5
Const GW_HWNDFIRST = 0
Const GW_HWNDNEXT = 2

DeskTopPath = Plugin.SysEx.GetDir(4)'获得桌面路径
FolderPath = DeskTopPath & "\DataViewer_2D_Picture"
Plugin.File.CreateFolder FolderPath
Main(FolderPath) 

Function Main(Path)
	Dim WHwnd,Title
	WHwnd = Plugin.Window.Foreground() '获取当前窗口句柄
	Title = Plugin.Window.GetText(WHwnd) 
	
	If InStr(Title, "DataViewer") <> 1 Then 
		'MsgBox "当前窗口不是DataViewer", vbInformation, "程序错误"
		TracePrint "当前窗口不是DataViewer"
		'ExitScript
		WHwnd = Plugin.Window.Find("SkyScan DataViewer",0) '获取后台DataViewer窗口句柄
		Title = Plugin.Window.GetText(WHwnd) 
	End If
	If WHwnd = 0 Then 
		MessageBox "未找到DataViewer窗口"
		ExitScript
	End If
	Dim MHwnd,SMHwnd,SMHwnd2
	MHwnd = GetMenu(WHwnd)'获得总菜单句柄
	SMHwnd = GetSubMenu(MHwnd, 0)'获得一级子菜单句柄
	SMHwnd2 = GetSubMenu(SMHwnd, 17)'获取保存子菜单句柄
	
	'生成图片保存路径（前缀）
	Dim t,SavePrefix
	t = Now()
	SavePrefix = Path & "\" & _
		Mid(Title, Len("DataViewer - ") + 1) & "_" & _
		add0(Year(t),4) & "-" & add0(Month(t),2) & "-" & add0(Day(t),2) & "_" & _
		add0(Hour (t),2) & "-" & add0(Minute(t),2) & "-" & add0(Second(t),2) & "_"
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 0)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 1)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 2)
	Call savePic(WHwnd, SMHwnd2, SavePrefix, 8)
End Function
'提供窗口、菜单项句柄和第几个保存图像按钮
Function savePic(hWindow, hSubMenu, pSavePrefix, pIndex)
	MIHwnd = GetMenuItemID(hSubMenu, 2 + pIndex) '获取保存图片按钮句柄
	PostMessage hWindow, WM_COMMAND, MIHwnd, 0'发送启动菜单
	Delay DelayTime
	
	Dim SWHwnd
	Do
		SWHwnd = Plugin.Window.FindEx(0, SWHwnd, "#32770", 0)'保存窗口父窗口为0，全面搜索"#32770"句柄
		If Plugin.Window.GetParentWindow(SWHwnd) = hWindow Then '如果父句柄是DataViewer则是保存窗口/或旋转警告窗口
			TracePrint "获得保存/旋转警告窗体句柄为 " & Hex(SWHwnd) & "  " & Plugin.Window.GetText(SWHwnd)
			Exit Do
		End If
	Loop Until SWHwnd = 0
	If InStr(Plugin.Window.GetText(SWHwnd),"Attention") > 0 Then '是旋转警告窗口或三视图警告
		BHwnd = Plugin.Window.FindEx(SWHwnd, 0, "Button", 0)
		If InStr(Plugin.Window.GetText(SWHwnd), "!") > 0 Then '是三视图警告
			BHwnd = Plugin.Window.FindEx(SWHwnd, BHwnd, "Button", 0)
		End If
		TracePrint "发现是/否按钮 " & Hex(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0
		Delay DelayTime
		SWHwnd = 0
		Do
			SWHwnd = Plugin.Window.FindEx(0, SWHwnd, "#32770", 0)'保存窗口父窗口为0，全面搜索"#32770"句柄
			If Plugin.Window.GetParentWindow(SWHwnd) = hWindow Then '如果父句柄是DataViewer则是保存窗口
				TracePrint "获得保存窗体句柄为 " & Hex(SWHwnd) & "  " & Plugin.Window.GetText(SWHwnd)
				Exit Do
			End If
		Loop Until SWHwnd = 0
	End If
	
	If SWHwnd = 0 Then
		TracePrint "未找到保存窗口"
		Exit Function
	End If
	
	PHwnd = Plugin.Window.FindEx(SWHwnd, 0, "DUIViewWndClassName", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "DirectUIHWND", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "FloatNotifySink", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "ComboBox", 0)
	PHwnd = Plugin.Window.FindEx(PHwnd, 0, "Edit", 0)
	TracePrint "地址框句柄为 " & Hex(PHwnd) & "  " & Plugin.Window.GetTextEx(PHwnd,1)
	Dim SavePath, ModeName
	Select Case pIndex
		Case 0
			ModeName = "X-Z"
		Case 1
			ModeName = "Z-Y"
		Case 2
			ModeName = "X-Y"
		Case 8
			ModeName = "Screen"
	End Select
	SavePath = pSavePrefix & ModeName & ".bmp"
	Plugin.Window.SendString PHwnd,"  " & SavePath '替换文字
	'SendMessage PHwnd, WM_SETTEXT, 0, SavePath
	TracePrint "保存到 " & SavePath
	
	Delay DelayTime
	BHwnd = 0
	BHwnd = Plugin.Window.FindEx(SWHwnd, 0, "Button", 0) '保存按钮
	TracePrint "保存按钮句柄为 " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
	PostMessage BHwnd, BM_CLICK, 0, 0'按下保存
	
	Delay DelayTime
	'保存覆盖询问窗口
	SAWHwnd = 0	
	Do
		SAWHwnd = Plugin.Window.FindEx(0, SAWHwnd, "#32770", 0)'保存窗口父窗口为0，全面搜索"#32770"句柄
		If Plugin.Window.GetParentWindow(SAWHwnd) = SWHwnd Then '如果父句柄是DataViewer则是保存窗口/或旋转警告窗口
			TracePrint "获得确认另存为窗口句柄为 " & Hex(SAWHwnd) & "  " & Plugin.Window.GetText(SAWHwnd)
			Exit Do
		End If
	Loop Until SAWHwnd = 0
	If SAWHwnd <> 0 Then 
		BFHwnd = 0
		BFHwnd = Plugin.Window.FindEx(SAWHwnd, 0, "DirectUIHWND", 0)
		BHwnd = 0
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BFHwnd, BHwnd, "CtrlNotifySink", 0)
		BHwnd = Plugin.Window.FindEx(BHwnd, 0, "Button", 0)
		TracePrint "确定按钮句柄为 " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0'按下确定
		Delay DelayTime
	End If
	
	'保存颜色询问窗口
	SCAWHwnd = 0
	Do
		SCAWHwnd = Plugin.Window.FindEx(0, SCAWHwnd, "#32770", 0)'保存窗口父窗口为0，全面搜索"#32770"句柄
		If Plugin.Window.GetParentWindow(SCAWHwnd) = hWindow Then '如果父句柄是DataViewer则是保存窗口/或旋转警告窗口
			TracePrint "获得颜色询问窗口句柄为 " & Hex(SCAWHwnd) & "  " & Plugin.Window.GetText(SCAWHwnd)
			Exit Do
		End If
	Loop Until SCAWHwnd = 0
	If SCAWHwnd <> 0 Then 
		BHwnd = 0
		BHwnd = Plugin.Window.FindEx(SCAWHwnd, 0, "Button", 0) '确定按钮
		TracePrint "确定按钮句柄为 " & Hex(BHwnd) & "  " & Plugin.Window.GetText(BHwnd)
		SendMessage BHwnd, BM_CLICK, 0, 0'按下确定
		Delay DelayTime
	End If
End Function

'补0
Function add0(num, length)
	add0 = String(length - Len(num),"0") & num
End Function

'点击窗口上的按钮
Event frmMain.btnRun.Click
	Main(frmMain.iptDir.Text)
End Event
